// Shop settings (0016), no Supabase:
//   * ShopSettingsForm validation: address, contact numbers (format,
//     repeats, 1 to 3), GCash, shop hours, payment window, late fee
//   * hasChanges (Save button / discard prompt)
//   * the screen with a fake service: the owner sees the Save bar and
//     inline errors; staff see the banner, read-only fields, no Save;
//     a load error shows Retry
// Run with: flutter test test/features/shop_dashboard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orange150_rental/core/config/shop_settings.dart';
import 'package:orange150_rental/core/services/shop_settings_service.dart';
import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/shop_dashboard/models/shop_settings_form.dart';
import 'package:orange150_rental/features/shop_dashboard/screens/shop_settings_screen.dart';

/// In-memory shop_settings row.
class _FakeApi implements ShopSettingsApi {
  _FakeApi({this.failRead = false});

  bool failRead;
  Map<String, dynamic>? lastUpdate;

  Map<String, dynamic> row = {
    'id': 1,
    'shop_hours': 'Mon to Sat, 9:00 AM to 6:00 PM',
    'payment_window_hours': 48,
    'late_fee_per_day': 200,
    'address': 'Blk. 39 Lot 20 Bolilao, Mandurriao',
    'contact_numbers': ['09157352844', '09544231197'],
    'gcash_number': '09157352844',
  };

  @override
  Future<Map<String, dynamic>?> readRow() async {
    if (failRead) throw Exception('offline');
    return row;
  }

  @override
  Future<Map<String, dynamic>> update(Map<String, dynamic> params) async {
    lastUpdate = params;
    row = {
      ...row,
      'shop_hours': params['p_shop_hours'],
      'payment_window_hours': params['p_payment_window_hours'],
      'late_fee_per_day': params['p_late_fee_per_day'],
      'address': params['p_address'],
      'contact_numbers': params['p_contact_numbers'],
      'gcash_number': params['p_gcash_number'],
    };
    return row;
  }
}

