import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_experience_scaffold.dart';
import 'widgets/intellia_237_membrane.dart';
import 'widgets/living_pass.dart';

/// Screen allowing safe account linking with explicit proof-of-control.
///
/// Prevents identity collision: never merges accounts based on email string alone.
/// Requires phone SMS OTP or password verification before linking credentials.
class AccountLinkingScreen extends ConsumerStatefulWidget {
  const AccountLinkingScreen({super.key});

  @override
  ConsumerState<AccountLinkingScreen> createState() =>
      _AccountLinkingScreenState();
}

class _AccountLinkingScreenState extends ConsumerState<AccountLinkingScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPhoneMode = true;
  bool _codeSent = false;
  String? _verificationId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendPhoneCode() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.length < 9) {
      setState(
        () => _errorMessage = 'Veuillez saisir un numéro de téléphone valide.',
      );
      return;
    }

    final formattedNumber = rawNumber.startsWith('+')
        ? rawNumber
        : '+237$rawNumber';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _finalizePhoneLinking(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = 'Échec d’envoi du SMS : ${e.message}';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _codeSent = true;
            _verificationId = verificationId;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Une erreur est survenue lors de l’envoi du code SMS.';
      });
    }
  }

  Future<void> _verifyOtpAndLink() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length < 6 || _verificationId == null) {
      setState(
        () => _errorMessage =
            'Veuillez saisir le code à 6 chiffres reçu par SMS.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await _finalizePhoneLinking(phoneCredential);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Code SMS invalide ou expiré.';
      });
    }
  }

  Future<void> _finalizePhoneLinking(
    PhoneAuthCredential phoneCredential,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Aucune session active.');
      }

      // Re-authenticate or link to current user
      await currentUser.linkWithCredential(phoneCredential);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      await ref.read(authControllerProvider.notifier).completeBootstrap();
      if (mounted) {
        context.go(AppRoutes.authGateway);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'credential-already-in-use' ||
            e.code == 'provider-already-linked') {
          _errorMessage =
              'Ce numéro de téléphone est déjà lié à un autre compte INTELLIA237.';
        } else {
          _errorMessage = 'Impossible de lier ce compte : ${e.message}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur inattendue lors de la liaison de compte.';
      });
    }
  }

  Future<void> _linkEmailAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(
        () => _errorMessage =
            'Veuillez saisir votre e-mail et votre mot de passe.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final emailCredential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Aucune session active.');
      }

      await currentUser.linkWithCredential(emailCredential);
      if (!mounted) return;

      setState(() => _isLoading = false);
      await ref.read(authControllerProvider.notifier).completeBootstrap();
      if (mounted) {
        context.go(AppRoutes.authGateway);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'credential-already-in-use') {
          _errorMessage = 'Cet e-mail est déjà associé à un autre compte.';
        } else if (e.code == 'wrong-password') {
          _errorMessage = 'Mot de passe incorrect.';
        } else {
          _errorMessage = 'Impossible de lier ce compte : ${e.message}';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur inattendue lors de la liaison de compte.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthExperienceScaffold(
      showBackButton: true,
      onBack: () => context.pop(),
      pass: const LivingPass(
        seal: PassSealStage.neutral,
        phase: 'Liaison de compte sécurisée',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: AuthHeader(
              showBrand: false,
              eyebrow: 'SÉCURITÉ & IDENTITÉ',
              title: 'Lier mon compte existant',
              subtitle:
                  'Pour rattacher votre Google à votre compte INTELLIA237, confirmez la possession de votre numéro ou mot de passe.',
            ),
          ),
          const SizedBox(height: 24),

          // Selector Phone / Email
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Numéro de téléphone'),
                icon: Icon(Icons.phone_android_rounded, size: 16),
              ),
              ButtonSegment(
                value: false,
                label: Text('E-mail / Mot de passe'),
                icon: Icon(Icons.email_outlined, size: 16),
              ),
            ],
            selected: {_isPhoneMode},
            onSelectionChanged: (set) => setState(() {
              _isPhoneMode = set.first;
              _errorMessage = null;
            }),
          ),
          const SizedBox(height: 20),

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB91C1C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 13,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_isPhoneMode) ...[
            if (!_codeSent) ...[
              TextField(
                key: const ValueKey('link-phone-input'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone Cameroun',
                  hintText: '6XX XXX XXX',
                  prefixText: '🇨🇲 +237 ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('link-phone-send-btn'),
                onPressed: _isLoading ? null : _sendPhoneCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Envoyer le code SMS'),
              ),
            ] else ...[
              TextField(
                key: const ValueKey('link-otp-input'),
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Code de vérification SMS',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('link-otp-verify-btn'),
                onPressed: _isLoading ? null : _verifyOtpAndLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003366),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Valider et associer mon compte'),
              ),
            ],
          ] else ...[
            TextField(
              key: const ValueKey('link-email-input'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse e-mail du compte',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('link-password-input'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('link-email-verify-btn'),
              onPressed: _isLoading ? null : _linkEmailAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003366),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Associer mon compte'),
            ),
          ],
        ],
      ),
    );
  }
}
