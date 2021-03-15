// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:metrics/common/domain/entities/persistent_store_error_code.dart';
import 'package:metrics/common/domain/entities/persistent_store_exception.dart';
import 'package:metrics/common/domain/usecases/receive_project_updates.dart';
import 'package:metrics/common/presentation/models/persistent_store_error_message.dart';
import 'package:metrics/common/presentation/models/project_model.dart';
import 'package:metrics/common/presentation/state/projects_notifier.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectsNotifier", () {
    final receiveProjectUpdatesMock = ReceiveProjectUpdatesMock();
    ProjectsNotifier projectsNotifier;
    const projects = [
      Project(id: 'id1', name: 'name1'),
      Project(id: 'id2', name: 'name2'),
    ];

    setUp(() {
      reset(receiveProjectUpdatesMock);
      projectsNotifier = ProjectsNotifier(receiveProjectUpdatesMock);
    });

    tearDown(() {
      projectsNotifier.dispose();
    });

    test(
      "throws an AssertionError if the receive project updates use case is null",
      () {
        expect(() => ProjectsNotifier(null), throwsAssertionError);
      },
    );

    test(
      ".subscribeToProjects() completes normally if the receive project updates stream emits null",
      () async {
        when(receiveProjectUpdatesMock()).thenAnswer((_) => Stream.value(null));

        await expectLater(projectsNotifier.subscribeToProjects(), completes);
      },
    );

    test(
      ".subscribeToProjects() delegates to the receive project updates use case",
      () {
        when(receiveProjectUpdatesMock()).thenAnswer((_) => Stream.value(null));

        projectsNotifier.subscribeToProjects();

        verify(receiveProjectUpdatesMock()).called(once);
      },
    );

    test(
      ".subscribeToProjects() subscribes to the receive project updates use case stream",
      () async {
        final projectsController = StreamController<List<Project>>();

        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => projectsController.stream,
        );

        await projectsNotifier.subscribeToProjects();

        expect(projectsController.hasListener, isTrue);
      },
    );

    test(
      ".projectsErrorMessage provides an error description if a project updates use case stream emits a persistent store exception",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        final projectsController = StreamController<List<Project>>();
        const errorMessage = PersistentStoreErrorMessage(errorCode);

        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => projectsController.stream,
        );

        projectsController.addError(const PersistentStoreException(
          code: errorCode,
        ));

        final projectsNotifier = ProjectsNotifier(receiveProjectUpdatesMock);

        await projectsNotifier.subscribeToProjects();

        final listener = expectAsyncUntil0(
          () {},
          () => projectsNotifier.projectsErrorMessage == errorMessage.message,
        );

        projectsNotifier.addListener(listener);
      },
    );

    test(
      ".unsubscribeFromProjects() unsubscribes from project updates",
      () async {
        final projectsController = StreamController<List<Project>>();

        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => projectsController.stream,
        );

        await projectsNotifier.subscribeToProjects();

        expect(projectsController.hasListener, isTrue);

        await projectsNotifier.unsubscribeFromProjects();

        expect(projectsController.hasListener, isFalse);
      },
    );

    test(
      ".projectModels returns an empty list if the receive project updates stream emits an empty list",
      () async {
        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => Stream.value([]),
        );

        final listener = expectAsyncUntil0(
          () {},
          () => projectsNotifier.projectModels?.isEmpty,
        );

        projectsNotifier.addListener(listener);
        await projectsNotifier.subscribeToProjects();
      },
    );

    test(
      "converts the Projects into ProjectModels",
      () async {
        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => Stream.value(projects),
        );

        final expectedProjectModels = projects
            .map((project) => ProjectModel(id: project.id, name: project.name))
            .toList();

        final listener = expectAsyncUntil0(() {}, () {
          final projectModels = projectsNotifier.projectModels;
          if (projectModels == null || projectModels.isEmpty) return false;

          return listEquals(projectModels, expectedProjectModels);
        });

        projectsNotifier.addListener(listener);
        await projectsNotifier.subscribeToProjects();
      },
    );

    test(
      "updates ProjectModels if receive project updates use case emits a new list",
      () async {
        const newProjects = [
          Project(id: 'new1', name: 'new'),
          Project(id: 'new2', name: 'new_projects'),
        ];

        final projectsController = StreamController<List<Project>>();
        projectsController.add(projects);

        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => projectsController.stream,
        );

        await projectsNotifier.subscribeToProjects();
        projectsController.add(newProjects);

        final expectedProjectModels = newProjects
            .map((project) => ProjectModel(id: project.id, name: project.name))
            .toList();

        final listener = expectAsyncUntil0(() {}, () {
          final projectModels = projectsNotifier.projectModels;
          if (projectModels == null || projectModels.isEmpty) return false;

          return listEquals(projectModels, expectedProjectModels);
        });

        projectsNotifier.addListener(listener);
      },
    );

    test(
      ".unsubscribeFromProjects() clears project models",
      () async {
        final projectsNotifier = ProjectsNotifier(receiveProjectUpdatesMock);

        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => Stream.value(projects),
        );

        await expectLater(projectsNotifier.subscribeToProjects(), completes);

        expect(projectsNotifier.projectModels, isNotNull);

        await projectsNotifier.unsubscribeFromProjects();

        expect(projectsNotifier.projectModels, isNull);
      },
    );

    test(
      ".dispose() cancels projects subscription",
      () async {
        final projectsNotifier = ProjectsNotifier(receiveProjectUpdatesMock);
        final projectsController = StreamController<List<Project>>();

        when(receiveProjectUpdatesMock()).thenAnswer(
          (_) => projectsController.stream,
        );

        await projectsNotifier.subscribeToProjects();

        expect(projectsController.hasListener, isTrue);

        projectsNotifier.dispose();

        expect(projectsController.hasListener, isFalse);
      },
    );
  });
}

class ReceiveProjectUpdatesMock extends Mock implements ReceiveProjectUpdates {}
