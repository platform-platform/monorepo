// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/domain/usecases/add_project_group_usecase.dart';
import 'package:metrics/project_groups/domain/usecases/parameters/add_project_group_param.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/project_group_repository_mock.dart';

void main() {
  group("AddProjectGroupUseCase", () {
    test("successfully creates an instance on a valid input", () {
      final repository = ProjectGroupRepositoryMock();

      expect(
        () => AddProjectGroupUseCase(repository),
        returnsNormally,
      );
    });

    test("throws an ArgumentError when the given repository is null", () {
      expect(
        () => AddProjectGroupUseCase(null),
        throwsArgumentError,
      );
    });

    test(
      ".call() delegates adding to the ProjectGroupRepository.addProjectGroup()",
      () async {
        final repository = ProjectGroupRepositoryMock();
        final addProjectGroupUseCase = AddProjectGroupUseCase(repository);
        final projectGroupParam = AddProjectGroupParam(
          projectGroupName: 'name',
          projectIds: const [],
        );

        await addProjectGroupUseCase(projectGroupParam);

        verify(repository.addProjectGroup(
          projectGroupParam.projectGroupName,
          projectGroupParam.projectIds,
        )).called(once);
      },
    );
  });
}
