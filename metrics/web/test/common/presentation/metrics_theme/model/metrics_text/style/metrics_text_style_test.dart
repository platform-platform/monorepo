// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_text/style/metrics_text_style.dart';

import '../../../../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("MetricsTextStyle", () {
    const lineHeightInPixels = 26.0;
    const fontSize = 24.0;
    const height = 2.0;

    test(
      "throws an AssertionError if the line height in pixels, font size and height are provided simultaneously",
      () {
        expect(
          () => MetricsTextStyle(
            lineHeightInPixels: lineHeightInPixels,
            fontSize: fontSize,
            height: height,
          ),
          throwsAssertionError,
        );
      },
    );

    test("applies the default inherit if it's not specified", () {
      const textStyle = MetricsTextStyle();

      expect(textStyle.inherit, isNotNull);
    });

    test(
      "sets height equals to the line height in pixels divided by the font size if they are not null",
      () {
        const textStyle = MetricsTextStyle(
          lineHeightInPixels: lineHeightInPixels,
          fontSize: fontSize,
        );

        expect(textStyle.height, equals(lineHeightInPixels / fontSize));
      },
    );

    test(
      "applies the given height when the given line height in pixels is not null and the font size is null",
      () {
        const textStyle = MetricsTextStyle(
          lineHeightInPixels: lineHeightInPixels,
          fontSize: null,
          height: height,
        );

        expect(textStyle.height, equals(height));
      },
    );

    test(
      "applies the given height when the given line height in pixels is null and the font size is not null",
      () {
        const textStyle = MetricsTextStyle(
          lineHeightInPixels: null,
          height: height,
        );

        expect(textStyle.height, equals(height));
      },
    );
  });
}
