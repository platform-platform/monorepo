// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/common/domain/repositories/project_repository.dart';
import 'package:metrics/common/domain/usecases/receive_project_updates.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ReceiveProjectUpdates", () {
    test("throws an ArgumentError when the given repository is null", () {
      expect(
        () => ReceiveProjectUpdates(null),
        throwsArgumentError,
      );
    });

    test(".call() delegates call to ProjectRepository.projectsStream()", () {
      final repository = ProjectRepositoryMock();
      final receiveProjectUpdates = ReceiveProjectUpdates(repository);

      receiveProjectUpdates();

      verify(repository.projectsStream()).called(once);
    });
  });
}

class ProjectRepositoryMock extends Mock implements ProjectRepository {}
