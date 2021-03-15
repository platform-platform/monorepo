// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/analytics/presentation/state/analytics_notifier.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/base/presentation/widgets/tappable_area.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/user_menu_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/state/theme_notifier.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/common/presentation/toggle/widgets/toggle.dart';
import 'package:metrics/common/presentation/widgets/metrics_user_menu.dart';
import 'package:metrics/feature_config/presentation/state/feature_config_notifier.dart';
import 'package:metrics/feature_config/presentation/view_models/debug_menu_feature_config_view_model.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/analytics_notifier_mock.dart';
import '../../../test_utils/auth_notifier_mock.dart';
import '../../../test_utils/feature_config_notifier_mock.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/navigation_notifier_mock.dart';
import '../../../test_utils/test_injection_container.dart';
import '../../../test_utils/theme_notifier_mock.dart';

void main() {
  group('MetricsUserMenu', () {
    const testBackgroundColor = Colors.white;
    const testDividerColor = Colors.black;
    const testTextStyle = TextStyle(color: Colors.grey);
    const shadowColor = Colors.yellow;

    const testTheme = MetricsThemeData(
      userMenuTheme: UserMenuThemeData(
        backgroundColor: testBackgroundColor,
        dividerColor: testDividerColor,
        contentTextStyle: testTextStyle,
        shadowColor: shadowColor,
      ),
    );

    testWidgets(
      "applies the background color from the user menu theme to the card",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed(
          theme: testTheme,
        ));

        final cardWidget = tester.widget<Card>(find.byType(Card));

        expect(cardWidget.color, equals(testBackgroundColor));
      },
    );

    testWidgets(
      "applies the divider color from the user menu theme to the divider",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed(
          theme: testTheme,
        ));

        final divider = tester.widget<Divider>(find.byType(Divider));

        expect(divider.color, equals(testDividerColor));
      },
    );

    testWidgets(
      "applies the shadow color from the user menu theme to the container's box shadow",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed(
          theme: testTheme,
        ));

        final container = tester.widget<Container>(find.ancestor(
          of: find.byType(Card),
          matching: find.byType(Container),
        ));
        final decoration = container.decoration as BoxDecoration;
        final boxShadow = decoration.boxShadow.first;

        expect(boxShadow.color, equals(shadowColor));
      },
    );

    testWidgets(
      "applies the text style from the user menu theme to the switch theme text widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed(
          theme: testTheme,
        ));

        final textWidget = tester.widget<Text>(
          find.text(CommonStrings.lightTheme),
        );

        expect(textWidget.style, equals(testTextStyle));
      },
    );

    testWidgets(
      "applies the text style from the user menu theme to the project groups Text widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed(
          theme: testTheme,
        ));

        final textWidget = tester.widget<Text>(
          find.text(CommonStrings.projectGroups),
        );

        expect(textWidget.style, equals(testTextStyle));
      },
    );

    testWidgets(
      "applies the text style from the user menu theme to the logOut Text widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed(
          theme: testTheme,
        ));

        final textWidget = tester.widget<Text>(
          find.text(CommonStrings.logOut),
        );

        expect(textWidget.style, equals(testTextStyle));
      },
    );

    testWidgets(
      "applies the text style from the user menu theme to the debug menu Text widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed(
          theme: testTheme,
        ));

        final textWidget = tester.widget<Text>(
          find.text(CommonStrings.debugMenu),
        );

        expect(textWidget.style, equals(testTextStyle));
      },
    );

    testWidgets(
      "applies a tappable area to the project group text widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed());

        final finder = find.ancestor(
          of: find.text(CommonStrings.projectGroups),
          matching: find.byType(TappableArea),
        );

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "applies a tappable area to the logOut text widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed());

        final finder = find.ancestor(
          of: find.text(CommonStrings.logOut),
          matching: find.byType(TappableArea),
        );

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "applies a tappable area to the debug menu text widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _MetricsUserMenuTestbed());

        final finder = find.ancestor(
          of: find.text(CommonStrings.debugMenu),
          matching: find.byType(TappableArea),
        );

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "displays the 'Debug menu' menu item if the debug menu is enabled in feature config",
      (WidgetTester tester) async {
        final featureConfigNotifier = FeatureConfigNotifierMock();

        when(featureConfigNotifier.debugMenuFeatureConfigViewModel).thenReturn(
          const DebugMenuFeatureConfigViewModel(isEnabled: true),
        );

        await tester.pumpWidget(_MetricsUserMenuTestbed(
          featureConfigNotifier: featureConfigNotifier,
        ));

        expect(find.text(CommonStrings.debugMenu), findsOneWidget);
      },
    );

    testWidgets(
      "does not display the 'Debug menu' menu item if the debug menu is disabled in feature config",
      (WidgetTester tester) async {
        final featureConfigNotifier = FeatureConfigNotifierMock();

        when(featureConfigNotifier.debugMenuFeatureConfigViewModel).thenReturn(
          const DebugMenuFeatureConfigViewModel(isEnabled: false),
        );

        await tester.pumpWidget(_MetricsUserMenuTestbed(
          featureConfigNotifier: featureConfigNotifier,
        ));

        expect(find.text(CommonStrings.debugMenu), findsNothing);
      },
    );

    testWidgets(
      "calls the ThemeNotifier.changeTheme() if the toggle widget is tapped",
      (WidgetTester tester) async {
        final themeNotifier = ThemeNotifierMock();

        when(themeNotifier.isDark).thenReturn(false);

        await tester.pumpWidget(
          _MetricsUserMenuTestbed(themeNotifier: themeNotifier),
        );

        await tester.tap(find.byType(Toggle));
        await tester.pumpAndSettle();

        verify(themeNotifier.toggleTheme()).called(once);
      },
    );

    testWidgets(
      "calls the AuthNotifier.signOut() on tap on 'Log out'",
      (tester) async {
        final authNotifier = AuthNotifierMock();

        when(authNotifier.isLoggedIn).thenReturn(true);

        await tester.pumpWidget(_MetricsUserMenuTestbed(
          authNotifier: authNotifier,
        ));

        await tester.tap(find.text(CommonStrings.logOut));
        await mockNetworkImagesFor(() {
          return tester.pump();
        });

        verify(authNotifier.signOut()).called(once);
      },
    );

    testWidgets(
      "calls the AnalyticsNotifier.resetUser() on tap on the 'Log out'",
      (tester) async {
        final analyticsNotifier = AnalyticsNotifierMock();

        await tester.pumpWidget(_MetricsUserMenuTestbed(
          analyticsNotifier: analyticsNotifier,
        ));

        await tester.tap(find.text(CommonStrings.logOut));
        await mockNetworkImagesFor(() {
          return tester.pump();
        });

        verify(analyticsNotifier.resetUser()).called(once);
      },
    );

    testWidgets(
      "after a user taps on 'Project groups' - application navigates to the project group screen",
      (WidgetTester tester) async {
        final authNotifier = AuthNotifierMock();
        final navigationNotifier = NavigationNotifierMock();

        when(authNotifier.isLoggedIn).thenReturn(true);

        await tester.pumpWidget(_MetricsUserMenuTestbed(
          authNotifier: authNotifier,
          navigationNotifier: navigationNotifier,
        ));

        await tester.tap(find.text(CommonStrings.projectGroups));

        verify(
          navigationNotifier.push(MetricsRoutes.projectGroups),
        ).called(once);
      },
    );

    testWidgets(
      "after a user taps on 'Debug menu' - application navigates to the debug menu screen",
      (WidgetTester tester) async {
        final featureConfigNotifier = FeatureConfigNotifierMock();
        final authNotifier = AuthNotifierMock();
        final navigationNotifier = NavigationNotifierMock();

        when(authNotifier.isLoggedIn).thenReturn(true);
        when(featureConfigNotifier.debugMenuFeatureConfigViewModel).thenReturn(
          const DebugMenuFeatureConfigViewModel(isEnabled: true),
        );

        await tester.pumpWidget(_MetricsUserMenuTestbed(
          featureConfigNotifier: featureConfigNotifier,
          authNotifier: authNotifier,
          navigationNotifier: navigationNotifier,
        ));

        await tester.tap(find.text(CommonStrings.debugMenu));

        verify(navigationNotifier.push(
          MetricsRoutes.debugMenu,
        )).called(once);
      },
    );
  });
}

