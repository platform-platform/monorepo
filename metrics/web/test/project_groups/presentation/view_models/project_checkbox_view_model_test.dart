// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/presentation/view_models/project_checkbox_view_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectCheckboxViewModel", () {
    const id = 'id';
    const name = 'name';
    const isChecked = false;

    test("successfully creates an instance on a valid input", () {
      expect(
        () => const ProjectCheckboxViewModel(
          id: id,
          name: name,
          isChecked: isChecked,
        ),
        returnsNormally,
      );
    });

    test("throws an AssertionError if the id parameter is null", () {
      expect(
        () => ProjectCheckboxViewModel(
          id: null,
          name: name,
          isChecked: isChecked,
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the name parameter is null", () {
      expect(
        () => ProjectCheckboxViewModel(
          id: id,
          name: null,
          isChecked: isChecked,
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the isChecked parameter is null", () {
      expect(
        () => ProjectCheckboxViewModel(
          id: id,
          name: name,
          isChecked: null,
        ),
        throwsAssertionError,
      );
    });

    test(
      "equals to another ProjectCheckboxViewModel with the same parameters",
      () {
        const expected = ProjectCheckboxViewModel(
          id: id,
          name: name,
          isChecked: isChecked,
        );

        const projectCheckboxViewModel = ProjectCheckboxViewModel(
          id: id,
          name: name,
          isChecked: isChecked,
        );

        expect(
          projectCheckboxViewModel,
          equals(expected),
        );
      },
    );
  });
}
