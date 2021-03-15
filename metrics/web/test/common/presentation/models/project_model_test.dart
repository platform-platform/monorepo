// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/common/presentation/models/project_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectModel", () {
    const id = 'id';
    const name = 'name';

    test("throws an AssertionError if the given id is null", () {
      expect(
        () => ProjectModel(id: null, name: name),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the given name is null", () {
      expect(
        () => ProjectModel(id: id, name: null),
        throwsAssertionError,
      );
    });

    test("successfully creates an instance on a valid input", () {
      expect(() => const ProjectModel(id: id, name: name), returnsNormally);
    });
  });
}
