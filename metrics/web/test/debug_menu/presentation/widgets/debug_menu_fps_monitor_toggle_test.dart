// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/common/presentation/metrics_theme/model/debug_menu/theme_data/debug_menu_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_text/style/metrics_text_style.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/toggle/widgets/toggle.dart';
import 'package:metrics/debug_menu/presentation/state/debug_menu_notifier.dart';
import 'package:metrics/debug_menu/presentation/strings/debug_menu_strings.dart';
import 'package:metrics/debug_menu/presentation/view_models/local_config_fps_monitor_view_model.dart';
import 'package:metrics/debug_menu/presentation/widgets/debug_menu_fps_monitor_toggle.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils/debug_menu_notifier_mock.dart';
import '../../../test_utils/matchers.dart' as matchers;
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/test_injection_container.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("DebugMenuFpsMonitorToggle", () {
    const contentTextStyle = MetricsTextStyle(lineHeightInPixels: 10);

    const metricsThemeData = MetricsThemeData(
      debugMenuTheme: DebugMenuThemeData(
        sectionContentTextStyle: contentTextStyle,
      ),
    );

    final toggleFinder = find.byType(Toggle);

    testWidgets(
      "throws an AssertionError if the given fps monitor view model is null",
      (WidgetTester tester) async {
        expect(
          () => DebugMenuFpsMonitorToggle(fpsMonitorViewModel: null),
          throwsAssertionError,
        );
      },
    );

    testWidgets(
      "displays the fps monitor text",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _DebugMenuFpsMonitorToggleTestbed(),
        );

        expect(find.text(DebugMenuStrings.fpsMonitor), findsOneWidget);
      },
    );

    testWidgets(
      "displays the toggle widget",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _DebugMenuFpsMonitorToggleTestbed(),
        );

        expect(toggleFinder, findsOneWidget);
      },
    );

    testWidgets(
      "applies the section content text style from the metrics theme",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _DebugMenuFpsMonitorToggleTestbed(
              metricsThemeData: metricsThemeData),
        );

        final content = tester.widget<Text>(
          find.text(DebugMenuStrings.fpsMonitor),
        );

        expect(content.style, equals(contentTextStyle));
      },
    );

    testWidgets(
      "displays the toggle widget with the false value if the fps monitor is disabled in debug menu notifier",
      (WidgetTester tester) async {
        const isFpsMonitorEnabled = false;
        const fpsMonitorViewModel = LocalConfigFpsMonitorViewModel(
          isEnabled: isFpsMonitorEnabled,
        );

        await tester.pumpWidget(
          const _DebugMenuFpsMonitorToggleTestbed(
            fpsMonitorViewModel: fpsMonitorViewModel,
          ),
        );

        final toggle = tester.widget<Toggle>(toggleFinder);

        expect(toggle.value, equals(isFpsMonitorEnabled));
      },
    );

    testWidgets(
      "displays the toggle widget with the true value if the fps monitor is enabled in debug menu notifier",
      (WidgetTester tester) async {
        const isFpsMonitorEnabled = true;
        const fpsMonitorViewModel = LocalConfigFpsMonitorViewModel(
          isEnabled: isFpsMonitorEnabled,
        );

        await tester.pumpWidget(
          const _DebugMenuFpsMonitorToggleTestbed(
            fpsMonitorViewModel: fpsMonitorViewModel,
          ),
        );

        final toggle = tester.widget<Toggle>(toggleFinder);

        expect(toggle.value, equals(isFpsMonitorEnabled));
      },
    );

    testWidgets(
      "calls the .toggleFpsMonitor() method of the debug menu notifier on tap",
      (WidgetTester tester) async {
        final debugMenuNotifier = DebugMenuNotifierMock();

        await tester.pumpWidget(
          _DebugMenuFpsMonitorToggleTestbed(
            debugMenuNotifier: debugMenuNotifier,
          ),
        );

        await tester.tap(toggleFinder);

        verify(debugMenuNotifier.toggleFpsMonitor()).called(matchers.once);
      },
    );
  });
}

/// A testbed class needed to test the [DebugMenuFpsMonitorToggle] widget.
class _DebugMenuFpsMonitorToggleTestbed extends StatelessWidget {
  /// A default [LocalConfigFpsMonitorViewModel] to use under tests.
  static const _defaultFpsMonitorViewModel = LocalConfigFpsMonitorViewModel(
    isEnabled: false,
  );

  /// A [DebugMenuNotifier] to use under tests.
  final DebugMenuNotifier debugMenuNotifier;

  /// A [MetricsThemeData] to use under tests.
  final MetricsThemeData metricsThemeData;

  /// A [LocalConfigFpsMonitorViewModel] to use in tests.
  final LocalConfigFpsMonitorViewModel fpsMonitorViewModel;

  /// Creates a new instance of this testbed with the given parameters.
  ///
  /// A [fpsMonitorViewModel] defaults to the [LocalConfigFpsMonitorViewModel]
  /// instance with `false` value.
  /// A [metricsThemeData] defaults to the [MetricsThemeData] instance.
  const _DebugMenuFpsMonitorToggleTestbed({
    Key key,
    this.debugMenuNotifier,
    this.fpsMonitorViewModel = _defaultFpsMonitorViewModel,
    this.metricsThemeData = const MetricsThemeData(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      debugMenuNotifier: debugMenuNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: metricsThemeData,
        body: DebugMenuFpsMonitorToggle(
          fpsMonitorViewModel: fpsMonitorViewModel,
        ),
      ),
    );
  }
}
