import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/firebase_phone_auth_repository.dart';
import '../domain/cameroon_phone_number.dart';
import '../domain/repositories/phone_auth_repository.dart';

enum PhoneAuthStage { phoneEntry, codeEntry, success }

/// Shared across login/link screens. Leaving a screen must not bypass the
/// spacing between SMS requests. This delay is not Firebase's unblock time.
final phoneRequestGateProvider = Provider((ref) => PhoneRequestGate());

class PhoneRequestGate {
  final _deadlines = <String, DateTime>{};

  int remaining(String phone) {
    final deadline = _deadlines[phone];
    if (deadline == null) return 0;
    final milliseconds = deadline.difference(DateTime.now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  void reserve(String phone, int seconds) {
    _deadlines.removeWhere((_, deadline) => deadline.isBefore(DateTime.now()));
    _deadlines[phone] = DateTime.now().add(Duration(seconds: seconds));
  }
}

class PhoneAuthState {
  const PhoneAuthState({
    this.stage = PhoneAuthStage.phoneEntry,
    this.phoneNumber = '',
    this.verificationId,
    this.resendToken,
    this.cooldownSeconds = 0,
    this.isLoading = false,
    this.errorCode,
    this.autoRetrievalTimedOut = false,
    this.session,
  });

  final PhoneAuthStage stage;
  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final int cooldownSeconds;
  final bool isLoading;
  final String? errorCode;
  final bool autoRetrievalTimedOut;
  final PhoneAuthSession? session;

  PhoneAuthState copyWith({
    PhoneAuthStage? stage,
    String? phoneNumber,
    String? verificationId,
    int? resendToken,
    int? cooldownSeconds,
    bool? isLoading,
    String? errorCode,
    bool clearError = false,
    bool? autoRetrievalTimedOut,
    PhoneAuthSession? session,
  }) {
    return PhoneAuthState(
      stage: stage ?? this.stage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      isLoading: isLoading ?? this.isLoading,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      autoRetrievalTimedOut:
          autoRetrievalTimedOut ?? this.autoRetrievalTimedOut,
      session: session ?? this.session,
    );
  }
}

final phoneAuthControllerProvider = StateNotifierProvider.autoDispose
    .family<PhoneAuthController, PhoneAuthState, bool>((ref, linkCurrentUser) {
      final controller = PhoneAuthController(
        repository: ref.read(phoneAuthRepositoryProvider),
        linkCurrentUser: linkCurrentUser,
        requestGate: ref.read(phoneRequestGateProvider),
      );
      ref.onDispose(controller.close);
      return controller;
    });

class PhoneAuthController extends StateNotifier<PhoneAuthState> {
  PhoneAuthController({
    required PhoneAuthRepository repository,
    required this.linkCurrentUser,
    PhoneRequestGate? requestGate,
  }) : _repository = repository,
       _requestGate = requestGate ?? PhoneRequestGate(),
       super(const PhoneAuthState());

  static const resendCooldown = 60;

  final PhoneAuthRepository _repository;
  final PhoneRequestGate _requestGate;
  final bool linkCurrentUser;
  Timer? _cooldownTimer;
  bool _closed = false;
  int _requestGeneration = 0;

  Future<void> sendCode(String rawPhone, {bool resend = false}) async {
    // Le clavier (`onFieldSubmitted`) et le bouton déclenchent le même geste.
    // Sans garde, un seul envoi voulu par l'élève pouvait produire deux
    // `verifyPhoneNumber`, donc consommer deux fois le quota Firebase et
    // provoquer le throttling « trop de tentatives ».
    if (_closed || state.isLoading || state.stage == PhoneAuthStage.success) {
      return;
    }
    String phone;
    try {
      phone = CameroonPhoneNumber.normalize(rawPhone);
    } on PhoneNumberFormatException {
      state = state.copyWith(errorCode: 'invalid-phone-number');
      return;
    }

    final remaining = _requestGate.remaining(phone);
    if (remaining > 0) {
      state = state.copyWith(phoneNumber: phone, cooldownSeconds: remaining);
      _startCooldown();
      return;
    }
    final generation = ++_requestGeneration;
    bool current() =>
        !_closed &&
        generation == _requestGeneration &&
        state.stage != PhoneAuthStage.success;
    final token = resend && phone == state.phoneNumber
        ? state.resendToken
        : null;
    _requestGate.reserve(phone, resendCooldown);
    state = state.copyWith(
      phoneNumber: phone,
      isLoading: true,
      clearError: true,
      autoRetrievalTimedOut: false,
    );
    try {
      await _repository.startVerification(
        phoneNumber: phone,
        linkCurrentUser: linkCurrentUser,
        forceResendingToken: token,
        onVerified: (session) {
          if (current()) _handleVerified(session);
        },
        onFailed: (failure) {
          if (current()) _handleFailure(failure);
        },
        onCodeSent: (dispatch) {
          if (current()) _handleCodeSent(dispatch);
        },
        onAutoRetrievalTimeout: (id) {
          if (current()) _handleTimeout(id);
        },
      );
    } on PhoneAuthFailure catch (error) {
      if (current()) _handleFailure(error);
    } catch (_) {
      if (current()) _handleFailure(const PhoneAuthFailure('unknown-error'));
    }
  }

  Future<void> confirmCode(String code) async {
    // La saisie du sixième chiffre valide déjà automatiquement : le
    // « terminé » du clavier ne doit pas soumettre le code une seconde fois.
    if (_closed || state.isLoading || state.stage != PhoneAuthStage.codeEntry) {
      return;
    }
    final verificationId = state.verificationId;
    final normalizedCode = code.replaceAll(RegExp(r'\D'), '');
    if (verificationId == null || normalizedCode.length != 6) {
      state = state.copyWith(errorCode: 'invalid-verification-code');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _handleVerified(
        await _repository.confirmCode(
          verificationId: verificationId,
          smsCode: normalizedCode,
          linkCurrentUser: linkCurrentUser,
        ),
      );
    } on PhoneAuthFailure catch (error) {
      _handleFailure(error);
    } catch (_) {
      _handleFailure(const PhoneAuthFailure('unknown-error'));
    }
  }

  Future<void> resendCode() async {
    if (state.cooldownSeconds > 0 || state.isLoading) return;
    await sendCode(state.phoneNumber, resend: true);
  }

  void changePhoneNumber() {
    if (_closed || state.isLoading) return;
    _requestGeneration++;
    _cancelPendingVerification();
    _cooldownTimer?.cancel();
    state = PhoneAuthState(
      phoneNumber: state.phoneNumber,
      cooldownSeconds: _requestGate.remaining(state.phoneNumber),
    );
    _startCooldown();
  }

  void showProfileMissing() {
    state = state.copyWith(
      stage: PhoneAuthStage.codeEntry,
      isLoading: false,
      errorCode: 'user-profile-not-found',
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _handleCodeSent(PhoneCodeDispatch dispatch) {
    if (_closed) return;
    _requestGate.reserve(state.phoneNumber, resendCooldown);
    state = state.copyWith(
      stage: PhoneAuthStage.codeEntry,
      verificationId: dispatch.verificationId,
      resendToken: dispatch.resendToken,
      cooldownSeconds: resendCooldown,
      isLoading: false,
      clearError: true,
    );
    _startCooldown();
  }

  void _handleVerified(PhoneAuthSession session) {
    if (_closed) return;
    _cooldownTimer?.cancel();
    state = state.copyWith(
      stage: PhoneAuthStage.success,
      isLoading: false,
      clearError: true,
      session: session,
    );
  }

  void _handleFailure(PhoneAuthFailure failure) {
    if (_closed || state.stage == PhoneAuthStage.success) return;
    state = state.copyWith(
      isLoading: false,
      errorCode: failure.code,
      cooldownSeconds: _requestGate.remaining(state.phoneNumber),
    );
    _startCooldown();
  }

  void _handleTimeout(String verificationId) {
    if (_closed || state.stage == PhoneAuthStage.success) return;
    state = state.copyWith(
      verificationId: verificationId,
      isLoading: state.stage == PhoneAuthStage.phoneEntry
          ? false
          : state.isLoading,
      autoRetrievalTimedOut: true,
    );
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_closed) {
        timer.cancel();
        return;
      }
      final next = _requestGate.remaining(state.phoneNumber);
      state = state.copyWith(cooldownSeconds: next.clamp(0, resendCooldown));
      if (next <= 0) timer.cancel();
    });
  }

  void close() {
    _closed = true;
    _cancelPendingVerification();
    _cooldownTimer?.cancel();
  }

  void _cancelPendingVerification() {
    final repository = _repository;
    if (repository is CancelablePhoneAuthRepository) {
      (repository as CancelablePhoneAuthRepository).cancelPendingVerification();
    }
  }
}
