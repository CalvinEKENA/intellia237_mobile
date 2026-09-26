import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/application/phone_auth_controller.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/presentation/widgets/intellia_237_membrane.dart';
import 'package:intellia237/features/auth/presentation/widgets/pass_auth_progress.dart';

/// Device QA round 3 : une seule correspondance entre l'état réel des
/// parcours et le sceau « 237 ».
void main() {
  group('phone', () {
    PassSealStage phone(
      PhoneAuthStage stage, {
      String number = '',
      String code = '',
      bool accessOpened = false,
    }) => PassAuthProgress.phone(
      stage: stage,
      phoneInput: number,
      codeInput: code,
      accessOpened: accessOpened,
    );

    test('empty and partial numbers keep every digit neutral', () {
      for (final partial in ['', '6', '699', '6991234', '69912345']) {
        expect(
          phone(PhoneAuthStage.phoneEntry, number: partial),
          PassSealStage.neutral,
          reason: partial,
        );
      }
    });

    test('a valid Cameroon number lights 2, in every accepted form', () {
      for (final valid in [
        '699123456',
        '6 99 12 34 56',
        '+237 699 12 34 56',
        '237699123456',
        '00237699123456',
      ]) {
        expect(
          phone(PhoneAuthStage.phoneEntry, number: valid),
          PassSealStage.identifier,
          reason: valid,
        );
      }
    });

    test('nine digits the SMS would refuse do not light 2', () {
      for (final refused in ['299123456', '6991234567', '0699123456']) {
        expect(
          phone(PhoneAuthStage.phoneEntry, number: refused),
          PassSealStage.neutral,
          reason: refused,
        );
      }
    });

    test('OTP: empty and partial keep 2, six digits light 3', () {
      expect(phone(PhoneAuthStage.codeEntry), PassSealStage.identifier);
      expect(
        phone(PhoneAuthStage.codeEntry, code: '123'),
        PassSealStage.identifier,
      );
      expect(
        phone(PhoneAuthStage.codeEntry, code: '12345'),
        PassSealStage.identifier,
      );
      expect(
        phone(PhoneAuthStage.codeEntry, code: '123456'),
        PassSealStage.secret,
      );
    });

    test('Firebase success lights 3 even when Android read the SMS', () {
      expect(phone(PhoneAuthStage.success), PassSealStage.secret);
      expect(
        phone(PhoneAuthStage.success, code: '123456'),
        PassSealStage.secret,
      );
    });

    test('only an opened space lights 7; a role conflict stays at 3', () {
      expect(
        phone(PhoneAuthStage.success, accessOpened: true),
        PassSealStage.verified,
      );
      expect(
        phone(PhoneAuthStage.success, accessOpened: false),
        PassSealStage.secret,
      );
    });

    test('the engraved line fills keystroke by keystroke, never past its '
        'stage', () {
      var previous = -1.0;
      const number = '699123456';
      for (var i = 0; i <= number.length; i++) {
        final line = PassAuthProgress.phoneLine(
          stage: PhoneAuthStage.phoneEntry,
          phoneInput: number.substring(0, i),
          codeInput: '',
          accessOpened: false,
        );
        expect(line, greaterThan(previous));
        expect(line, lessThanOrEqualTo(1 / 3));
        previous = line;
      }
      for (var i = 0; i <= 6; i++) {
        final line = PassAuthProgress.phoneLine(
          stage: PhoneAuthStage.codeEntry,
          phoneInput: number,
          codeInput: '123456'.substring(0, i),
          accessOpened: false,
        );
        expect(line, greaterThanOrEqualTo(previous));
        expect(line, lessThanOrEqualTo(2 / 3));
        previous = line;
      }
      expect(
        PassAuthProgress.phoneLine(
          stage: PhoneAuthStage.success,
          phoneInput: number,
          codeInput: '',
          accessOpened: true,
        ),
        PassAuthProgress.complete,
      );
    });
  });

  group('e-mail sign-in', () {
    PassSealStage email(String address, String password, {bool open = false}) =>
        PassAuthProgress.emailSignIn(
          email: address,
          password: password,
          accessOpened: open,
        );

    test('empty → valid address → password → access opened', () {
      expect(email('', ''), PassSealStage.neutral);
      expect(email('amina@', ''), PassSealStage.neutral);
      expect(email('amina@ecole.cm', ''), PassSealStage.identifier);
      expect(email('amina@ecole.cm', 'abcdefg'), PassSealStage.identifier);
      expect(email('amina@ecole.cm', 'abcdefgh'), PassSealStage.secret);
      expect(
        email('amina@ecole.cm', 'abcdefgh', open: true),
        PassSealStage.verified,
      );
    });

    test('a password without a valid address lights nothing', () {
      expect(email('amina', 'motdepasse'), PassSealStage.neutral);
    });
  });

  group('password reset', () {
    test('address lights 2, the sent link lights 3, never 7', () {
      expect(
        PassAuthProgress.passwordReset(email: '', linkSent: false),
        PassSealStage.neutral,
      );
      expect(
        PassAuthProgress.passwordReset(email: 'a@b.cm', linkSent: false),
        PassSealStage.identifier,
      );
      expect(
        PassAuthProgress.passwordReset(email: 'a@b.cm', linkSent: true),
        PassSealStage.secret,
      );
    });
  });

  group('account creation (teacher)', () {
    PassSealStage account(
      String address,
      String password,
      String confirmation, {
      bool opened = false,
    }) => PassAuthProgress.accountCreation(
      email: address,
      password: password,
      confirmation: confirmation,
      accountOpened: opened,
    );

    test('credentials drive the seal, not the form steps', () {
      expect(account('', '', ''), PassSealStage.neutral);
      expect(account('serge@ecole.cm', '', ''), PassSealStage.identifier);
      expect(
        account('serge@ecole.cm', 'motdepasse', ''),
        PassSealStage.identifier,
      );
      expect(
        account('serge@ecole.cm', 'motdepasse', 'motdepass'),
        PassSealStage.identifier,
      );
      expect(
        account('serge@ecole.cm', 'motdepasse', 'motdepasse'),
        PassSealStage.secret,
      );
      expect(
        account('serge@ecole.cm', 'motdepasse', 'motdepasse', opened: true),
        PassSealStage.verified,
      );
    });
  });

  group('screens opened after authentication', () {
    test('the seal is complete exactly when a session exists', () {
      final cases = <AuthState, PassSealStage>{
        const AuthState.bootstrapping(): PassSealStage.neutral,
        const AuthState.unauthenticated(): PassSealStage.neutral,
        const AuthState.needsOnboarding(userId: 'u'): PassSealStage.verified,
        const AuthState.authenticated(role: AppRole.parent, userId: 'u'):
            PassSealStage.verified,
        const AuthState.retryableProfileFailure(userId: 'u'):
            PassSealStage.verified,
        const AuthState.legacyProfileRecovery(userId: 'u'):
            PassSealStage.verified,
      };
      for (final entry in cases.entries) {
        expect(
          PassAuthProgress.session(entry.key),
          entry.value,
          reason: '${entry.key.status}',
        );
      }
    });

    test('registration lines fill in equal steps', () {
      expect(
        [
          for (var step = 0; step < 3; step++)
            PassAuthProgress.registrationLine(step: step, steps: 3),
        ],
        [0.25, 0.5, 0.75],
      );
    });

    test('holds keep the second stage and the completed seal readable', () {
      expect(
        PassSealTiming.stageHold,
        greaterThan(Intellia237Motion.colorChange),
      );
      expect(
        PassSealTiming.completionHold - Intellia237Motion.colorChange,
        greaterThanOrEqualTo(const Duration(milliseconds: 1200)),
      );
    });
  });

  /// Garde structurelle : aucun écran ne pose une valeur de son cru.
  group('one canonical mapping in lib/', () {
    final sources = {
      for (final file
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart')))
        file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
    };

    List<({String path, String arguments})> calls(String constructor) => [
      for (final entry in sources.entries)
        for (final match in RegExp(
          '(?<![\\w.])${RegExp.escape(constructor)}\\(',
        ).allMatches(entry.value))
          if (!_isDeclaration(entry.value, match.start))
            (path: entry.key, arguments: _balanced(entry.value, match.end - 1)),
    ];

    test('every Pass states its seal through PassAuthProgress or neutral', () {
      final passes = calls('LivingPass');
      expect(passes.length, greaterThanOrEqualTo(11));
      for (final pass in passes) {
        final seal = _argument(pass.arguments, 'seal');
        expect(
          seal,
          isNotNull,
          reason: '${pass.path}: LivingPass without seal',
        );
        expect(
          seal!.startsWith('PassAuthProgress.') ||
              seal == 'PassSealStage.neutral' ||
              seal == 'seal' ||
              seal == 'widget.seal',
          isTrue,
          reason: '${pass.path}: seal: $seal',
        );
      }
    });

    test('a seal passed down by variable comes from PassAuthProgress', () {
      for (final path in [
        'lib/features/student_registration/presentation/student_registration_flow_screen.dart',
      ]) {
        expect(
          sources[path],
          contains('final seal = PassAuthProgress.session('),
          reason: path,
        );
      }
      for (final screen in calls('AuthSuccessScreen')) {
        final seal = _argument(screen.arguments, 'seal');
        expect(
          seal == 'seal' || (seal?.startsWith('PassAuthProgress.') ?? false),
          isTrue,
          reason: '${screen.path}: seal: $seal',
        );
      }
    });

    test('no screen passes a numeric literal to the Pass', () {
      final literal = RegExp(r'(?<![\w.])\.?\d+(\.\d+)?(?![\w])');
      for (final pass in calls('LivingPass')) {
        for (final name in ['seal', 'progress']) {
          final value = _argument(pass.arguments, name);
          if (value == null) continue;
          expect(
            literal.hasMatch(value),
            isFalse,
            reason: '${pass.path}: $name: $value',
          );
        }
      }
    });

    test('only LivingPass builds the seal, and nothing reads a legacy '
        'progress', () {
      final builders = calls(
        'Intellia237Membrane',
      ).map((call) => call.path).toSet();
      expect(builders, {
        'lib/features/auth/presentation/widgets/living_pass.dart',
      });
      for (final entry in sources.entries) {
        expect(entry.value, isNot(contains('sealProgress')), reason: entry.key);
        expect(
          entry.value,
          isNot(contains('IntelliaColors.cmJaune')),
          reason: entry.key,
        );
      }
    });
  });
}

/// Contenu entre la parenthèse ouvrante à [open] et sa fermante.
String _balanced(String source, int open) {
  var depth = 0;
  String? quote;
  for (var i = open; i < source.length; i++) {
    final char = source[i];
    if (quote == null && source.startsWith('//', i)) {
      final end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end;
      continue;
    }
    if (quote != null) {
      if (char == r'\') {
        i++;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
    } else if ('([{'.contains(char)) {
      depth++;
    } else if (')]}'.contains(char)) {
      depth--;
      if (depth == 0) return source.substring(open + 1, i);
    }
  }
  throw StateError('unbalanced call at $open');
}

/// Expression passée à l'argument nommé [name], au premier niveau.
String? _argument(String arguments, String name) {
  var depth = 0;
  String? quote;
  var start = 0;
  final parts = <String>[];
  for (var i = 0; i < arguments.length; i++) {
    final char = arguments[i];
    if (quote == null && arguments.startsWith('//', i)) {
      final end = arguments.indexOf('\n', i);
      i = end < 0 ? arguments.length : end;
      continue;
    }
    if (quote != null) {
      if (char == r'\') {
        i++;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
    } else if ('([{'.contains(char)) {
      depth++;
    } else if (')]}'.contains(char)) {
      depth--;
    } else if (char == ',' && depth == 0) {
      parts.add(arguments.substring(start, i));
      start = i + 1;
    }
  }
  parts.add(arguments.substring(start));
  for (final part in parts) {
    final withoutComments = part
        .split('\n')
        .where((line) => !line.trim().startsWith('//'))
        .join('\n')
        .trim();
    final prefix = '$name:';
    if (withoutComments.startsWith(prefix)) {
      return withoutComments
          .substring(prefix.length)
          .replaceAll(RegExp(r'\s+'), '')
          .trim();
    }
  }
  return null;
}

/// Vrai pour `const LivingPass({` ou `class LivingPass(` : pas un appel.
bool _isDeclaration(String source, int index) {
  final lineStart = source.lastIndexOf('\n', index) + 1;
  final before = source.substring(lineStart, index).trim();
  final after = source.substring(index);
  return before == 'const' && RegExp(r'^\w+\(\{').hasMatch(after) ||
      before.startsWith('class') ||
      before.startsWith('extends');
}
