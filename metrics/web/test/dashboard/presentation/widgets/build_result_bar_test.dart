// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/graphs/placeholder_bar.dart';
import 'package:metrics/common/presentation/colored_bar/widgets/metrics_colored_bar.dart';
import 'package:metrics/common/presentation/graph_indicator/widgets/graph_indicator.dart';
import 'package:metrics/common/presentation/graph_indicator/widgets/negative_graph_indicator.dart';
import 'package:metrics/common/presentation/graph_indicator/widgets/neutral_graph_indicator.dart';
import 'package:metrics/common/presentation/graph_indicator/widgets/positive_graph_indicator.dart';
import 'package:metrics/common/presentation/metrics_theme/config/dimensions_config.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_widget_theme_data.dart';
import 'package:metrics/dashboard/presentation/view_models/build_result_popup_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/build_result_view_model.dart';
import 'package:metrics/dashboard/presentation/widgets/build_result_bar.dart';
import 'package:metrics/dashboard/presentation/widgets/build_result_popup_card.dart';
import 'package:metrics/dashboard/presentation/widgets/strategy/build_result_bar_appearance_strategy.dart';
import 'package:metrics/dashboard/presentation/widgets/strategy/build_result_bar_padding_strategy.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("BuildResultBar", () {
    const metricsTheme = MetricsThemeData(
      inactiveWidgetTheme: MetricsWidgetThemeData(
        primaryColor: Colors.red,
      ),
    );
    final successfulBuildResult = BuildResultViewModel(
      buildResultPopupViewModel: BuildResultPopupViewModel(
        date: DateTime.now(),
        duration: Duration.zero,
        buildStatus: BuildStatus.successful,
      ),
      date: DateTime.now(),
      duration: const Duration(seconds: 20),
      buildStatus: BuildStatus.successful,
      url: 'url',
    );
    final placeholderFinder = find.byType(PlaceholderBar);
    final mouseRegionFinder = find.ancestor(
      of: find.byType(GestureDetector),
      matching: find.byType(MouseRegion),
    );

    Future<void> _hoverBar(WidgetTester tester) async {
      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
      mouseRegion.onEnter(const PointerEnterEvent());
      await mockNetworkImagesFor(() {
        return tester.pumpAndSettle();
      });
    }

    final urlLauncherMock = _UrlLauncherMock();
    UrlLauncherPlatform.instance = urlLauncherMock;

    tearDown(() {
      reset(urlLauncherMock);
    });

    testWidgets(
      "displays the PlaceholderBar if the given build result is null",
      (tester) async {
        await tester.pumpWidget(const _BuildResultBarTestbed(
          buildResult: null,
        ));

        expect(placeholderFinder, findsOneWidget);
      },
    );

    testWidgets(
      "applies the bar color from the inactive widget theme to the PlaceholderBar",
      (WidgetTester tester) async {
        final expectedColor = metricsTheme.inactiveWidgetTheme.primaryColor;

        await tester.pumpWidget(const _BuildResultBarTestbed(
          buildResult: null,
          themeData: metricsTheme,
        ));

        final placeholderBar = tester.widget<PlaceholderBar>(placeholderFinder);

        expect(placeholderBar.color, expectedColor);
      },
    );

    testWidgets(
      "applies the bar width from the dimension config to the PlaceholderBar",
      (WidgetTester tester) async {
        const expectedWidth = DimensionsConfig.graphBarWidth;

        await tester.pumpWidget(const _BuildResultBarTestbed(
          buildResult: null,
        ));

        final placeholderBar = tester.widget<PlaceholderBar>(placeholderFinder);

        expect(placeholderBar.width, expectedWidth);
      },
    );

    testWidgets(
      "opens the BuildResultPopupCard widget on hover",
      (WidgetTester tester) async {
        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: successfulBuildResult,
        ));

        await _hoverBar(tester);

        expect(find.byType(BuildResultPopupCard), findsOneWidget);
      },
    );

    testWidgets(
      "closes the BuildResultPopupCard widget on exit",
      (WidgetTester tester) async {
        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: successfulBuildResult,
        ));

        await _hoverBar(tester);
        final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
        mouseRegion.onExit(const PointerExitEvent());
        await tester.pumpAndSettle();

        expect(find.byType(BuildResultPopupCard), findsNothing);
      },
    );

    testWidgets(
      "does not displays the graph indicator if the popup is closed",
      (tester) async {
        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: successfulBuildResult,
        ));

        final graphIndicatorFinder = find.byWidgetPredicate(
          (widget) => widget is GraphIndicator,
        );

        expect(graphIndicatorFinder, findsNothing);
      },
    );

    testWidgets(
      "displays the positive graph indicator if the build status is successful and the popup is opened",
      (tester) async {
        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: successfulBuildResult,
        ));

        await _hoverBar(tester);

        final graphIndicatorFinder = find.byType(PositiveGraphIndicator);

        expect(graphIndicatorFinder, findsOneWidget);
      },
    );

    testWidgets(
      "displays the negative graph indicator if the build status is failed and the popup is opened",
      (tester) async {
        final buildResult = BuildResultViewModel(
          buildResultPopupViewModel: BuildResultPopupViewModel(
            date: DateTime.now(),
            duration: Duration.zero,
            buildStatus: BuildStatus.failed,
          ),
          date: DateTime.now(),
          duration: Duration.zero,
          buildStatus: BuildStatus.failed,
        );

        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: buildResult,
        ));

        await _hoverBar(tester);

        final graphIndicatorFinder = find.byType(NegativeGraphIndicator);

        expect(graphIndicatorFinder, findsOneWidget);
      },
    );

    testWidgets(
      "displays the neutral graph indicator if the build status is unknown and the popup is opened",
      (tester) async {
        final buildResult = BuildResultViewModel(
          buildResultPopupViewModel: BuildResultPopupViewModel(
            date: DateTime.now(),
            duration: Duration.zero,
            buildStatus: BuildStatus.unknown,
          ),
          date: DateTime.now(),
          duration: Duration.zero,
          buildStatus: BuildStatus.unknown,
        );

        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: buildResult,
        ));

        await _hoverBar(tester);

        final graphIndicatorFinder = find.byType(NeutralGraphIndicator);

        expect(graphIndicatorFinder, findsOneWidget);
      },
    );

    testWidgets(
      "applies the padding returned from the given build result bar strategy",
      (tester) async {
        final strategy = BuildResultBarPaddingStrategy(
          buildResults: [successfulBuildResult],
        );
        final expectedPadding = strategy.getBarPadding(successfulBuildResult);

        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: successfulBuildResult,
          strategy: strategy,
        ));

        final paddingWidget = tester.widget<Padding>(find.byWidgetPredicate(
          (widget) => widget is Padding && widget.child is Stack,
        ));

        expect(paddingWidget.padding, equals(expectedPadding));
      },
    );

    testWidgets(
      "opens the build result url on tap if the url can be launched",
      (tester) async {
        await tester.pumpWidget(
          _BuildResultBarTestbed(
            buildResult: successfulBuildResult,
          ),
        );
        final url = successfulBuildResult.url;

        when(urlLauncherMock.canLaunch(url)).thenAnswer(
          (_) => Future.value(true),
        );
        await tester.tap(find.byType(BuildResultBar));

        verify(urlLauncherMock.launch(
          url,
          useSafariVC: anyNamed('useSafariVC'),
          useWebView: anyNamed('useWebView'),
          enableJavaScript: anyNamed('enableJavaScript'),
          enableDomStorage: anyNamed('enableDomStorage'),
          universalLinksOnly: anyNamed('universalLinksOnly'),
          headers: anyNamed('headers'),
        )).called(once);
      },
    );

    testWidgets(
      "does not open the build result url on tap if the url can't be launched",
      (tester) async {
        await tester.pumpWidget(
          _BuildResultBarTestbed(
            buildResult: successfulBuildResult,
          ),
        );
        final url = successfulBuildResult.url;

        when(urlLauncherMock.canLaunch(url)).thenAnswer(
          (_) => Future.value(false),
        );
        await tester.tap(find.byType(BuildResultBar));

        verifyNever(urlLauncherMock.launch(
          url,
          useSafariVC: anyNamed('useSafariVC'),
          useWebView: anyNamed('useWebView'),
          enableJavaScript: anyNamed('enableJavaScript'),
          enableDomStorage: anyNamed('enableDomStorage'),
          universalLinksOnly: anyNamed('universalLinksOnly'),
          headers: anyNamed('headers'),
        ));
      },
    );

    testWidgets(
      "displays the MetricsColoredBar with the BuildResultBarAppearanceStrategy",
      (tester) async {
        await tester.pumpWidget(_BuildResultBarTestbed(
          buildResult: successfulBuildResult,
        ));

        final bar = tester.widget<MetricsColoredBar>(find.byWidgetPredicate(
          (widget) => widget is MetricsColoredBar<BuildStatus>,
        ));

        expect(bar.strategy, isA<BuildResultBarAppearanceStrategy>());
      },
    );
  });
}

/// A testbed class required to test the [BuildResultBar].
class _BuildResultBarTestbed extends StatelessWidget {
  /// A [BuildResultViewModel] to display.
  final BuildResultViewModel buildResult;

  /// A [MetricsThemeData] used in tests.
  final MetricsThemeData themeData;

  /// A height of the [BuildResultBar].
  final double barHeight;

  /// A class that provides an [EdgeInsets] based
  /// on the [BuildResultViewModel].
  final BuildResultBarPaddingStrategy strategy;

  /// Creates an instance of this testbed.
  ///
  /// The [themeData] default value is an empty [MetricsThemeData] instance.
  /// The [strategy] default value is an empty
  /// [BuildResultBarPaddingStrategy] instance.
  /// The [barHeight] default value is `20.0`.
  const _BuildResultBarTestbed({
    Key key,
    this.themeData = const MetricsThemeData(),
    this.strategy = const BuildResultBarPaddingStrategy(),
    this.barHeight = 20.0,
    this.buildResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetricsThemedTestbed(
      metricsThemeData: themeData,
      body: BuildResultBar(
        strategy: strategy,
        buildResult: buildResult,
      ),
    );
  }
}

class _UrlLauncherMock extends Mock
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {}
