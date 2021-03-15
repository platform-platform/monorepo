// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/common/presentation/metrics_theme/state/theme_notifier.dart';
import 'package:metrics/common/presentation/widgets/platform_brightness_observer.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils/auth_notifier_mock.dart';
import '../../../test_utils/binding_util.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/test_injection_container.dart';
import '../../../test_utils/theme_notifier_mock.dart';

void main() {
  group("PlatformBrightnessObserver", () {
    testWidgets(
      "throws an AssertionError if the given child is null",
      (tester) async {
        await tester.pumpWidget(const _PlatformBrightnessObserverTestbed(
          child: null,
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "displays the given child",
      (tester) async {
        const child = Text('child');

        await tester.pumpWidget(const _PlatformBrightnessObserverTestbed(
          child: child,
        ));

        expect(find.byWidget(child), findsOneWidget);
      },
    );

    testWidgets(
      "sets the application theme based on the platform brightness once opened",
      (tester) async {
        final themeNotifier = ThemeNotifierMock();
        final currentBrightness = tester.binding.window.platformBrightness;

        await tester.pumpWidget(
          _PlatformBrightnessObserverTestbed(themeNotifier: themeNotifier),
        );

        verify(themeNotifier.setTheme(currentBrightness)).called(once);
      },
    );

    testWidgets(
      "does not set the application theme based on the platform brightness once opened if a user is logged in",
      (tester) async {
        final themeNotifier = ThemeNotifierMock();
        final authNotifier = AuthNotifierMock();

        when(authNotifier.isLoggedIn).thenReturn(true);

        await tester.pumpWidget(
          _PlatformBrightnessObserverTestbed(
            themeNotifier: themeNotifier,
            authNotifier: authNotifier,
          ),
        );

        verifyNever(themeNotifier.setTheme(any));
      },
    );

    testWidgets(
      "updates the application theme based on the platform brightness once brightness changed",
      (tester) async {
        const brightness = Brightness.dark;
        final themeNotifier = ThemeNotifierMock();
        BindingUtil.setPlatformBrightness(tester, Brightness.light);

        await tester.pumpWidget(_PlatformBrightnessObserverTestbed(
          themeNotifier: themeNotifier,
        ));

        BindingUtil.setPlatformBrightness(tester, brightness);
        await tester.pump();

        verify(themeNotifier.setTheme(brightness)).called(once);
      },
    );
  });
}

/// A testbed class used to test the [PlatformBrightnessObserver] widget.
class _PlatformBrightnessObserverTestbed extends StatelessWidget {
  /// A [ThemeNotifier] used in tests.
  final ThemeNotifier themeNotifier;

  /// An [AuthNotifier] used in tests.
  final AuthNotifier authNotifier;

  /// A child widget of the [PlatformBrightnessObserver].
  final Widget child;

  /// Creates a new instance of the platform brightness observer testbed.
  ///
  /// The [child] defaults to [SizedBox].
  const _PlatformBrightnessObserverTestbed({
    Key key,
    this.themeNotifier,
    this.authNotifier,
    this.child = const SizedBox(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      themeNotifier: themeNotifier,
      authNotifier: authNotifier,
      child: MetricsThemedTestbed(
        body: PlatformBrightnessObserver(
          child: child,
        ),
      ),
    );
  }
}
