import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:master_ecology/main.dart';

void main() {
  testWidgets('app launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MasterEcologyApp()));
    await tester.pumpAndSettle();
  });
}
