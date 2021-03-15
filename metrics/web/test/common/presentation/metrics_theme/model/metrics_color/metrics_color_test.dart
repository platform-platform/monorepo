// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:test/test.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_color/metrics_color.dart';

import '../../../../../test_utils/matchers.dart';

void main() {
  group("MetricsColor", () {
    const primary = 0xFF000000;
    const existingShade = 100;
    const swatch = <int, Color>{
      existingShade: Color(primary),
    };

    const color = MetricsColor(primary, swatch);

    test(
      "creates an instance with the given primary value",
      () {
        const color = MetricsColor(primary, swatch);

        expect(color.value, equals(primary));
      },
    );

    test(
      "creates an instance with shades from the given swatch",
      () {
        const swatch = {
          100: Colors.white,
          200: Colors.black,
        };

        const color = MetricsColor(primary, swatch);
        final metricsColorMatcher = predicate<MetricsColor>(
          (color) => color[100] == swatch[100] && color[200] == swatch[200],
        );

        expect(color, metricsColorMatcher);
      },
    );

    test(
      "operator [] throws an AssertionError if the given shade does not exist",
      () {
        const nonExistingShade = -1000;

        expect(() => color[nonExistingShade], throwsAssertionError);
      },
    );

    test(
      "operator [] returns the corresponding color from the swatch",
      () {
        final expectedColor = swatch[existingShade];

        final actualColor = color[existingShade];

        expect(actualColor, equals(expectedColor));
      },
    );
  });
}
