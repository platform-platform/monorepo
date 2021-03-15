// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/navigation/metrics_page/metrics_page.dart';
import 'package:metrics/common/presentation/navigation/metrics_page/metrics_page_route.dart';
import 'package:test/test.dart';

import '../../../../test_utils/matchers.dart';

void main() {
  group("MetricsPage", () {
    const child = Text('child');

    test(
      "throws an AssertionError if the given child is null",
      () {
        expect(
          () => MetricsPage(child: null),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given maintain state is null",
      () {
        expect(
          () => MetricsPage(child: child, maintainState: null),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given fullscreen dialog is null",
      () {
        expect(
          () => MetricsPage(child: child, fullscreenDialog: null),
          throwsAssertionError,
        );
      },
    );

    test(
      "uses the default maintain state value if the given parameter is not specified",
      () {
        const metricsPage = MetricsPage(child: child);

        expect(metricsPage.maintainState, isNotNull);
      },
    );

    test(
      "uses the default fullscreen dialog value if the given parameter is not specified",
      () {
        const metricsPage = MetricsPage(child: child);

        expect(metricsPage.fullscreenDialog, isNotNull);
      },
    );

    test(
      ".createRoute() returns a metrics page with the given route name",
      () {
        const expectedName = 'test';
        const metricsPage = MetricsPage(child: child, name: expectedName);
        final actualRoute = metricsPage.createRoute(null);

        expect(actualRoute.settings.name, equals(expectedName));
      },
    );

    test(
      ".createRoute() returns a metrics page with the given route arguments",
      () {
        const arguments = 'test arguments';
        const metricsPage = MetricsPage(child: child, arguments: arguments);
        final actualRoute = metricsPage.createRoute(null);

        expect(actualRoute.settings.arguments, arguments);
      },
    );

    test(
      ".createRoute() returns the metrics page route that builds the given child widget",
      () {
        const metricsPage = MetricsPage(child: child);
        final actualRoute = metricsPage.createRoute(null) as MetricsPageRoute;
        final actualChild = actualRoute.builder(null);

        expect(actualChild, equals(child));
      },
    );
  });
}
