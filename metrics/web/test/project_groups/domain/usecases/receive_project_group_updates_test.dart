// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/domain/usecases/receive_project_group_updates.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/project_group_repository_mock.dart';

void main() {
  group("ReceiveProjectGroupUpdates", () {
    test("throws an ArgumentError when the given repository is null", () {
      expect(() => ReceiveProjectGroupUpdates(null), throwsArgumentError);
    });

    test(
        ".call() delegates call to ProjectGroupRepository.projectGroupsStream()",
        () {
      final repository = ProjectGroupRepositoryMock();
      final receiveProjectGroupUpdates = ReceiveProjectGroupUpdates(repository);

      receiveProjectGroupUpdates();

      verify(repository.projectGroupsStream()).called(once);
    });
  });
}
