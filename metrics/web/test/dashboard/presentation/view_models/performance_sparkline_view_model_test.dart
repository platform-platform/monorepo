// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:metrics/dashboard/presentation/view_models/performance_sparkline_view_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("PerformanceSparklineViewModel", () {
    test("throws an AssertionError is the given performance is null", () {
      expect(
        () => PerformanceSparklineViewModel(
          performance: null,
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError is the given value is null", () {
      expect(
        () => PerformanceSparklineViewModel(
            value: null, performance: UnmodifiableListView([])),
        throwsAssertionError,
      );
    });

    test(
      ".performance is an UnmodifiableListView",
      () {
        final performanceSparklineViewModel = PerformanceSparklineViewModel(
          performance: UnmodifiableListView([]),
        );

        expect(
          performanceSparklineViewModel.performance,
          isA<UnmodifiableListView>(),
        );
      },
    );

    test(
      "equals to another PerformanceSparklineViewModel with the same parameters",
      () {
        const performance = <Point<int>>[];
        const value = Duration(minutes: 10);
        final expected = PerformanceSparklineViewModel(
          performance: UnmodifiableListView(performance),
          value: value,
        );

        final performanceMetric = PerformanceSparklineViewModel(
          performance: UnmodifiableListView(performance),
          value: value,
        );

        expect(performanceMetric, equals(expected));
      },
    );
  });
}
