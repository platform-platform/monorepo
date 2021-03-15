// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics_core/metrics_core.dart';
import 'package:test/test.dart';

import '../../test_utils/matchers.dart';

void main() {
  group("Project", () {
    test(
      "throws an AssertionError if the given id is null",
      () {
        const projectName = 'name';

        expect(
          () => Project(name: projectName, id: null),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given name is null",
      () {
        const projectId = 'projectId';

        expect(
          () => Project(name: null, id: projectId),
          throwsAssertionError,
        );
      },
    );
  });
}
