// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/dashboard/domain/entities/metrics/builds_on_date.dart';
import 'package:test/test.dart';

import '../../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  test(
    "Can't create the BuildsOnDate with the date that contains non-zero time",
    () {
      final invalidDates = [
        DateTime(2020, 1, 1, 1, 1, 1, 1, 1),
        DateTime(2020, 1, 1, 0, 0, 0, 0, 1),
        DateTime(2020, 1, 1, 0, 0, 0, 1, 0),
        DateTime(2020, 1, 1, 0, 0, 1, 0, 0),
        DateTime(2020, 1, 1, 0, 1, 0, 0, 0),
        DateTime(2020, 1, 1, 1, 0, 0, 0, 0),
      ];

      for (final invalidDate in invalidDates) {
        expect(
          () => BuildsOnDate(date: invalidDate),
          throwsAssertionError,
        );
      }
    },
  );

  test(
    'Creates the BuildsonDate with the date with zero time',
    () {
      final validDate = DateTime(2020, 1, 1);

      expect(BuildsOnDate(date: validDate), isA<BuildsOnDate>());
    },
  );
}
