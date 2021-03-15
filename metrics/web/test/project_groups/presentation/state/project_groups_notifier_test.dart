// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:metrics/common/domain/entities/persistent_store_error_code.dart';
import 'package:metrics/common/domain/entities/persistent_store_exception.dart';
import 'package:metrics/common/presentation/models/persistent_store_error_message.dart';
import 'package:metrics/common/presentation/models/project_model.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/project_groups/domain/entities/project_group.dart';
import 'package:metrics/project_groups/domain/usecases/add_project_group_usecase.dart';
import 'package:metrics/project_groups/domain/usecases/delete_project_group_usecase.dart';
import 'package:metrics/project_groups/domain/usecases/parameters/add_project_group_param.dart';
import 'package:metrics/project_groups/domain/usecases/parameters/delete_project_group_param.dart';
import 'package:metrics/project_groups/domain/usecases/parameters/update_project_group_param.dart';
import 'package:metrics/project_groups/domain/usecases/receive_project_group_updates.dart';
import 'package:metrics/project_groups/domain/usecases/update_project_group_usecase.dart';
import 'package:metrics/project_groups/presentation/state/project_groups_notifier.dart';
import 'package:metrics/project_groups/presentation/view_models/project_checkbox_view_model.dart';
import 'package:metrics/project_groups/presentation/view_models/project_group_card_view_model.dart';
import 'package:metrics/project_groups/presentation/view_models/project_group_dialog_view_model.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ProjectGroupsNotifier", () {
    const projectGroupId = 'projectGroupId';
    const projectGroupName = 'projectGroupName';

    final projectGroup = ProjectGroup(
      id: projectGroupId,
      name: projectGroupName,
      projectIds: List.from([]),
    );

    const project = ProjectModel(id: 'projectId', name: 'projectName');

    const projects = [
      project,
      ProjectModel(id: '1', name: 'name1'),
      ProjectModel(id: '2', name: 'name2'),
    ];

    final projectGroups = [
      projectGroup,
      ProjectGroup(id: '1', name: 'name1', projectIds: List.from(['1', '2'])),
      ProjectGroup(id: '2', name: 'name2', projectIds: List.from(['1'])),
    ];

    final addProjectGroupUseCase = AddProjectGroupUseCaseMock();
    final updateProjectGroupUseCase = UpdateProjectGroupUseCaseMock();
    final deleteProjectGroupUseCase = DeleteProjectGroupUseCaseMock();
    final receiveProjectGroupUpdates = ReceiveProjectGroupUpdatesMock();

    ProjectGroupsNotifier projectGroupsNotifier;

    /// Sets up a new instance of the [ProjectGroupsNotifier] with the mock use cases.
    ///
    /// Mocks the use [ReceiveProjectGroupUpdates] to return the given [projectGroupsStream].
    /// If the given [projectGroupsStream] is null, the stream with [projectGroups] used.
    ///
    /// Sets the given [projects] to [ProjectGroupsNotifier].
    /// If the [projects] parameter is not specified, the default projects used.
    void setUpProjectGroupsNotifier({
      Stream<List<ProjectGroup>> projectGroupsStream,
      List<ProjectModel> projects = projects,
    }) {
      reset(receiveProjectGroupUpdates);
      reset(addProjectGroupUseCase);
      reset(updateProjectGroupUseCase);
      reset(deleteProjectGroupUseCase);

      projectGroupsNotifier = ProjectGroupsNotifier(
        receiveProjectGroupUpdates,
        addProjectGroupUseCase,
        updateProjectGroupUseCase,
        deleteProjectGroupUseCase,
      );

      when(receiveProjectGroupUpdates()).thenAnswer(
        (_) => projectGroupsStream ?? Stream.value(projectGroups),
      );

      projectGroupsNotifier.subscribeToProjectGroups();
      projectGroupsNotifier.setProjects(projects);
    }

    setUp(() {
      setUpProjectGroupsNotifier();
    });

    tearDown(() {
      projectGroupsNotifier.dispose();
    });

    test(
      "throws an AssertionError if the given receive project group updates use case is null",
      () {
        expect(
          () => ProjectGroupsNotifier(
            null,
            addProjectGroupUseCase,
            updateProjectGroupUseCase,
            deleteProjectGroupUseCase,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given add project group use case is null",
      () {
        expect(
          () => ProjectGroupsNotifier(
            receiveProjectGroupUpdates,
            null,
            updateProjectGroupUseCase,
            deleteProjectGroupUseCase,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given update project group use case is null",
      () {
        expect(
          () => ProjectGroupsNotifier(
            receiveProjectGroupUpdates,
            addProjectGroupUseCase,
            null,
            deleteProjectGroupUseCase,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given delete project group use case is null",
      () {
        expect(
          () => ProjectGroupsNotifier(
            receiveProjectGroupUpdates,
            addProjectGroupUseCase,
            updateProjectGroupUseCase,
            null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      ".filterByProjectName() filters a list of project checkbox view models",
      () {
        const filter = '2';

        projectGroupsNotifier.setProjects(projects);

        final expectedModels = projectGroupsNotifier.projectCheckboxViewModels
            .where((element) => element.name.contains(filter))
            .toList();

        projectGroupsNotifier.filterByProjectName(filter);

        final listener = expectAsyncUntil0(
          () {},
          () => listEquals(
              projectGroupsNotifier.projectCheckboxViewModels, expectedModels),
        );

        projectGroupsNotifier.addListener(listener);
      },
    );

    test(
      ".initDeleteProjectGroupDialogViewModel() sets the delete project group view model with the given project group id",
      () async {
        projectGroupsNotifier.initDeleteProjectGroupDialogViewModel(
          projectGroup.id,
        );

        expect(
          projectGroupsNotifier.deleteProjectGroupDialogViewModel.id,
          equals(projectGroup.id),
        );
      },
    );

    test(
      ".initDeleteProjectGroupDialogViewModel() does not create a view model if the given project group id is null",
      () {
        final initialDeleteDialogViewModel =
            projectGroupsNotifier.deleteProjectGroupDialogViewModel;

        projectGroupsNotifier.initDeleteProjectGroupDialogViewModel(null);

        expect(
          projectGroupsNotifier.deleteProjectGroupDialogViewModel,
          equals(initialDeleteDialogViewModel),
        );
      },
    );

    test(
      ".initDeleteProjectGroupDialogViewModel() does not create a view model if the project groups do not contain a group with the given id",
      () {
        final initialDeleteDialogViewModel =
            projectGroupsNotifier.deleteProjectGroupDialogViewModel;

        projectGroupsNotifier
            .initDeleteProjectGroupDialogViewModel('invalid_id');

        expect(
          projectGroupsNotifier.deleteProjectGroupDialogViewModel,
          equals(initialDeleteDialogViewModel),
        );
      },
    );

    test(
      ".resetDeleteProjectGroupDialogViewModel() sets the delete project group view model to null",
      () {
        projectGroupsNotifier.initDeleteProjectGroupDialogViewModel(
          projectGroup.id,
        );

        expect(
          projectGroupsNotifier.deleteProjectGroupDialogViewModel,
          isNotNull,
        );

        projectGroupsNotifier.resetDeleteProjectGroupDialogViewModel();

        expect(
          projectGroupsNotifier.deleteProjectGroupDialogViewModel,
          isNull,
        );
      },
    );

    test(
      ".initProjectGroupDialogViewModel() sets the projectGroupDialogViewModel using the given project group id",
      () {
        projectGroupsNotifier.initProjectGroupDialogViewModel(projectGroup.id);

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel.id,
          equals(projectGroup.id),
        );
      },
    );

    test(
      ".initProjectGroupDialogViewModel() sets an empty projectGroupDialogViewModel if there is no project group with the given id",
      () {
        final expectedViewModel = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView([]),
        );

        projectGroupsNotifier.initProjectGroupDialogViewModel(null);

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel,
          equals(expectedViewModel),
        );
      },
    );

    test(
      ".hasConfiguredProjects is true when there are configured projects",
      () {
        projectGroupsNotifier.setProjects(projects);

        expect(projectGroupsNotifier.hasConfiguredProjects, isTrue);
      },
    );

    test(
      ".hasConfiguredProjects is false when there are no configured projects",
      () {
        const emptyProjectList = <ProjectModel>[];
        projectGroupsNotifier.setProjects(emptyProjectList);

        expect(projectGroupsNotifier.hasConfiguredProjects, isFalse);
      },
    );

    test(
      ".initProjectGroupDialogViewModel() sets an empty projectGroupDialogViewModel if there is no project group with the given id",
      () {
        final expectedViewModel = ProjectGroupDialogViewModel(
          selectedProjectIds: UnmodifiableListView([]),
        );

        projectGroupsNotifier.initProjectGroupDialogViewModel('invalid_id');

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel,
          equals(expectedViewModel),
        );
      },
    );

    test(
      ".projectGroupDialogViewModel can't contain a project id if there is no project with such id",
      () async {
        const invalidGroupId = '1';
        final invalidProjectGroup = ProjectGroup(
          id: invalidGroupId,
          name: 'name1',
          projectIds: List.from(['id1', 'id2']),
        );

        final projectGroups = [
          invalidProjectGroup,
          ProjectGroup(
            id: '2',
            name: 'name2',
            projectIds: List.from(['id1']),
          ),
        ];

        const projects = [
          ProjectModel(id: 'id1', name: 'name1'),
        ];

        final availableProjectIds = projects.map((project) => project.id);

        setUpProjectGroupsNotifier(
          projectGroupsStream: Stream.value(projectGroups),
          projects: projects,
        );

        final listener = expectAsyncUntil0(() {
          final projectGroupCardViewModels =
              projectGroupsNotifier.projectGroupCardViewModels;

          if (projectGroupCardViewModels == null ||
              projectGroupCardViewModels.isEmpty) {
            return;
          }

          if (projectGroupsNotifier.projectGroupDialogViewModel == null) {
            projectGroupsNotifier
                .initProjectGroupDialogViewModel(invalidGroupId);
          }
        }, () {
          final projectGroupDialogViewModel =
              projectGroupsNotifier.projectGroupDialogViewModel;

          if (projectGroupDialogViewModel == null) return false;

          return projectGroupDialogViewModel.selectedProjectIds
              .every((id) => availableProjectIds.contains(id));
        });

        projectGroupsNotifier.addListener(listener);
      },
    );

    test(
      ".resetProjectGroupDialogViewModel() sets the project group dialog view model to null",
      () {
        projectGroupsNotifier.initProjectGroupDialogViewModel(projectGroup.id);

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel,
          isNotNull,
        );

        projectGroupsNotifier.resetProjectGroupDialogViewModel();

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel,
          isNull,
        );
      },
    );

    test(
      ".toggleProjectCheckedStatus() changes a checked status of the project checkbox view model",
      () {
        projectGroupsNotifier.initProjectGroupDialogViewModel(projectGroup.id);

        projectGroupsNotifier.toggleProjectCheckedStatus(
          project.id,
        );

        final projectCheckboxViewModel = projectGroupsNotifier
            .projectCheckboxViewModels
            .firstWhere((viewModel) => viewModel.id == project.id);

        expect(projectCheckboxViewModel.isChecked, isTrue);
      },
    );

    test(
      ".toggleProjectCheckedStatus() changes the project group dialog view model",
      () {
        projectGroupsNotifier.initProjectGroupDialogViewModel(projectGroup.id);

        final initialViewModel =
            projectGroupsNotifier.projectGroupDialogViewModel;

        projectGroupsNotifier.toggleProjectCheckedStatus(
          project.id,
        );

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel,
          isNot(equals(initialViewModel)),
        );
      },
    );

    test(
      ".toggleProjectCheckedStatus() does not change the project checkbox view models if the given id is null",
      () {
        final expectedProjectCheckboxViewModels =
            projectGroupsNotifier.projectCheckboxViewModels;

        projectGroupsNotifier.toggleProjectCheckedStatus(null);

        final actualProjectCheckboxViewModels =
            projectGroupsNotifier.projectCheckboxViewModels;

        expect(
          actualProjectCheckboxViewModels,
          equals(expectedProjectCheckboxViewModels),
        );
      },
    );

    test(
      ".toggleProjectCheckedStatus() does not change the selected project ids if the given id is null",
      () {
        projectGroupsNotifier.initProjectGroupDialogViewModel(projectGroup.id);

        final expectedSelectedProjects = projectGroupsNotifier
            .projectGroupDialogViewModel.selectedProjectIds;

        projectGroupsNotifier.toggleProjectCheckedStatus(null);

        final actualSelectedProjects = projectGroupsNotifier
            .projectGroupDialogViewModel.selectedProjectIds;

        expect(
          actualSelectedProjects,
          equals(expectedSelectedProjects),
        );
      },
    );

    test(
      ".toggleProjectCheckedStatus() adds the project id to the project group dialog view model if it is not selected",
      () {
        projectGroupsNotifier.initProjectGroupDialogViewModel(projectGroup.id);

        projectGroupsNotifier.toggleProjectCheckedStatus(
          project.id,
        );

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel.selectedProjectIds,
          contains(project.id),
        );
      },
    );

    test(
      ".toggleProjectCheckedStatus() removes the given project id from the project group dialog view model if it is selected",
      () {
        projectGroupsNotifier.initProjectGroupDialogViewModel(projectGroup.id);

        projectGroupsNotifier.toggleProjectCheckedStatus(
          project.id,
        );

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel.selectedProjectIds,
          contains(project.id),
        );

        projectGroupsNotifier.toggleProjectCheckedStatus(
          project.id,
        );

        expect(
          projectGroupsNotifier.projectGroupDialogViewModel.selectedProjectIds,
          isNot(contains(project.id)),
        );
      },
    );

    test(
      ".subscribeToProjectGroups() return normally if the receive project group updates stream emits null",
      () async {
        when(receiveProjectGroupUpdates()).thenAnswer(
          (_) => Stream.value(null),
        );

        expect(
          () => projectGroupsNotifier.subscribeToProjectGroups(),
          returnsNormally,
        );
      },
    );

    test(
      ".subscribeToProjectGroups() delegates to the receive project group updates use case",
      () {
        when(receiveProjectGroupUpdates.call()).thenAnswer(
          (_) => const Stream.empty(),
        );

        projectGroupsNotifier.subscribeToProjectGroups();

        verify(receiveProjectGroupUpdates()).called(once);
      },
    );

    test(
      ".subscribeToProjectGroups() subscribes to the project groups updates stream",
      () async {
        final projectGroupsController = StreamController<List<ProjectGroup>>();

        setUpProjectGroupsNotifier(
          projectGroupsStream: projectGroupsController.stream,
        );

        expect(projectGroupsController.hasListener, isTrue);
      },
    );

    test(
      ".subscribeToProjectGroups() creates a list of project group card view models",
      () async {
        setUpProjectGroupsNotifier();

        final expectedProjectGroupCardViewModels = projectGroups
            .map((projectGroup) => ProjectGroupCardViewModel(
                  name: projectGroup.name,
                  id: projectGroup.id,
                  projectsCount: projectGroup.projectIds.length,
                ))
            .toList();

        final listener = expectAsyncUntil0(
            () {},
            () => listEquals(projectGroupsNotifier.projectGroupCardViewModels,
                expectedProjectGroupCardViewModels));

        projectGroupsNotifier.addListener(listener);
      },
    );

    test(
      ".unsubscribeFromProjectGroups() unsubscribes from project groups updates",
      () async {
        final projectGroupsController = StreamController<List<ProjectGroup>>();

        setUpProjectGroupsNotifier(
          projectGroupsStream: projectGroupsController.stream,
        );

        expect(projectGroupsController.hasListener, isTrue);

        await projectGroupsNotifier.unsubscribeFromProjectGroups();
        expect(projectGroupsController.hasListener, isFalse);
      },
    );

    test(
      ".unsubscribeFromProjectGroups() sets project group models to null",
      () async {
        final asyncListener = expectAsyncUntil0(
          () {},
          () => projectGroupsNotifier.projectGroupModels == null,
        );

        projectGroupsNotifier.addListener(asyncListener);
        await projectGroupsNotifier.unsubscribeFromProjectGroups();
      },
    );

    test(
      ".subscribeToProjectGroups() does not call the use case if already subscribed",
      () async {
        when(receiveProjectGroupUpdates()).thenAnswer(
          (_) => Stream.value(projectGroups),
        );

        projectGroupsNotifier.subscribeToProjectGroups();

        verify(receiveProjectGroupUpdates()).called(once);
      },
    );

    test(
      ".projectGroupsErrorMessage provides an error description if a project groups stream emits a persistent store exception",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        final projectGroupsController = StreamController<List<ProjectGroup>>();
        const errorMessage = PersistentStoreErrorMessage(errorCode);

        setUpProjectGroupsNotifier(
          projectGroupsStream: projectGroupsController.stream,
        );

        projectGroupsController.addError(const PersistentStoreException(
          code: errorCode,
        ));

        final listener = expectAsyncUntil0(
          () {},
          () =>
              projectGroupsNotifier.projectGroupsErrorMessage ==
              errorMessage.message,
        );

        projectGroupsNotifier.addListener(listener);
      },
    );

    test(
      ".addProjectGroup() delegates to the add project group use case",
      () {
        projectGroupsNotifier.addProjectGroup(
          projectGroupName,
          [],
        );

        verify(
          addProjectGroupUseCase(AddProjectGroupParam(
            projectGroupName: projectGroupName,
            projectIds: const [],
          )),
        ).called(once);
      },
    );

    test(
      ".addProjectGroup() does not call the use case if the given name is null",
      () async {
        await projectGroupsNotifier.addProjectGroup(null, []);
        verifyNever(addProjectGroupUseCase(any));
      },
    );

    test(
      ".addProjectGroup() does not call the use case if the given project ids list is null",
      () async {
        await projectGroupsNotifier.addProjectGroup(
          projectGroupName,
          null,
        );

        verifyNever(addProjectGroupUseCase(any));
      },
    );

    test(
      ".addProjectGroup() sets the project group error message if the use case throws a persistent store exception",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        const errorMessage = PersistentStoreErrorMessage(errorCode);

        when(addProjectGroupUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await projectGroupsNotifier.addProjectGroup(
          projectGroupName,
          [],
        );

        expect(
          projectGroupsNotifier.projectGroupSavingError,
          errorMessage.message,
        );
      },
    );

    test(
      ".addProjectGroup() resets the project group error message",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;

        when(addProjectGroupUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await projectGroupsNotifier.addProjectGroup(
          projectGroupName,
          [],
        );

        expect(projectGroupsNotifier.projectGroupSavingError, isNotNull);
        reset(addProjectGroupUseCase);

        await projectGroupsNotifier.addProjectGroup(
          projectGroupName,
          [],
        );

        expect(projectGroupsNotifier.projectGroupSavingError, isNull);
      },
    );

    test(
      ".updateProjectGroup() delegates to the update project group use case",
      () {
        projectGroupsNotifier.updateProjectGroup(
          projectGroupId,
          projectGroupName,
          [],
        );

        verify(
          updateProjectGroupUseCase(
            UpdateProjectGroupParam(projectGroupId, projectGroupName, const []),
          ),
        ).called(once);
      },
    );

    test(
      ".updateProjectGroup() does not call the use case if the given id is null",
      () async {
        await projectGroupsNotifier.updateProjectGroup(
          null,
          projectGroupName,
          [],
        );

        verifyNever(updateProjectGroupUseCase(any));
      },
    );

    test(
      ".updateProjectGroup() does not call the use case if the given name is null",
      () async {
        await projectGroupsNotifier.updateProjectGroup(
          projectGroupId,
          null,
          [],
        );

        verifyNever(updateProjectGroupUseCase(any));
      },
    );

    test(
      ".updateProjectGroup() does not call the use case if the given project ids list is null",
      () async {
        await projectGroupsNotifier.updateProjectGroup(
          projectGroupId,
          projectGroupName,
          null,
        );

        verifyNever(updateProjectGroupUseCase(any));
      },
    );

    test(
      ".updateProjectGroup() sets the project group error message if throws a persistent store exception",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        const errorMessage = PersistentStoreErrorMessage(errorCode);

        when(updateProjectGroupUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await projectGroupsNotifier.updateProjectGroup(
          projectGroupId,
          projectGroupName,
          [],
        );

        expect(
          projectGroupsNotifier.projectGroupSavingError,
          errorMessage.message,
        );
      },
    );

    test(
      ".updateProjectGroup() resets the project group error message",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;

        when(updateProjectGroupUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await projectGroupsNotifier.updateProjectGroup(
          projectGroupId,
          projectGroupName,
          [],
        );

        expect(
          projectGroupsNotifier.projectGroupSavingError,
          isNotNull,
        );

        reset(updateProjectGroupUseCase);

        await projectGroupsNotifier.updateProjectGroup(
          projectGroupId,
          projectGroupName,
          [],
        );

        expect(
          projectGroupsNotifier.projectGroupSavingError,
          isNull,
        );
      },
    );

    test(
      ".deleteProjectGroup() delegates to the delete project group use case",
      () {
        projectGroupsNotifier.deleteProjectGroup(projectGroupId);

        verify(
          deleteProjectGroupUseCase(
            DeleteProjectGroupParam(projectGroupId: projectGroupId),
          ),
        ).called(once);
      },
    );

    test(
      ".deleteProjectGroup() does not call the use case if the given id is null",
      () async {
        await projectGroupsNotifier.deleteProjectGroup(null);

        verifyNever(deleteProjectGroupUseCase(any));
      },
    );

    test(
      ".deleteProjectGroup() sets the project group error message if the use case throws a persistent store exception",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        const errorMessage = PersistentStoreErrorMessage(errorCode);

        when(deleteProjectGroupUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await projectGroupsNotifier.deleteProjectGroup(projectGroupId);

        expect(
          projectGroupsNotifier.projectGroupSavingError,
          errorMessage.message,
        );
      },
    );

    test(
      ".deleteProjectGroup() resets the project group error message",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;

        when(deleteProjectGroupUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await projectGroupsNotifier.deleteProjectGroup(projectGroupId);

        expect(
          projectGroupsNotifier.projectGroupSavingError,
          isNotNull,
        );

        reset(deleteProjectGroupUseCase);

        await projectGroupsNotifier.deleteProjectGroup(projectGroupId);

        expect(
          projectGroupsNotifier.projectGroupSavingError,
          isNull,
        );
      },
    );

    test(
      ".setProjects() creates a list of project checkbox view models from the given projects",
      () {
        projectGroupsNotifier.setProjects(projects);

        final expectedProjectCheckboxViewModels = projects.map(
          (e) => ProjectCheckboxViewModel(
            id: e.id,
            name: e.name,
            isChecked: false,
          ),
        );

        expect(
          projectGroupsNotifier.projectCheckboxViewModels,
          expectedProjectCheckboxViewModels,
        );
      },
    );

    test(
      ".setProjects() updates the list of project group card view models corresponding to new projects",
      () {
        const newProjects = [
          ProjectModel(id: "id2", name: 'name'),
        ];
        final availableProjectIds = newProjects.map((project) => project.id);

        final expectedProjectGroupCardViewModels =
            <ProjectGroupCardViewModel>[];

        for (final group in projectGroups) {
          final selectedIds = List<String>.from(group.projectIds);
          selectedIds.removeWhere(
              (projectId) => !availableProjectIds.contains(projectId));

          expectedProjectGroupCardViewModels.add(ProjectGroupCardViewModel(
            id: group.id,
            name: group.name,
            projectsCount: selectedIds.length,
          ));
        }

        final expectListener = expectAsyncUntil0(
          () {},
          () {
            final projectGroupCardViewModels =
                projectGroupsNotifier.projectGroupCardViewModels;

            return listEquals(
              projectGroupCardViewModels,
              expectedProjectGroupCardViewModels,
            );
          },
        );

        projectGroupsNotifier.addListener(expectListener);
        projectGroupsNotifier.setProjects(newProjects);
      },
    );

    test(
      ".setProjects() sets a list of project checkbox view models to null if the given projects are null",
      () {
        projectGroupsNotifier.setProjects(null);

        expect(
          projectGroupsNotifier.projectCheckboxViewModels,
          isNull,
        );
      },
    );

    test(
      ".setProjects() saves the projects error message if it is not null",
      () {
        const expectedMessage = CommonStrings.unknownErrorMessage;

        projectGroupsNotifier.setProjects(projects, expectedMessage);

        expect(
          projectGroupsNotifier.projectsErrorMessage,
          equals(expectedMessage),
        );
      },
    );

    test(
      ".dispose() cancels all created subscriptions",
      () async {
        final projectGroupsNotifier = ProjectGroupsNotifier(
          receiveProjectGroupUpdates,
          addProjectGroupUseCase,
          updateProjectGroupUseCase,
          deleteProjectGroupUseCase,
        );

        final projectGroupsController = StreamController<List<ProjectGroup>>();

        when(receiveProjectGroupUpdates()).thenAnswer(
          (_) => projectGroupsController.stream,
        );

        projectGroupsNotifier.subscribeToProjectGroups();

        expect(projectGroupsController.hasListener, isTrue);

        projectGroupsNotifier.dispose();

        expect(projectGroupsController.hasListener, isFalse);
      },
    );
  });
}

class AddProjectGroupUseCaseMock extends Mock
    implements AddProjectGroupUseCase {}

class UpdateProjectGroupUseCaseMock extends Mock
    implements UpdateProjectGroupUseCase {}

class DeleteProjectGroupUseCaseMock extends Mock
    implements DeleteProjectGroupUseCase {}

class ReceiveProjectGroupUpdatesMock extends Mock
    implements ReceiveProjectGroupUpdates {}
