// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/presentation/view_models/delete_project_group_dialog_view_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("DeleteProjectGroupDialogViewModel", () {
    const id = 'id';
    const name = 'name';

    test("successfully creates an instance on a valid input", () {
      expect(
        () => const DeleteProjectGroupDialogViewModel(id: id, name: name),
        returnsNormally,
      );
    });

    test("throws an AssertionError if the id parameter is null", () {
      expect(
        () => DeleteProjectGroupDialogViewModel(id: null, name: name),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the name parameter is null", () {
      expect(
        () => DeleteProjectGroupDialogViewModel(id: id, name: null),
        throwsAssertionError,
      );
    });
  });
}
