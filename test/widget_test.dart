// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:bigs/main.dart';
import 'package:bigs/api/bigs_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('앱이 초기 화면을 렌더링한다', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final apiClient = BigsApiClient();
    addTearDown(apiClient.close);

    await tester.pumpWidget(BigsApp(
      preferences: prefs,
      apiClient: apiClient,
    ));

    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsWidgets);
  });
}
