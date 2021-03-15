// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/analytics/presentation/state/analytics_notifier.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/common/domain/entities/metrics_config.dart';
import 'package:metrics/common/presentation/injector/widget/injection_container.dart';
import 'package:metrics/common/presentation/metrics_theme/state/theme_notifier.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:metrics/common/presentation/state/projects_notifier.dart';
import 'package:metrics/dashboard/presentation/state/project_metrics_notifier.dart';
import 'package:metrics/debug_menu/presentation/state/debug_menu_notifier.dart';
import 'package:metrics/feature_config/presentation/state/feature_config_notifier.dart';
import 'package:metrics/project_groups/presentation/state/project_groups_notifier.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../../../test_utils/matchers.dart';
import '../../../../test_utils/metrics_config_stub.dart';

void main() {
  group("InjectionContainer", () {
    Future<void> changePage(WidgetTester tester) async {
      await tester.tap(find.byType(RaisedButton));
      await tester.pumpAndSettle();
    }

    testWidgets(
      "throws an AssertionError if the given metrics config is null",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed(
          metricsConfig: null,
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "creates a new instance with the given metrics config",
      (tester) async {
        const metricsConfig = MetricsConfigStub(sentryEnvironment: 'test');

        await tester.pumpWidget(const InjectionContainerTestbed(
          metricsConfig: metricsConfig,
        ));
        final finder = find.byType(InjectionContainer);
        final injectionContainer = tester.widget<InjectionContainer>(finder);

        expect(injectionContainer.metricsConfig, same(metricsConfig));
      },
    );

    testWidgets(
      "uses the metrics config google client id injecting notifiers",
      (tester) async {
        final configMock = _MetricsConfigMock();

        await tester.pumpWidget(InjectionContainerTestbed(
          metricsConfig: configMock,
        ));

        expect(tester.takeException(), isNull);
        verify(configMock.googleSignInClientId).called(once);
      },
    );

    testWidgets(
      "displays the given child",
      (tester) async {
        const child = Text('test');

        await tester.pumpWidget(const InjectionContainerTestbed(
          child: child,
        ));
        final finder = find.byWidget(child);

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "injects an AuthNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<AuthNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "injects a ThemeNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<ThemeNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "initializes and injects a ThemeNotifier with the theme that corresponds the operating system's theme",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final platformBrightness = tester.binding.window.platformBrightness;
        final isDark = platformBrightness == Brightness.dark;

        final themeNotifier =
            Provider.of<ThemeNotifier>(context, listen: false);

        expect(
          themeNotifier.isDark,
          equals(isDark),
        );
      },
    );

    testWidgets(
      "injects a ProjectsNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<ProjectsNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "injects a ProjectMetricsNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<ProjectMetricsNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "injects a ProjectGroupsNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<ProjectGroupsNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "injects an AnalyticsNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<AnalyticsNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "injects a FeatureConfigNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<FeatureConfigNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "injects a DebugMenuNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<DebugMenuNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "injects a NavigationNotifier",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        expect(
          () => Provider.of<NavigationNotifier>(context, listen: false),
          returnsNormally,
        );
      },
    );

    testWidgets(
      "disposes an AuthNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final authNotifier = Provider.of<AuthNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => authNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes a ThemeNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final themeNotifier = Provider.of<ThemeNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => themeNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes a ProjectsNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final projectsNotifier = Provider.of<ProjectsNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => projectsNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes a ProjectMetricsNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final projectMetricsNotifier = Provider.of<ProjectMetricsNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => projectMetricsNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes a ProjectGroupsNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final projectGroupsNotifier = Provider.of<ProjectGroupsNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => projectGroupsNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes an AnalyticsNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final analyticsNotifier = Provider.of<AnalyticsNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => analyticsNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes a FeatureConfigNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final featureConfigNotifier = Provider.of<FeatureConfigNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => featureConfigNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes a DebugMenuNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final debugMenuNotifier = Provider.of<DebugMenuNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => debugMenuNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );

    testWidgets(
      "disposes a NavigationNotifier on dispose",
      (tester) async {
        await tester.pumpWidget(const InjectionContainerTestbed());

        final context = InjectionContainerTestbed.childKey.currentContext;

        final navigationNotifier = Provider.of<NavigationNotifier>(
          context,
          listen: false,
        );

        await changePage(tester);

        expect(
          () => navigationNotifier.notifyListeners(),
          throwsFlutterError,
        );
      },
    );
  });
}

/// A testbed class needed to test the [InjectionContainer] widget.
class InjectionContainerTestbed extends StatelessWidget {
  /// A [GlobalKey] needed to get the current context of the [InjectionContainer.child].
  static final GlobalKey childKey = GlobalKey();

  /// A child [Widget] to display.
  final Widget child;

  /// A [MetricsConfig] instance to inject.
  final MetricsConfig metricsConfig;

  /// Creates a new instance of the [InjectionContainerTestbed].
  ///
  /// The [metricsConfig] defaults to the [MetricsConfigStub] instance.
  const InjectionContainerTestbed({
    Key key,
    this.child,
    this.metricsConfig = const MetricsConfigStub(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: InjectionContainer(
        metricsConfig: metricsConfig,
        child: child ??
            Builder(
              builder: (context) {
                return Container(
                  key: childKey,
                  child: RaisedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SizedBox()),
                      );
                    },
                  ),
                );
              },
            ),
      ),
    );
  }
}

class _MetricsConfigMock extends Mock implements MetricsConfig {}
