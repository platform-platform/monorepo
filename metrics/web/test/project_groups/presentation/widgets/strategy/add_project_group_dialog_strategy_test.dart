// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/project_groups/presentation/strings/project_groups_strings.dart';
import 'package:metrics/project_groups/presentation/widgets/strategy/add_project_group_dialog_strategy.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/matchers.dart';
import '../../../../test_utils/project_groups_notifier_mock.dart';

void main() {
  group("AddProjectGroupDialogStrategy", () {
    final strategy = AddProjectGroupDialogStrategy();

    test(
      ".loadingText equals to the ProjectGroupsStrings.creatingGroup",
      () {
        expect(
          strategy.loadingText,
          equals(ProjectGroupsStrings.creatingProjectGroup),
        );
      },
    );

    test(".text equals to the ProjectGroupString.createGroup", () {
      expect(
        strategy.text,
        equals(ProjectGroupsStrings.createGroup),
      );
    });

    test(".title equals to the ProjectGroupString.createGroup", () {
      expect(
        strategy.title,
        equals(ProjectGroupsStrings.createGroup),
      );
    });

    test(
      ".getSuccessfulActionMessage() returns a created project group message with the given project group name",
      () {
        const name = 'project group name';
        final expectedMessage =
            ProjectGroupsStrings.getCreatedProjectGroupMessage(name);
        final actualMessage = strategy.getSuccessfulActionMessage(name);

        expect(actualMessage, equals(expectedMessage));
      },
    );

    test(
      ".action() delegates adding a new project group to the given notifier",
      () {
        const id = 'groupId';
        const name = 'groupName';
        const projectIds = <String>[];
        final notifier = ProjectGroupsNotifierMock();

        strategy.action(notifier, id, name, projectIds);

        verify(
          notifier.addProjectGroup(name, projectIds),
        ).called(once);
      },
    );
  });
}
