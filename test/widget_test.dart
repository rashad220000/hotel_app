import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel/main.dart';
import 'package:hotel/screens/splash_screen.dart';

void main() {
  testWidgets('MaterialApp provides localizations for RefreshIndicator', (
    tester,
  ) async {
    await tester.pumpWidget(const HotelApp());

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(
      materialApp.localizationsDelegates,
      contains(GlobalMaterialLocalizations.delegate),
    );
    expect(materialApp.supportedLocales, contains(const Locale('ar')));
  });

  testWidgets('App starts with the premium splash screen', (tester) async {
    await tester.pumpWidget(const HotelApp());

    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
