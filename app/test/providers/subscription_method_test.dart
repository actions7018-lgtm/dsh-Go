import 'package:dsh_app/l10n/l10n.dart';
import 'package:dsh_app/state/account_state.dart' show accountBrowserProvider;
import 'package:dsh_app/state/subscriptions_state.dart';
import 'package:dsh_app/ui/providers/subscription_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../account/support.dart' show FakeBrowser;
import '../shell/golden_harness.dart' show goldenApp;
import 'support.dart';

class _Backend extends FakeSubscriptionBackend {
  String? choice;

  @override
  Future<LoginStep> poll(String attemptId) async => switch (choice) {
    'device_code' => const LoginStep(
      phase: LoginPhase.device,
      url: 'https://auth.openai.com/codex/device',
      userCode: 'TEST-1234',
    ),
    'browser' => const LoginStep(phase: LoginPhase.open, url: 'https://auth.openai.com/oauth/authorize'),
    _ => const LoginStep(
      phase: LoginPhase.select,
      options: [
        LoginOption(id: 'browser', label: 'Browser login (default)'),
        LoginOption(id: 'device_code', label: 'Device code login (headless)'),
      ],
    ),
  };

  @override
  Future<void> answer(String attemptId, String value) async {
    await super.answer(attemptId, value);
    choice = value;
  }
}

void main() {
  for (final method in ['device_code', 'browser']) {
    testWidgets('choose $method without opening a browser before selection', (tester) async {
      final backend = _Backend();
      final browser = FakeBrowser();
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
        return null;
      });
      try {
        await tester.pumpWidget(
          goldenApp(
            home: const Scaffold(body: SubscriptionLoginSheet(subscription: Subscription.chatgpt)),
            brightness: Brightness.light,
            overrides: [
              ...providerOverrides(FakeProviderBackend(), subscriptions: backend),
              accountBrowserProvider.overrideWithValue(browser),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text(appL10n.engineSubscriptionChooseMethod), findsOneWidget);
        expect(browser.opened, isEmpty);
        await tester.tap(
          find.text(
            method == 'device_code' ? appL10n.engineSubscriptionDeviceMethod : appL10n.engineSubscriptionBrowserMethod,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(backend.calls.where((call) => call.startsWith('answer:')), ['answer:att-1:$method']);
        if (method == 'device_code') {
          expect(find.text('TEST-1234'), findsOneWidget);
          expect(browser.opened, isEmpty, reason: 'let the user copy the code before opening verification');
          await tester.tap(find.text(appL10n.engineSubscriptionCopyCode));
          await tester.pump();
          expect(copied, ['TEST-1234']);
          await tester.tap(find.text(appL10n.engineSubscriptionOpenVerification));
          await tester.pump();
          expect(browser.opened, [Uri.parse('https://auth.openai.com/codex/device')]);
        } else {
          expect(browser.opened, [Uri.parse('https://auth.openai.com/oauth/authorize')]);
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      }
      expect(backend.calls, contains('cancel:att-1'));
    });
  }
}