/// A testbed widget, used to test the [MetricsUserMenu] widget.
class _MetricsUserMenuTestbed extends StatelessWidget {
  /// The [MetricsThemeData] used in testbed.
  final MetricsThemeData theme;

  /// A [ThemeNotifier] to use in tests.
  final ThemeNotifier themeNotifier;

  /// An [AuthNotifier] to use in tests.
  final AuthNotifier authNotifier;

  /// An [AnalyticsNotifier] to use in tests.
  final AnalyticsNotifier analyticsNotifier;

  /// A [FeatureConfigNotifier] to use in tests.
  final FeatureConfigNotifier featureConfigNotifier;

  /// A [NavigationNotifier] used in tests.
  final NavigationNotifier navigationNotifier;

  /// Creates the [_MetricsUserMenuTestbed] with the given parameters.
  ///
  /// The [theme] defaults to an empty [MetricsThemeData] instance.
  const _MetricsUserMenuTestbed({
    Key key,
    this.theme = const MetricsThemeData(),
    this.themeNotifier,
    this.authNotifier,
    this.analyticsNotifier,
    this.featureConfigNotifier,
    this.navigationNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      themeNotifier: themeNotifier,
      authNotifier: authNotifier,
      analyticsNotifier: analyticsNotifier,
      featureConfigNotifier: featureConfigNotifier,
      navigationNotifier: navigationNotifier,
      child: Builder(
        builder: (context) {
          return MetricsThemedTestbed(
            metricsThemeData: theme,
            body: const MetricsUserMenu(),
          );
        },
      ),
    );
  }
}
