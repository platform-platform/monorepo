// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/domain/usecases/parameters/update_project_group_param.dart';
import 'package:metrics/project_groups/domain/usecases/update_project_group_usecase.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/project_group_repository_mock.dart';

void main() {
  group("UpdateProjectGroupUseCase", () {
    test("throws an ArgumentError when the given repository is null", () {
      expect(
        () => UpdateProjectGroupUseCase(null),
        throwsArgumentError,
      );
    });

    test(
      ".call() delegates call to the ProjectGroupRepository.updateProjectGroup()",
      () async {
        final repository = ProjectGroupRepositoryMock();
        final updateProjectGroupUseCase = UpdateProjectGroupUseCase(repository);
        final projectGroupParam = UpdateProjectGroupParam(
          'id',
          'name',
          const [],
        );

        await updateProjectGroupUseCase(projectGroupParam);

        verify(repository.updateProjectGroup(
          projectGroupParam.projectGroupId,
          projectGroupParam.projectGroupName,
          projectGroupParam.projectIds,
        )).called(once);
      },
    );
  });
}