void main() {
  group('ShopSettingsForm validation', () {
    test('address is required and at most 200 characters', () {
      expect(ShopSettingsForm.validateAddress(''), isNotNull);
      expect(ShopSettingsForm.validateAddress('   '), isNotNull);
      expect(ShopSettingsForm.validateAddress('x' * 201), isNotNull);
      expect(ShopSettingsForm.validateAddress('Mandurriao, Iloilo'), isNull);
    });

    test('contact numbers: 09XXXXXXXXX, no repeats', () {
      final all = ['09157352844', '09157352844', '0915735284'];
      expect(
        ShopSettingsForm.validateContactNumber(all[0], all: all, index: 0),
        isNull,
      );
      expect(
        ShopSettingsForm.validateContactNumber(all[1], all: all, index: 1),
        'This number is already listed.',
      );
      expect(
        ShopSettingsForm.validateContactNumber(all[2], all: all, index: 2),
        isNotNull, // 10 digits
      );
      expect(
        ShopSettingsForm.validateContactNumber(
          '08157352844',
          all: const [],
          index: 0,
        ),
        isNotNull, // must start with 09
      );
      expect(
        ShopSettingsForm.validateContactNumber('', all: const [], index: 0),
        isNotNull, // required
      );
    });

    test('1 to 3 contact numbers', () {
      expect(ShopSettingsForm.validateContactCount(0), isNotNull);
      expect(ShopSettingsForm.validateContactCount(1), isNull);
      expect(ShopSettingsForm.validateContactCount(3), isNull);
      expect(ShopSettingsForm.validateContactCount(4), isNotNull);
    });

    test('GCash number is required and 09XXXXXXXXX', () {
      expect(ShopSettingsForm.validateGcash(''), isNotNull);
      expect(ShopSettingsForm.validateGcash('9157352844'), isNotNull);
      expect(ShopSettingsForm.validateGcash('09157352844'), isNull);
    });

    test('shop hours are optional, at most 120 characters', () {
      expect(ShopSettingsForm.validateHours(''), isNull);
      expect(ShopSettingsForm.validateHours(null), isNull);
      expect(ShopSettingsForm.validateHours('x' * 121), isNotNull);
    });

    test('payment window: chosen, 1 to 168 hours', () {
      expect(ShopSettingsForm.validateWindow(null), isNotNull);
      expect(ShopSettingsForm.validateWindow(0), isNotNull);
      expect(ShopSettingsForm.validateWindow(169), isNotNull);
      for (final hours in ShopSettingsForm.paymentWindowChoices) {
        expect(ShopSettingsForm.validateWindow(hours), isNull);
      }
    });

    test('an unusual saved window stays in the dropdown', () {
      expect(ShopSettingsForm.windowChoicesFor(48), [12, 24, 48, 72]);
      expect(ShopSettingsForm.windowChoicesFor(36), [12, 24, 36, 48, 72]);
      expect(ShopSettingsForm.windowLabel(48), '48 hours (2 days)');
      expect(ShopSettingsForm.windowLabel(24), '24 hours (1 day)');
      expect(ShopSettingsForm.windowLabel(12), '12 hours');
    });

    test('late fee: required number, 0 or more, not too large', () {
      expect(ShopSettingsForm.validateLateFee(''), isNotNull);
      expect(ShopSettingsForm.validateLateFee('.'), isNotNull);
      expect(ShopSettingsForm.validateLateFee('-5'), isNotNull);
      expect(ShopSettingsForm.validateLateFee('1000000'), isNotNull);
      expect(ShopSettingsForm.validateLateFee('0'), isNull);
      expect(ShopSettingsForm.validateLateFee('212.50'), isNull);
      expect(ShopSettingsForm.lateFeeText(200), '200');
      expect(ShopSettingsForm.lateFeeText(212.5), '212.50');
    });

    test('hasChanges spots any edit and ignores outer spaces', () {
      const saved = ShopSettings(
        paymentWindowHours: 48,
        lateFeePerDay: 200,
        address: 'Iloilo',
        contactNumbers: ['09157352844'],
        gcashNumber: '09157352844',
      );
      bool changed({
        String address = 'Iloilo',
        List<String> numbers = const ['09157352844'],
        String gcash = '09157352844',
        String hours = '',
        int window = 48,
        String fee = '200',
      }) => ShopSettingsForm.hasChanges(
        saved: saved,
        address: address,
        contactNumbers: numbers,
        gcash: gcash,
        hours: hours,
        window: window,
        lateFee: fee,
      );

      expect(changed(), isFalse);
      expect(changed(address: ' Iloilo '), isFalse);
      expect(changed(fee: '200.00'), isFalse);
      expect(changed(address: 'Iloilo City'), isTrue);
      expect(changed(numbers: ['09157352844', '09544231197']), isTrue);
      expect(changed(gcash: '09544231197'), isTrue);
      expect(changed(hours: 'Mon to Sat'), isTrue);
      expect(changed(window: 24), isTrue);
      expect(changed(fee: '250'), isTrue);
    });
  });

  group('ShopSettingsScreen', () {
    Future<_FakeApi> pump(
      WidgetTester tester, {
      required bool owner,
      bool failRead = false,
    }) async {
      final api = _FakeApi(failRead: failRead);
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ShopSettingsScreen(
            service: ShopSettingsService(api: api),
            isOwner: owner,
          ),
        ),
      );
      await tester.pumpAndSettle();
      return api;
    }

    testWidgets('owner: Save turns on after an edit and saves', (tester) async {
      final api = await pump(tester, owner: true);
      expect(find.text(ShopSettingsScreen.ownerOnlyMessage), findsNothing);
      expect(find.text('Shop details'), findsOneWidget);
      expect(find.text(ShopSettingsForm.hoursHelper), findsOneWidget);
      expect(find.text('View rental terms'), findsOneWidget);

      FilledButton save() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(save().onPressed, isNull); // nothing changed yet

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Late fee per day *'),
        '250',
      );
      await tester.pump();
      expect(save().onPressed, isNotNull);
      expect(find.text('You have unsaved changes.'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(api.lastUpdate!['p_late_fee_per_day'], 250);
      expect(find.text('Shop settings saved'), findsOneWidget);
      expect(save().onPressed, isNull); // saved = no changes left
      expect(tester.takeException(), isNull);
    });

    testWidgets('owner: a bad number shows an inline error, nothing sent', (
      tester,
    ) async {
      final api = await pump(tester, owner: true);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'GCash number *'),
        '0915',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('09XXXXXXXXX'), findsWidgets);
      expect(api.lastUpdate, isNull);
    });

    testWidgets('owner: add and remove contact numbers (up to 3)', (
      tester,
    ) async {
      await pump(tester, owner: true);
      expect(find.text('Contact number 2 *'), findsOneWidget);
      await tester.tap(find.text('Add contact number'));
      await tester.pump();
      expect(find.text('Contact number 3 *'), findsOneWidget);
      expect(find.text('Add contact number'), findsNothing); // 3 is the max
      await tester.tap(find.byTooltip('Remove contact number 3'));
      await tester.pump();
      expect(find.text('Contact number 3 *'), findsNothing);
    });

    testWidgets('staff: banner, read-only fields, no Save bar', (tester) async {
      await pump(tester, owner: false);
      expect(find.text(ShopSettingsScreen.ownerOnlyMessage), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
      expect(find.text('Add contact number'), findsNothing);
      final address = tester.widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, 'Shop address *'),
          matching: find.byType(EditableText),
        ),
      );
      expect(address.readOnly, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a load error shows Retry', (tester) async {
      await pump(tester, owner: true, failRead: true);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsNothing);
    });
  });
}
