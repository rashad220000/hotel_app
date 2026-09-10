import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotel/main.dart';

void main() {
  testWidgets(
    'MaterialApp supplies MaterialLocalizations for RefreshIndicator',
    (tester) async {
      await tester.pumpWidget(const HotelApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(materialApp.localizationsDelegates, isNotNull);
      expect(
        materialApp.localizationsDelegates,
        contains(GlobalMaterialLocalizations.delegate),
      );
      expect(materialApp.supportedLocales, contains(const Locale('ar')));
    },
  );
}
