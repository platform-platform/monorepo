// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/dashboard/presentation/view_models/build_result_popup_view_model.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("BuildResultPopupViewModel", () {
    test("throws an AssertionError if the given duration is null", () {
      expect(
        () => BuildResultPopupViewModel(
          duration: null,
          date: DateTime.now(),
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the given date is null", () {
      expect(
        () => BuildResultPopupViewModel(
          date: null,
          duration: Duration.zero,
        ),
        throwsAssertionError,
      );
    });

    test(
      "equals to another BuildResultPopupViewModel with the same parameters",
      () {
        const duration = Duration.zero;
        const buildStatus = BuildStatus.unknown;
        final date = DateTime.now();

        final expected = BuildResultPopupViewModel(
          duration: duration,
          date: date,
          buildStatus: buildStatus,
        );

        final buildResult = BuildResultPopupViewModel(
          duration: duration,
          date: date,
          buildStatus: buildStatus,
        );

        expect(buildResult, equals(expected));
      },
    );
  });
}
