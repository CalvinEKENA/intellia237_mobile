import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/profile/application/user_preferences_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('les préférences d’accessibilité sont persistées', () async {
    SharedPreferences.setMockInitialValues(const {});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(userPreferencesProvider.notifier);

    await controller.setTextScale(1.3);
    await controller.setReduceMotion(true);
    await controller.setDataSaver(true);

    final state = container.read(userPreferencesProvider);
    expect(state.textScale, 1.3);
    expect(state.reduceMotion, isTrue);
    expect(state.dataSaver, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('preferences_text_scale'), 1.3);
    expect(prefs.getBool('preferences_reduce_motion'), isTrue);
    expect(prefs.getBool('preferences_data_saver'), isTrue);
  });

  test('la taille du texte est bornée à une plage sûre', () async {
    SharedPreferences.setMockInitialValues(const {});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(userPreferencesProvider.notifier);

    await controller.setTextScale(4);
    expect(container.read(userPreferencesProvider).textScale, 1.5);
  });

  test('l’heure du rappel est persistée sans demander de permission', () async {
    SharedPreferences.setMockInitialValues(const {});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(userPreferencesProvider.notifier)
        .setReminderTime(hour: 19, minute: 15);

    final state = container.read(userPreferencesProvider);
    expect(state.reminderHour, 19);
    expect(state.reminderMinute, 15);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('preferences_reminder_hour'), 19);
    expect(prefs.getInt('preferences_reminder_minute'), 15);
  });
}
