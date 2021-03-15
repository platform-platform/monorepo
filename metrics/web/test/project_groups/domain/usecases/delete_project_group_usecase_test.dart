// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/domain/usecases/delete_project_group_usecase.dart';
import 'package:metrics/project_groups/domain/usecases/parameters/delete_project_group_param.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/project_group_repository_mock.dart';

void main() {
  group("DeleteProjectGroupUseCase", () {
    test("successfully creates an instance on a valid input", () {
      final repository = ProjectGroupRepositoryMock();

      expect(
        () => DeleteProjectGroupUseCase(repository),
        returnsNormally,
      );
    });

    test("throws an ArgumentError when the given repository is null", () {
      expect(
        () => DeleteProjectGroupUseCase(null),
        throwsArgumentError,
      );
    });

    test(
      ".call() delegates deleting to the ProjectGroupRepository.deleteProjectGroup()",
      () async {
        final repository = ProjectGroupRepositoryMock();
        final deleteProjectGroupUseCase = DeleteProjectGroupUseCase(repository);
        final projectGroupParam = DeleteProjectGroupParam(projectGroupId: 'id');

        await deleteProjectGroupUseCase(projectGroupParam);

        verify(repository.deleteProjectGroup(
          projectGroupParam.projectGroupId,
        )).called(once);
      },
    );
  });
}
