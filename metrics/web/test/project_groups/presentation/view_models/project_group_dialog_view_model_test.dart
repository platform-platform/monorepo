// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:metrics/project_groups/presentation/view_models/project_group_dialog_view_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectGroupDialogViewModel", () {
    const id = 'id';
    const name = 'name';
    final projectIds = UnmodifiableListView<String>([]);

    test("successfully creates an instance on a valid input", () {
      expect(
        () => ProjectGroupDialogViewModel(
          id: id,
          name: name,
          selectedProjectIds: projectIds,
        ),
        returnsNormally,
      );
    });

    test(
      "throws an AssertionError if the selected project ids parameter is null",
      () {
        expect(
          () => ProjectGroupDialogViewModel(
            id: id,
            name: name,
            selectedProjectIds: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "equals to another ProjectGroupDialogViewModel with the same parameters",
      () {
        final expected = ProjectGroupDialogViewModel(
          id: id,
          name: name,
          selectedProjectIds: projectIds,
        );

        final projectGroupDialogViewModel = ProjectGroupDialogViewModel(
          id: id,
          name: name,
          selectedProjectIds: projectIds,
        );

        expect(
          projectGroupDialogViewModel,
          equals(expected),
        );
      },
    );
  });
}
