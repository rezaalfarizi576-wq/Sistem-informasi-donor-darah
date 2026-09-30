import 'package:flutter_test/flutter_test.dart';
import 'package:donor_darah_lamongan/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DonorDarahLamonganApp());
    expect(find.text('Donor Darah Lamongan'), findsOneWidget);
  });
}
