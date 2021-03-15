// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/dashboard/presentation/view_models/build_result_popup_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/build_result_view_model.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("BuildResultViewModel", () {
    final buildResultPopupViewModel = BuildResultPopupViewModel(
      duration: Duration.zero,
      date: DateTime.now(),
    );

    test("throws an AssertionError if the given duration is null", () {
      expect(
        () => BuildResultViewModel(
          duration: null,
          date: DateTime.now(),
          buildResultPopupViewModel: buildResultPopupViewModel,
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the given date is null", () {
      expect(
        () => BuildResultViewModel(
          date: null,
          duration: Duration.zero,
          buildResultPopupViewModel: buildResultPopupViewModel,
        ),
        throwsAssertionError,
      );
    });

    test(
      "throws an AssertionError if the given build result popup view model is null",
      () {
        expect(
          () => BuildResultViewModel(
            date: DateTime.now(),
            duration: Duration.zero,
            buildResultPopupViewModel: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "equals to another BuildResultViewModel with the same parameters",
      () {
        const duration = Duration.zero;
        const buildStatus = BuildStatus.unknown;
        const url = 'url';
        final date = DateTime.now();

        final expected = BuildResultViewModel(
          duration: duration,
          date: date,
          buildStatus: buildStatus,
          url: url,
          buildResultPopupViewModel: buildResultPopupViewModel,
        );

        final buildResult = BuildResultViewModel(
          duration: duration,
          date: date,
          buildStatus: buildStatus,
          url: url,
          buildResultPopupViewModel: buildResultPopupViewModel,
        );

        expect(buildResult, equals(expected));
      },
    );
  });
}
