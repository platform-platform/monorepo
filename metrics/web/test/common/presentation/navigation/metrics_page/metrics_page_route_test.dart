// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/metrics_page/metrics_page_route.dart';
import 'package:test/test.dart';

import '../../../../test_utils/matchers.dart';

void main() {
  group("MetricsPageRoute", () {
    test(
      "throws an AssertionError if the builder is null",
      () {
        expect(
          () => MetricsPageRoute(
            builder: null,
            settings: RouteSettings(name: MetricsRoutes.login.path),
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the maintain state is null",
      () {
        expect(
          () => MetricsPageRoute(
            builder: (_) => Container(),
            settings: RouteSettings(name: MetricsRoutes.login.path),
            maintainState: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the fullscreen dialog is null",
      () {
        expect(
          () => MetricsPageRoute(
            builder: (_) => Container(),
            settings: RouteSettings(name: MetricsRoutes.login.path),
            fullscreenDialog: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      ".buildTransitions() returns given child widget",
      () {
        const expectedChild = Text("Child");
        final route = MetricsPageRoute(
          builder: (_) => expectedChild,
        );
        final child = route.buildTransitions(null, null, null, expectedChild);
        expect(child, equals(expectedChild));
      },
    );
  });
}
