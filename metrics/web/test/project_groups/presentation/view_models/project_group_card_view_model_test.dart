// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/presentation/view_models/project_group_card_view_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectGroupCardViewModel", () {
    const id = 'id';
    const name = 'name';
    const projectsCount = 0;

    test("successfully creates an instance on a valid input", () {
      expect(
        () => const ProjectGroupCardViewModel(
          id: id,
          name: name,
          projectsCount: projectsCount,
        ),
        returnsNormally,
      );
    });

    test("throws an AssertionError if the id parameter is null", () {
      expect(
        () => ProjectGroupCardViewModel(
          id: null,
          name: name,
          projectsCount: projectsCount,
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the name parameter is null", () {
      expect(
        () => ProjectGroupCardViewModel(
          id: id,
          name: null,
          projectsCount: projectsCount,
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the projects count parameter is null",
        () {
      expect(
        () => ProjectGroupCardViewModel(
          id: id,
          name: name,
          projectsCount: null,
        ),
        throwsAssertionError,
      );
    });

    test(
      "equals to another ProjectGroupCardViewModel with the same parameters",
      () {
        const expected = ProjectGroupCardViewModel(
          id: id,
          name: name,
          projectsCount: projectsCount,
        );

        const projectGroupCardViewModel = ProjectGroupCardViewModel(
          id: id,
          name: name,
          projectsCount: projectsCount,
        );

        expect(
          projectGroupCardViewModel,
          equals(expected),
        );
      },
    );
  });
}
