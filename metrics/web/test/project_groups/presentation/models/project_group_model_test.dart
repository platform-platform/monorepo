// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:metrics/project_groups/presentation/models/project_group_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectGroupModel", () {
    final UnmodifiableListView<String> projectIds = UnmodifiableListView([]);
    const name = 'name';

    test("throws an AssertionError if the given name is null", () {
      expect(
        () => ProjectGroupModel(name: null, projectIds: projectIds),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the given project ids is null", () {
      expect(
        () => ProjectGroupModel(name: name, projectIds: null),
        throwsAssertionError,
      );
    });

    test("creates an instance with the given parameters", () {
      const id = "id";

      final projectGroupModel = ProjectGroupModel(
        id: id,
        name: name,
        projectIds: projectIds,
      );

      expect(projectGroupModel.id, equals(id));
      expect(projectGroupModel.name, equals(name));
      expect(projectGroupModel.projectIds, equals(projectIds));
    });
  });
}
