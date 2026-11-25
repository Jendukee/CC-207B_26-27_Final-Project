// Staff accounts (owner only, manage-staff), no Supabase:
//   * StaffPassword: at least 8 characters with a letter and a number;
//     confirm must match
//   * StaffEmail / StaffName validation and normalizing
//   * the "Add staff" sheet: bad input shows errors and sends nothing;
//     good input is sent cleaned; a server error stays in the sheet
//   * the "Reset password" sheet: rule + confirm, show / hide toggle
//   * StaffMember.fromMap (is_disabled) and the card's Disabled chip / menu
//   * friendly messages for failed function calls
// Run with: flutter test test/features/shop_dashboard

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:orange150_rental/core/theme/app_theme.dart';
import 'package:orange150_rental/features/shop_dashboard/models/staff_member.dart';
import 'package:orange150_rental/features/shop_dashboard/services/staff_accounts_service.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/add_staff_sheet.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/reset_password_sheet.dart';
import 'package:orange150_rental/features/shop_dashboard/widgets/staff_member_card.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  group('StaffPassword', () {
    test('needs 8+ characters', () {
      expect(StaffPassword.validate(null), 'Password is required.');
      expect(StaffPassword.validate(''), 'Password is required.');
      expect(StaffPassword.validate('abc123'), 'Use at least 8 characters.');
      expect(StaffPassword.validate('abcd123'), 'Use at least 8 characters.');
    });

    test('needs a letter AND a number', () {
      const rule = 'Use at least one letter and one number.';
      expect(StaffPassword.validate('abcdefgh'), rule);
      expect(StaffPassword.validate('12345678'), rule);
      expect(StaffPassword.validate('!!!!!!!!'), rule);
    });

    test('accepts a good password, at most 72 characters', () {
      expect(StaffPassword.validate('orange150'), isNull);
      expect(StaffPassword.validate('Abcdefg1'), isNull);
      expect(StaffPassword.validate('a1 with spaces!'), isNull);
      expect(StaffPassword.validate('a1${'x' * 70}'), isNull); // 72
      expect(StaffPassword.validate('a1${'x' * 71}'), isNotNull); // 73
    });

    test('confirm must match exactly', () {
      expect(StaffPassword.validateConfirm('', 'orange150'), isNotNull);
      expect(
        StaffPassword.validateConfirm('Orange150', 'orange150'),
        'The passwords do not match.',
      );
      expect(StaffPassword.validateConfirm('orange150', 'orange150'), isNull);
    });
  });

  group('StaffEmail and StaffName', () {
    test('email: required and a valid address', () {
      expect(StaffEmail.validate(''), 'Email is required.');
      expect(StaffEmail.validate('   '), 'Email is required.');
      for (final bad in [
        'pearl',
        'pearl@',
        '@example.com',
        'pearl@example',
        'pearl example@mail.com',
        'pearl@@example.com',
      ]) {
        expect(
          StaffEmail.validate(bad),
          'Enter a valid email address.',
          reason: bad,
        );
      }
      expect(StaffEmail.validate('  Pearl.B@Example.COM '), isNull);
      expect(StaffEmail.normalize('  Pearl@Example.COM '), 'pearl@example.com');
    });

    test('name: required, at most 120, spaces collapsed', () {
      expect(StaffName.validate(''), isNotNull);
      expect(StaffName.validate('x' * 121), isNotNull);
      expect(StaffName.validate('Pearl Batumbakal'), isNull);
      expect(StaffName.normalize('  Pearl   Batumbakal '), 'Pearl Batumbakal');
    });
  });

  group('Add staff sheet', () {
    Future<List<NewStaff>> pumpSheet(
      WidgetTester tester, {
      String? answer,
    }) async {
      final sent = <NewStaff>[];
      await _pump(
        tester,
        AddStaffSheet(
          onSubmit: (staff) async {
            sent.add(staff);
            return answer;
          },
        ),
      );
      return sent;
    }

    Future<void> fill(
      WidgetTester tester, {
      String name = 'Pearl  Batumbakal',
      String email = ' Pearl@Example.com ',
      String phone = '',
      String password = 'orange150',
      String? confirm,
    }) async {
      await tester.enterText(_field('Full name *'), name);
      await tester.enterText(_field('Email *'), email);
      await tester.enterText(_field('Mobile number (optional)'), phone);
      await tester.enterText(_field('Password *'), password);
      await tester.enterText(_field('Confirm password *'), confirm ?? password);
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.ensureVisible(find.text('Create staff account'));
      await tester.tap(find.text('Create staff account'));
      await tester.pump();
    }

    testWidgets('shows the password helper', (tester) async {
      await pumpSheet(tester);
      expect(find.text(StaffPassword.helper), findsOneWidget);
    });

    testWidgets('empty form: errors, nothing sent', (tester) async {
      final sent = await pumpSheet(tester);
      await submit(tester);
      expect(find.text('Full name is required.'), findsOneWidget);
      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
      expect(sent, isEmpty);
    });

    testWidgets('weak password and mismatch are refused', (tester) async {
      final sent = await pumpSheet(tester);
      await fill(tester, password: 'abcdefgh', confirm: 'abcdefgx');
      await submit(tester);
      expect(
        find.text('Use at least one letter and one number.'),
        findsOneWidget,
      );
      expect(find.text('The passwords do not match.'), findsOneWidget);
      expect(sent, isEmpty);
    });

    testWidgets('bad email or phone is refused', (tester) async {
      final sent = await pumpSheet(tester);
      await fill(tester, email: 'pearl@', phone: '0917');
      await submit(tester);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(sent, isEmpty);
    });

    testWidgets('good input is sent cleaned', (tester) async {
      final sent = await pumpSheet(tester);
      await fill(tester, phone: '09171234567');
      await submit(tester);
      expect(sent, hasLength(1));
      expect(sent.single.fullName, 'Pearl Batumbakal');
      expect(sent.single.email, 'pearl@example.com');
      expect(sent.single.phone, '09171234567');
      expect(sent.single.password, 'orange150');
    });

    testWidgets('no phone is sent as null', (tester) async {
      final sent = await pumpSheet(tester);
      await fill(tester);
      await submit(tester);
      expect(sent.single.phone, isNull);
    });

    testWidgets('a server error stays in the sheet', (tester) async {
      const exists = 'An account with this email already exists.';
      await pumpSheet(tester, answer: exists);
      await fill(tester);
      await submit(tester);
      await tester.pump();
      expect(find.text(exists), findsOneWidget);
      expect(find.text('Create staff account'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Reset password sheet', () {
    testWidgets('rule, confirm and show / hide', (tester) async {
      final sent = <String>[];
      await _pump(
        tester,
        ResetPasswordSheet(
          name: 'Pearl',
          onSubmit: (password) async {
            sent.add(password);
            return null;
          },
        ),
      );
      EditableText editable(String label) => tester.widget<EditableText>(
        find.descendant(of: _field(label), matching: find.byType(EditableText)),
      );

      // Hidden by default; the eye shows it.
      expect(editable('New password *').obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password').first);
      await tester.pump();
      expect(editable('New password *').obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);

      await tester.enterText(_field('New password *'), 'short1');
      await tester.enterText(_field('Confirm new password *'), 'short1');
      await tester.tap(find.text('Set new password'));
      await tester.pump();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(sent, isEmpty);

      await tester.enterText(_field('New password *'), 'newpass99');
      await tester.enterText(_field('Confirm new password *'), 'newpass99');
      await tester.tap(find.text('Set new password'));
      await tester.pump();
      expect(sent, ['newpass99']);
    });
  });

  group('StaffMember and card', () {
    final disabled = StaffMember.fromMap({
      'id': 'u1',
      'full_name': 'Pearl Batumbakal',
      'email': 'pearl@example.com',
      'phone': null,
      'role': 'staff',
      'is_disabled': true,
      'created_at': '2026-11-24T10:00:00Z',
    });

    test('fromMap reads is_disabled and created_at', () {
      expect(disabled.isDisabled, isTrue);
      expect(disabled.createdAt, DateTime.utc(2026, 11, 24, 10));
      expect(disabled.phone, isNull);
      expect(
        StaffMember.fromMap({'id': 'u2', 'role': 'staff'}).isDisabled,
        isFalse,
      );
    });

    testWidgets('disabled staff: chip and "Enable account"', (tester) async {
      StaffAction? chosen;
      await _pump(
        tester,
        StaffMemberCard(member: disabled, onAction: (a) => chosen = a),
      );
      expect(find.text('Disabled'), findsOneWidget);
      await tester.tap(find.byTooltip('Actions for Pearl Batumbakal'));
      await tester.pumpAndSettle();
      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Disable account'), findsNothing);
      await tester.tap(find.text('Enable account'));
      await tester.pumpAndSettle();
      expect(chosen, StaffAction.enable);
      expect(tester.takeException(), isNull);
    });

    testWidgets('owner card has no menu', (tester) async {
      await _pump(
        tester,
        StaffMemberCard(
          member: StaffMember.fromMap({
            'id': 'o1',
            'full_name': 'Shop Owner',
            'role': 'owner',
          }),
          onAction: (_) {},
        ),
      );
      expect(find.text('Owner'), findsOneWidget);
      expect(find.byType(PopupMenuButton<StaffAction>), findsNothing);
    });
  });

  group('function error messages', () {
    test("the function's own error text wins", () {
      const error = FunctionException(
        status: 409,
        details: {'error': 'An account with this email already exists.'},
      );
      expect(
        StaffAccountsService.messageFor(error, fallback: 'x'),
        'An account with this email already exists.',
      );
    });

    test('by status when there is no text', () {
      expect(
        StaffAccountsService.messageFor(
          const FunctionException(status: 403),
          fallback: 'x',
        ),
        'Only the owner can manage staff accounts.',
      );
      expect(
        StaffAccountsService.messageFor(
          const FunctionException(status: 500),
          fallback: 'fallback',
        ),
        'fallback',
      );
    });
  });
}
