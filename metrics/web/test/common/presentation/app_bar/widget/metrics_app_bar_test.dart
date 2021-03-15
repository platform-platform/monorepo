// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/svg_image.dart';
import 'package:metrics/base/presentation/widgets/tappable_area.dart';
import 'package:metrics/common/presentation/app_bar/widget/metrics_app_bar.dart';
import 'package:metrics/common/presentation/metrics_theme/config/dimensions_config.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/common/presentation/user_menu_button/widgets/metrics_user_menu_button.dart';
import 'package:metrics/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../../test_utils/matchers.dart';
import '../../../../test_utils/navigation_notifier_mock.dart';
import '../../../../test_utils/test_injection_container.dart';

void main() {
  group("MetricsAppBar", () {
    testWidgets("displays the app logo", (WidgetTester tester) async {
      await mockNetworkImagesFor(() {
        return tester.pumpWidget(const _MetricsAppBarTestbed());
      });

      final finder = find.descendant(
        of: find.byTooltip(CommonStrings.home),
        matching: find.byType(SvgImage),
      );

      expect(finder, findsOneWidget);
    });

    testWidgets(
      "applies a tappable area to the app logo",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _MetricsAppBarTestbed());
        });

        final finder = find.descendant(
          of: find.byTooltip(CommonStrings.home),
          matching: find.byType(TappableArea),
        );

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "navigates to the dashboard page when the app logo is tapped",
      (WidgetTester tester) async {
        final navigationNotifier = NavigationNotifierMock();

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_MetricsAppBarTestbed(
            navigationNotifier: navigationNotifier,
          ));
        });

        await tester.tap(
          find.byTooltip(CommonStrings.home),
        );
        await mockNetworkImagesFor(() {
          return tester.pumpAndSettle();
        });

        verify(navigationNotifier.pushAndRemoveUntil(
          MetricsRoutes.dashboard,
          any,
        )).called(once);
      },
    );

    testWidgets(
      "app bar width equals to the dimensions config content width",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _MetricsAppBarTestbed());
        });

        final sizedBoxPredicate = find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.width == DimensionsConfig.contentWidth,
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(MetricsAppBar),
          matching: sizedBoxPredicate,
        );

        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      "app bar height equals to the dimensions config app bar height",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _MetricsAppBarTestbed());
        });

        final sizedBoxPredicate = find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.height == DimensionsConfig.appBarHeight,
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(MetricsAppBar),
          matching: sizedBoxPredicate,
        );

        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      "displays the metrics user menu button",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _MetricsAppBarTestbed());
        });

        expect(find.byType(MetricsUserMenuButton), findsOneWidget);
      },
    );
  });
}

/// A testbed widget, used to test the [MetricsAppBar] widget.
class _MetricsAppBarTestbed extends StatelessWidget {
  /// A [NavigationNotifier] used in tests.
  final NavigationNotifier navigationNotifier;

  /// Creates the [_MetricsAppBarTestbed] with the given [navigationNotifier].
  const _MetricsAppBarTestbed({
    Key key,
    this.navigationNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      navigationNotifier: navigationNotifier,
      child: MaterialApp(
        routes: {
          '/dashboard': (context) => DashboardPage(),
        },
        home: const Scaffold(
          body: MetricsAppBar(),
        ),
      ),
    );
  }
}
