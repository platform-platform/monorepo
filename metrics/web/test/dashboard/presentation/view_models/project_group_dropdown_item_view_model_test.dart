// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/dashboard/presentation/view_models/project_group_dropdown_item_view_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectGroupDropdownItemViewModel", () {
    const id = 'id';
    const name = 'name';

    test(
      "successfully creates an instance on a valid input",
      () {
        expect(
          () => const ProjectGroupDropdownItemViewModel(id: id, name: name),
          returnsNormally,
        );
      },
    );

    test(
      "throws an AssertionError if the given name is null",
      () {
        expect(
          () => ProjectGroupDropdownItemViewModel(id: id, name: null),
          throwsAssertionError,
        );
      },
    );

    test(
      "equals to another ProjectGroupDropdownItemViewModel instance with the same value",
      () {
        const firstViewModel = ProjectGroupDropdownItemViewModel(
          id: id,
          name: name,
        );

        const secondViewModel = ProjectGroupDropdownItemViewModel(
          id: id,
          name: name,
        );

        expect(firstViewModel, equals(secondViewModel));
      },
    );
  });
}
