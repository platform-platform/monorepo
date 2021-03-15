// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/svg_image.dart';
import 'package:metrics/base/presentation/widgets/tappable_area.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:metrics/common/presentation/page_title/theme/page_title_theme_data.dart';
import 'package:metrics/common/presentation/page_title/widgets/metrics_page_title.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../../test_utils/matchers.dart';
import '../../../../test_utils/metrics_themed_testbed.dart';
import '../../../../test_utils/navigation_notifier_mock.dart';
import '../../../../test_utils/test_injection_container.dart';

void main() {
  group("MetricsPageTitle", () {
    const testIconColor = Colors.red;
    const testTextStyle = TextStyle(fontSize: 6.0);
    const testTheme = MetricsThemeData(
      pageTitleTheme: PageTitleThemeData(
        iconColor: testIconColor,
        textStyle: testTextStyle,
      ),
    );

    testWidgets(
      "throws an AssertionError if a text is null",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _MetricsPageTitleTestbed(title: null),
          );
        });

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets("displays the arrow back icon", (WidgetTester tester) async {
      await mockNetworkImagesFor(() {
        return tester.pumpWidget(
          const _MetricsPageTitleTestbed(),
        );
      });

      final finder = find.descendant(
        of: find.byTooltip(CommonStrings.navigateBack),
        matching: find.byType(SvgImage),
      );

      expect(finder, findsOneWidget);
    });

    testWidgets(
      "applies a tappable area to the arrow back icon",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _MetricsPageTitleTestbed(),
          );
        });

        final finder = find.descendant(
          of: find.byTooltip(CommonStrings.navigateBack),
          matching: find.byType(TappableArea),
        );

        expect(finder, findsOneWidget);
      },
    );

    testWidgets("displays the given title", (WidgetTester tester) async {
      const title = 'test';

      await mockNetworkImagesFor(() {
        return tester.pumpWidget(
          const _MetricsPageTitleTestbed(title: title),
        );
      });

      expect(find.text(title), findsOneWidget);
    });

    testWidgets(
      "navigates to the dashboard page on tap on the back button",
      (WidgetTester tester) async {
        final navigationNotifier = NavigationNotifierMock();

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_MetricsPageTitleTestbed(
            navigationNotifier: navigationNotifier,
          ));
        });

        await tester.tap(find.byTooltip(CommonStrings.navigateBack));

        verify(navigationNotifier.push(
          MetricsRoutes.dashboard,
        )).called(once);
      },
    );

    testWidgets(
      "applies the title style from the metrics theme to the title text",
      (WidgetTester tester) async {
        const testTitle = 'test title';

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _MetricsPageTitleTestbed(
            theme: testTheme,
            title: testTitle,
          ));
        });

        final textWidget = tester.widget<Text>(
          find.text(testTitle),
        );

        expect(textWidget.style, equals(testTextStyle));
      },
    );

    testWidgets(
      "applies the icon color from the metrics theme to the icon",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _MetricsPageTitleTestbed(
            theme: testTheme,
          ));
        });

        final iconFinder = find.descendant(
          of: find.byTooltip(CommonStrings.navigateBack),
          matching: find.byType(SvgImage),
        );

        final iconWidget = tester.widget<SvgImage>(iconFinder);

        expect(iconWidget.color, equals(testIconColor));
      },
    );
  });
}

/// A testbed widget, used to test the [MetricsPageTitle] widget.
class _MetricsPageTitleTestbed extends StatelessWidget {
  /// A title to display.
  final String title;

  /// A [MetricsThemeData] used in tests.
  final MetricsThemeData theme;

  /// A [NavigationNotifier] used in tests.
  final NavigationNotifier navigationNotifier;

  /// Creates the [_MetricsPageTitleTestbed] with the given parameters.
  ///
  /// The [title] defaults to `title`.
  /// The [theme] defaults to [MetricsThemeData].
  const _MetricsPageTitleTestbed({
    Key key,
    this.title = 'title',
    this.theme = const MetricsThemeData(),
    this.navigationNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      navigationNotifier: navigationNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: theme,
        body: MetricsPageTitle(
          title: title,
        ),
      ),
    );
  }
}
