// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/auth/presentation/pages/login_page.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/auth/presentation/strings/auth_strings.dart';
import 'package:metrics/auth/presentation/widgets/auth_form.dart';
import 'package:metrics/common/presentation/metrics_theme/model/login_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/state/theme_notifier.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/common/presentation/toast/widgets/negative_toast.dart';
import 'package:metrics/common/presentation/widgets/platform_brightness_observer.dart';
import 'package:metrics/dashboard/presentation/state/project_metrics_notifier.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/auth_notifier_mock.dart';
import '../../../test_utils/auth_notifier_stub.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/navigation_notifier_mock.dart';
import '../../../test_utils/router_delegate_stub.dart';
import '../../../test_utils/test_injection_container.dart';

void main() {
  group("LoginPage", () {
    const error = "Something went wrong";

    const metricsThemeData = MetricsThemeData(
      loginTheme: LoginThemeData(
        titleTextStyle: TextStyle(
          color: Colors.blue,
          fontSize: 20.0,
        ),
      ),
    );

    testWidgets(
      "displays the welcome message",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginPageTestbed());
        });

        expect(find.text(CommonStrings.welcomeMetrics), findsOneWidget);
      },
    );

    testWidgets(
      "applies the title text style from the theme to the welcome message",
      (WidgetTester tester) async {
        final expectedStyle = metricsThemeData.loginTheme.titleTextStyle;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginPageTestbed(
            metricsThemeData: metricsThemeData,
          ));
        });

        final text = tester.widget<Text>(
          find.text(CommonStrings.welcomeMetrics),
        );
        final style = text.style;

        expect(style, equals(expectedStyle));
      },
    );

    testWidgets(
      "displays the authentication form",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginPageTestbed());
        });

        expect(find.byType(AuthForm), findsOneWidget);
      },
    );

    testWidgets(
      "displays the PlatformBrightnessObserver widget",
      (tester) async {
        await tester.pumpWidget(
          const _LoginPageTestbed(),
        );

        expect(find.byType(PlatformBrightnessObserver), findsOneWidget);
      },
    );

    testWidgets(
      "displays the negative toast when there is an auth error message",
      (WidgetTester tester) async {
        final authNotifier = AuthNotifierMock();
        when(authNotifier.isLoading).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_LoginPageTestbed(
            authNotifier: authNotifier,
          ));
        });

        when(authNotifier.authErrorMessage).thenReturn(error);
        authNotifier.notifyListeners();

        await mockNetworkImagesFor(() {
          return tester.pumpAndSettle();
        });

        expect(find.widgetWithText(NegativeToast, error), findsOneWidget);

        ToastManager().dismissAll();
      },
    );

    testWidgets(
      "displays the negative toast when there is an error occurred during the user profile saving operation",
      (WidgetTester tester) async {
        final authNotifier = AuthNotifierMock();
        when(authNotifier.isLoading).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_LoginPageTestbed(
            authNotifier: authNotifier,
          ));
        });

        when(authNotifier.userProfileSavingErrorMessage).thenReturn(error);
        authNotifier.notifyListeners();
        await tester.pumpAndSettle();

        expect(find.widgetWithText(NegativeToast, error), findsOneWidget);

        ToastManager().dismissAll();
      },
    );

    testWidgets(
      "displays the negative toast when there is an error occurred during loading user profile data",
      (WidgetTester tester) async {
        final authNotifier = AuthNotifierMock();
        when(authNotifier.isLoading).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_LoginPageTestbed(
            authNotifier: authNotifier,
          ));
        });

        when(authNotifier.userProfileErrorMessage).thenReturn(error);
        authNotifier.notifyListeners();
        await tester.pumpAndSettle();

        expect(find.widgetWithText(NegativeToast, error), findsOneWidget);

        ToastManager().dismissAll();
      },
    );

    testWidgets(
      "closes and navigates to the dashboard page if the login was successful",
      (WidgetTester tester) async {
        final navigationNotifier = NavigationNotifierMock();

        when(navigationNotifier.currentConfiguration).thenReturn(
          MetricsRoutes.dashboard,
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_LoginPageTestbed(
            authNotifier: AuthNotifierStub(),
            navigationNotifier: navigationNotifier,
          ));
        });

        await tester.enterText(
          find.widgetWithText(TextFormField, AuthStrings.email),
          'test@email.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, AuthStrings.password),
          'testPassword',
        );
        await tester.tap(find.widgetWithText(RaisedButton, AuthStrings.signIn));

        await mockNetworkImagesFor(() {
          return tester.pumpAndSettle();
        });

        verify(navigationNotifier.pushStateReplacement(
          MetricsRoutes.dashboard,
        )).called(once);
      },
    );

    testWidgets(
      "closes and navigates to the dashboard page on open if the user is logged in",
      (tester) async {
        final authNotifier = AuthNotifierMock();
        final navigationNotifier = NavigationNotifierMock();

        when(navigationNotifier.currentConfiguration).thenReturn(
          MetricsRoutes.dashboard,
        );

        when(authNotifier.isLoading).thenReturn(false);
        when(authNotifier.isLoggedIn).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _LoginPageTestbed(
              authNotifier: authNotifier,
              navigationNotifier: navigationNotifier,
            ),
          );
        });

        verify(navigationNotifier.pushStateReplacement(
          MetricsRoutes.dashboard,
        )).called(once);
      },
    );
  });
}

/// A testbed widget, used to test the [LoginPage] widget.
class _LoginPageTestbed extends StatelessWidget {
  /// A [GlobalKey] for the [LoginPage] to use in tests.
  final GlobalKey loginKey;

  /// A [MetricsThemeData] to use in tests.
  final MetricsThemeData metricsThemeData;

  /// An [AuthNotifier] used in tests.
  final AuthNotifier authNotifier;

  /// A [ProjectMetricsNotifier] used in tests.
  final ProjectMetricsNotifier metricsNotifier;

  /// A [NavigationNotifier] used in tests.
  final NavigationNotifier navigationNotifier;

  /// A [ThemeNotifier] used in tests.
  final ThemeNotifier themeNotifier;

  /// Creates a new instance of the [_LoginPageTestbed] with the given parameters.
  ///
  /// The [metricsThemeData] defaults to an empty [MetricsThemeData] instance.
  const _LoginPageTestbed({
    this.metricsThemeData = const MetricsThemeData(),
    this.authNotifier,
    this.metricsNotifier,
    this.loginKey,
    this.navigationNotifier,
    this.themeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      authNotifier: authNotifier,
      metricsNotifier: metricsNotifier,
      navigationNotifier: navigationNotifier,
      themeNotifier: themeNotifier,
      child: Builder(
        builder: (context) {
          return MetricsThemedTestbed(
            metricsThemeData: metricsThemeData,
            body: Router(
              routerDelegate: RouterDelegateStub(
                body: LoginPage(key: loginKey),
              ),
            ),
          );
        },
      ),
    );
  }
}
