import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/firebase_phone_auth_repository.dart';
import '../domain/cameroon_phone_number.dart';
import '../domain/repositories/phone_auth_repository.dart';

enum PhoneAuthStage { phoneEntry, codeEntry, success }

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
      );
      ref.onDispose(controller.close);
      return controller;
    });

class PhoneAuthController extends StateNotifier<PhoneAuthState> {
  PhoneAuthController({
    required PhoneAuthRepository repository,
    required this.linkCurrentUser,
  }) : _repository = repository,
       super(const PhoneAuthState());

  static const resendCooldown = 45;

  final PhoneAuthRepository _repository;
  final bool linkCurrentUser;
  Timer? _cooldownTimer;
  bool _closed = false;

  Future<void> sendCode(String rawPhone) async {
    String phone;
    try {
      phone = CameroonPhoneNumber.normalize(rawPhone);
    } on PhoneNumberFormatException {
      state = state.copyWith(errorCode: 'invalid-phone-number');
      return;
    }

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
        forceResendingToken: state.resendToken,
        onVerified: _handleVerified,
        onFailed: _handleFailure,
        onCodeSent: _handleCodeSent,
        onAutoRetrievalTimeout: _handleTimeout,
      );
    } on PhoneAuthFailure catch (error) {
      _handleFailure(error);
    } catch (_) {
      _handleFailure(const PhoneAuthFailure('unknown-error'));
    }
  }

  Future<void> confirmCode(String code) async {
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
    await sendCode(state.phoneNumber);
  }

  void changePhoneNumber() {
    _cooldownTimer?.cancel();
    state = PhoneAuthState(phoneNumber: state.phoneNumber);
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
    if (_closed) return;
    state = state.copyWith(isLoading: false, errorCode: failure.code);
  }

  void _handleTimeout(String verificationId) {
    if (_closed || state.stage == PhoneAuthStage.success) return;
    state = state.copyWith(
      verificationId: verificationId,
      isLoading: false,
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
      final next = state.cooldownSeconds - 1;
      state = state.copyWith(cooldownSeconds: next.clamp(0, resendCooldown));
      if (next <= 0) timer.cancel();
    });
  }

  void close() {
    _closed = true;
    _cooldownTimer?.cancel();
  }
}
