// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/common/presentation/drawer/widget/metrics_drawer.dart';
import 'package:metrics/common/presentation/metrics_theme/state/theme_notifier.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/dashboard/presentation/state/project_metrics_notifier.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../../test_utils/auth_notifier_mock.dart';
import '../../../../test_utils/matchers.dart';
import '../../../../test_utils/navigation_notifier_mock.dart';
import '../../../../test_utils/test_injection_container.dart';
import '../../../../test_utils/theme_notifier_mock.dart';

void main() {
  group("MetricsDrawer", () {
    testWidgets(
      "calls the ThemeNotifier.changeTheme() on tap on a checkbox",
      (WidgetTester tester) async {
        final themeNotifier = ThemeNotifierMock();

        when(themeNotifier.isDark).thenReturn(false);

        await tester.pumpWidget(MetricsDrawerTestbed(
          themeNotifier: themeNotifier,
        ));

        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        verify(themeNotifier.toggleTheme()).called(once);
      },
    );

    testWidgets(
      "calls the AuthNotifier.signOut() on tap on 'Log out'",
      (tester) async {
        final authNotifier = AuthNotifierMock();

        when(authNotifier.isLoggedIn).thenReturn(true);

        await tester.pumpWidget(MetricsDrawerTestbed(
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
      "navigates to the project group page on tap on the project groups list item",
      (tester) async {
        final navigationNotifier = NavigationNotifierMock();

        await tester.pumpWidget(MetricsDrawerTestbed(
          navigationNotifier: navigationNotifier,
        ));

        await tester.tap(find.text(CommonStrings.projectGroups));

        await tester.pumpAndSettle();

        verify(navigationNotifier.push(
          MetricsRoutes.projectGroups,
        )).called(once);
      },
    );
  });
}

/// A testbed widget, used to test the [MetricsDrawer] widget.
class MetricsDrawerTestbed extends StatelessWidget {
  /// A [ThemeNotifier] used in tests.
  final ThemeNotifier themeNotifier;

  /// A [ProjectMetricsNotifier] used in tests.
  final ProjectMetricsNotifier metricsNotifier;

  /// An [AuthNotifier] used in tests.
  final AuthNotifier authNotifier;

  /// A [NavigationNotifier] used in tests.
  final NavigationNotifier navigationNotifier;

  /// Creates a [MetricsDrawerTestbed].
  const MetricsDrawerTestbed({
    Key key,
    this.themeNotifier,
    this.metricsNotifier,
    this.authNotifier,
    this.navigationNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      themeNotifier: themeNotifier,
      metricsNotifier: metricsNotifier,
      authNotifier: authNotifier,
      navigationNotifier: navigationNotifier,
      child: Builder(
        builder: (context) {
          return const MaterialApp(
            home: Scaffold(
              body: MetricsDrawer(),
            ),
          );
        },
      ),
    );
  }
}
