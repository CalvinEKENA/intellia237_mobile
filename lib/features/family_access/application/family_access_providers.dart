import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/family_access_repository.dart';

final familyAccessRepositoryProvider = Provider<FamilyAccessRepository>(
  (ref) => FirebaseFamilyAccessRepository(),
);
