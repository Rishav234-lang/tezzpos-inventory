import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/providers.dart';

final splashReadyProvider = StateProvider<bool>((ref) => false);

final onboardingSeenProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool('onboarding_complete') ?? false;
});
