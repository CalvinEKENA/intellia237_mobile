import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'bootstrap.dart';

void main() {
  bootstrap(() => const ProviderScope(child: EduNovaApp()));
}
