// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:metrics/common/presentation/models/project_model.dart';
import 'package:metrics/dashboard/domain/entities/collections/date_time_set.dart';
import 'package:metrics/dashboard/domain/entities/metrics/build_number_metric.dart';
import 'package:metrics/dashboard/domain/entities/metrics/build_performance.dart';
import 'package:metrics/dashboard/domain/entities/metrics/build_result.dart';
import 'package:metrics/dashboard/domain/entities/metrics/build_result_metric.dart';
import 'package:metrics/dashboard/domain/entities/metrics/dashboard_project_metrics.dart';
import 'package:metrics/dashboard/domain/entities/metrics/performance_metric.dart';
import 'package:metrics/dashboard/domain/entities/metrics/project_build_status_metric.dart';
import 'package:metrics/dashboard/domain/usecases/parameters/project_id_param.dart';
import 'package:metrics/dashboard/domain/usecases/receive_project_metrics_updates.dart';
import 'package:metrics/dashboard/presentation/state/project_metrics_notifier.dart';
import 'package:metrics/dashboard/presentation/view_models/build_result_metric_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/project_group_dropdown_item_view_model.dart';
import 'package:metrics/dashboard/presentation/view_models/project_metrics_tile_view_model.dart';
import 'package:metrics/project_groups/presentation/models/project_group_model.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ProjectMetricsNotifier", () {
    const projectId = 'projectId';
    const projectIdParam = ProjectIdParam(projectId);
    const List<ProjectModel> projects = [
      ProjectModel(id: 'id', name: 'name'),
      ProjectModel(id: 'id2', name: 'name2'),
    ];
    const String errorMessage = null;

    final receiveProjectMetricsUpdates = _ReceiveProjectMetricsUpdatesStub();

    DashboardProjectMetrics expectedProjectMetrics;
    ProjectMetricsNotifier projectMetricsNotifier;

    setUp(() async {
      projectMetricsNotifier = ProjectMetricsNotifier(
        receiveProjectMetricsUpdates,
      );

      expectedProjectMetrics =
          await receiveProjectMetricsUpdates(projectIdParam).first;

      final _completer = Completer();

      void initializationListener() {
        if (projectMetricsNotifier.projectsMetricsTileViewModels.every(
                (projectMetric) => projectMetric.buildNumberMetric != null) &&
            !_completer.isCompleted) {
          _completer.complete();
        }
      }

      projectMetricsNotifier.addListener(initializationListener);
      await projectMetricsNotifier.setProjects(
        projects,
        errorMessage,
      );
      await _completer.future;
      projectMetricsNotifier.removeListener(initializationListener);
    });

    tearDown(() async {
      await projectMetricsNotifier.dispose();
    });

    test(
      "throws an AssertionError if receive project metric updates use case is null",
      () {
        expect(
          () => ProjectMetricsNotifier(null),
          throwsAssertionError,
        );
      },
    );

    test(
      "creates ProjectMetricsData with empty points from empty DashboardProjectMetrics",
      () async {
        final receiveEmptyMetrics = _ReceiveProjectMetricsUpdatesStub(
          metrics: const DashboardProjectMetrics(),
        );
        const projects = [ProjectModel(id: 'id', name: 'name')];

        final emptyBuildResultMetric = BuildResultMetricViewModel(
          buildResults: UnmodifiableListView([]),
        );

        final projectMetricsNotifier = ProjectMetricsNotifier(
          receiveEmptyMetrics,
        );

        bool hasNullMetrics;
        final metricsListener = expectAsyncUntil0(() async {
          final projectMetrics =
              projectMetricsNotifier.projectsMetricsTileViewModels;
          if (projectMetrics == null || projectMetrics.isEmpty) return;

          final projectMetric = projectMetrics.first;
          final buildResultMetrics = projectMetric.buildResultMetrics;
          final performanceMetrics = projectMetric.performanceSparkline;
          final stabilityMetric = projectMetric.stability;

          hasNullMetrics = buildResultMetrics == emptyBuildResultMetric &&
              performanceMetrics != null &&
              performanceMetrics.performance.isEmpty &&
              stabilityMetric != null;
        }, () => hasNullMetrics);

        projectMetricsNotifier.addListener(metricsListener);

        await projectMetricsNotifier.setProjects(projects, errorMessage);

        addTearDown(projectMetricsNotifier.dispose);
      },
    );

    test(
      "creates ProjectMetricsData with null metrics if the DashboardProjectMetrics is null",
      () async {
        final receiveProjectMetricsUpdates =
            _ReceiveProjectMetricsUpdatesStub.withNullMetrics();

        final projectMetricsNotifier = ProjectMetricsNotifier(
          receiveProjectMetricsUpdates,
        );

        bool hasNullMetrics;
        final metricsListener = expectAsyncUntil0(() async {
          final projectMetrics =
              projectMetricsNotifier.projectsMetricsTileViewModels;
          if (projectMetrics == null || projectMetrics.isEmpty) return;

          final buildResultMetrics = projectMetrics.first.buildResultMetrics;
          final performanceMetrics = projectMetrics.first.performanceSparkline;

          hasNullMetrics =
              buildResultMetrics == null && performanceMetrics == null;

          if (hasNullMetrics) await projectMetricsNotifier.dispose();
        }, () => hasNullMetrics);

        projectMetricsNotifier.addListener(metricsListener);

        await projectMetricsNotifier.setProjects(projects, errorMessage);
      },
    );

    test("loads the build status data", () async {
      final expectedProjectBuildStatus =
          expectedProjectMetrics.projectBuildStatusMetric;

      final projectMetrics =
          projectMetricsNotifier.projectsMetricsTileViewModels.first;
      final projectBuildStatus = projectMetrics.buildStatus;

      expect(
        projectBuildStatus.value,
        equals(expectedProjectBuildStatus.status),
      );
    });

    test("loads the coverage data", () async {
      final expectedProjectCoverage = expectedProjectMetrics.coverage;

      final projectMetrics =
          projectMetricsNotifier.projectsMetricsTileViewModels.first;
      final projectCoverage = projectMetrics.coverage;

      expect(projectCoverage.value, equals(expectedProjectCoverage.value));
    });

    test("loads the stability data", () async {
      final expectedProjectStability = expectedProjectMetrics.stability;

      final projectMetrics =
          projectMetricsNotifier.projectsMetricsTileViewModels.first;
      final projectStability = projectMetrics.stability;

      expect(projectStability.value, equals(expectedProjectStability.value));
    });

    test("loads the build number metrics", () async {
      final expectedBuildNumberMetrics =
          expectedProjectMetrics.buildNumberMetrics;

      final firstProjectMetrics =
          projectMetricsNotifier.projectsMetricsTileViewModels.first;

      expect(
        firstProjectMetrics.buildNumberMetric.numberOfBuilds,
        expectedBuildNumberMetrics.numberOfBuilds,
      );
    });

    test("loads the performance metrics", () async {
      final period = ReceiveProjectMetricsUpdates.buildsLoadingPeriod.inDays;
      final expectedPerformanceMetrics =
          expectedProjectMetrics.performanceMetrics;

      final buildPerformance =
          expectedPerformanceMetrics.buildsPerformance.first;
      final expectedX = List.generate(period + 1, (index) => index);
      final expectedY = List.generate(period, (_) => 0);
      expectedY.add(buildPerformance.duration.inMilliseconds);

      final firstProjectMetrics =
          projectMetricsNotifier.projectsMetricsTileViewModels.first;
      final performanceMetrics = firstProjectMetrics.performanceSparkline;
      final performancePoints = performanceMetrics.performance;

      expect(performancePoints, hasLength(equals(period + 1)));
      expect(
        performanceMetrics.value,
        equals(expectedPerformanceMetrics.averageBuildDuration),
      );
      expect(performancePoints.map((p) => p.x), equals(expectedX));
      expect(performancePoints.map((p) => p.y), equals(expectedY));
    });

    test("loads the build result metrics", () async {
      final expectedBuildResults =
          expectedProjectMetrics.buildResultMetrics.buildResults;

      final firstProjectMetrics =
          projectMetricsNotifier.projectsMetricsTileViewModels.first;
      final buildResultMetrics = firstProjectMetrics.buildResultMetrics;

      expect(
        buildResultMetrics.buildResults.length,
        expectedBuildResults.length,
      );

      final expectedBuildResult = expectedBuildResults.first;
      final firstBuildResultMetric = buildResultMetrics.buildResults.first;

      expect(
        firstBuildResultMetric.duration,
        expectedBuildResult.duration,
      );
      expect(
        firstBuildResultMetric.date,
        expectedBuildResult.date,
      );
      expect(
        firstBuildResultMetric.buildStatus,
        expectedBuildResult.buildStatus,
      );
      expect(
        firstBuildResultMetric.url,
        expectedBuildResult.url,
      );
    });

    test(
      "deletes the ProjectMetricsData if the project was deleted on server",
      () async {
        final metricsNotifier = ProjectMetricsNotifier(
          receiveProjectMetricsUpdates,
        );

        await metricsNotifier.setProjects(projects, errorMessage);

        final List<ProjectModel> expectedProjects = [...projects];
        List<ProjectMetricsTileViewModel> actualProjects =
            metricsNotifier.projectsMetricsTileViewModels;

        expect(actualProjects.length, expectedProjects.length);

        expectedProjects.removeLast();

        await metricsNotifier.setProjects(expectedProjects, errorMessage);

        actualProjects = metricsNotifier.projectsMetricsTileViewModels;

        expect(actualProjects.length, expectedProjects.length);

        await metricsNotifier.dispose();
      },
    );

    test(
      ".projectMetrics is an empty list when the projects parameter is an empty list",
      () async {
        final metricsNotifier = ProjectMetricsNotifier(
          receiveProjectMetricsUpdates,
        );

        bool hasEmptyProjectMetrics;
        final metricsListener = expectAsyncUntil0(() async {
          final projectMetrics = metricsNotifier.projectsMetricsTileViewModels;
          hasEmptyProjectMetrics =
              projectMetrics != null && projectMetrics.isEmpty;

          if (hasEmptyProjectMetrics) await metricsNotifier.dispose();
        }, () => hasEmptyProjectMetrics);

        metricsNotifier.addListener(metricsListener);

        await metricsNotifier.setProjects([], errorMessage);
      },
    );

    test(
      ".filterByProjectName() filters list of the project metrics according to the given value",
      () async {
        final metricsTileViewModel =
            projectMetricsNotifier.projectsMetricsTileViewModels.last;
        final expectedProjectMetrics = [metricsTileViewModel];
        final projectNameFilter = metricsTileViewModel.projectName;

        final listener = expectAsyncUntil0(
          () {},
          () {
            final filteredProjectMetrics =
                projectMetricsNotifier.projectsMetricsTileViewModels;
            return listEquals(filteredProjectMetrics, expectedProjectMetrics);
          },
        );

        projectMetricsNotifier.addListener(listener);
        projectMetricsNotifier.filterByProjectName(projectNameFilter);
      },
    );

    test(
      ".resetProjectNameFilter() resets the project name filter",
      () async {
        const projectNameFilter = 'filter name';

        final listener = expectAsyncUntil0(
          () {
            if (projectMetricsNotifier.projectNameFilter != null) {
              projectMetricsNotifier.resetProjectNameFilter();
            }
          },
          () => projectMetricsNotifier.projectNameFilter == null,
        );

        projectMetricsNotifier.addListener(listener);
        projectMetricsNotifier.filterByProjectName(projectNameFilter);
      },
    );

    test(
      ".filterByProjectName() doesn't apply filters to the list of the project metrics if the given value is null",
      () async {
        final expectedProjectMetrics =
            projectMetricsNotifier.projectsMetricsTileViewModels;

        final listener = expectAsyncUntil0(
          () {},
          () {
            final filteredProjectMetrics =
                projectMetricsNotifier.projectsMetricsTileViewModels;
            return listEquals(filteredProjectMetrics, expectedProjectMetrics);
          },
        );

        projectMetricsNotifier.addListener(listener);
        projectMetricsNotifier.filterByProjectName(null);
      },
    );

    test(
      ".filterByProjectName() updates the project name filter value",
      () async {
        const expectedProjectNameFilter = 'some project';

        final listener = expectAsyncUntil0(
          () {},
          () {
            return projectMetricsNotifier.projectNameFilter ==
                expectedProjectNameFilter;
          },
        );

        projectMetricsNotifier.addListener(listener);
        projectMetricsNotifier.filterByProjectName(expectedProjectNameFilter);
      },
    );

    test(
      ".dispose() unsubscribes from all streams and removes project metrics",
      () async {
        final metricsUpdates = _ReceiveProjectMetricsUpdatesStub();
        final metricsNotifier = ProjectMetricsNotifier(metricsUpdates);

        await metricsNotifier.setProjects(projects, errorMessage);

        await expectLater(metricsUpdates.hasListener, isTrue);

        await metricsNotifier.dispose();

        expect(metricsUpdates.hasListener, isFalse);
        expect(metricsNotifier.projectsMetricsTileViewModels, isNull);
      },
    );

    test(
      ".setProjects() cancels all created subscriptions and removes project metrics if the given projects are null",
      () async {
        final metricsUpdates = _ReceiveProjectMetricsUpdatesStub();
        final metricsNotifier = ProjectMetricsNotifier(metricsUpdates);

        await metricsNotifier.setProjects(projects, errorMessage);

        expect(metricsUpdates.hasListener, isTrue);

        await metricsNotifier.setProjects(null, null);

        expect(metricsUpdates.hasListener, isFalse);
        expect(metricsNotifier.projectsMetricsTileViewModels, isNull);

        await metricsNotifier.dispose();
      },
    );

    test(
      ".setProjects() cancels all created subscriptions and removes project metrics if the given projects are empty",
      () async {
        final metricsUpdates = _ReceiveProjectMetricsUpdatesStub();
        final metricsNotifier = ProjectMetricsNotifier(metricsUpdates);

        await metricsNotifier.setProjects(projects, errorMessage);

        expect(metricsUpdates.hasListener, isTrue);

        await metricsNotifier.setProjects([], null);

        expect(metricsUpdates.hasListener, isFalse);
        expect(metricsNotifier.projectsMetricsTileViewModels, isEmpty);

        await metricsNotifier.dispose();
      },
    );

    test(
      ".setProjectGroups() refreshes a list of project group dropdown item view models",
      () {
        final projectGroups = [
          ProjectGroupModel(
            id: "id",
            name: "name",
            projectIds: UnmodifiableListView([]),
          ),
          ProjectGroupModel(
            id: "id2",
            name: "name1",
            projectIds: UnmodifiableListView([]),
          ),
        ];

        projectMetricsNotifier.setProjectGroups(projectGroups);

        final newProjectGroups = [
          ProjectGroupModel(
            id: "id",
            name: "name",
            projectIds: UnmodifiableListView(['id1']),
          ),
          ProjectGroupModel(
            id: "id2",
            name: "name2",
            projectIds: UnmodifiableListView(['id2']),
          ),
        ];

        final newProjectGroupItemViewModels = newProjectGroups.map(
          (projectGroup) => ProjectGroupDropdownItemViewModel(
            id: projectGroup.id,
            name: projectGroup.name,
          ),
        );

        projectMetricsNotifier.setProjectGroups(newProjectGroups);

        expect(
          projectMetricsNotifier.projectGroupDropdownItems,
          containsAll(newProjectGroupItemViewModels),
        );
      },
    );

    test(
      ".setProjectGroups() updates selected project group",
      () {
        const projectGroupId = "groupId";

        final List<ProjectGroupModel> projectGroups = [
          ProjectGroupModel(
            id: projectGroupId,
            name: "name",
            projectIds: UnmodifiableListView([]),
          ),
        ];

        projectMetricsNotifier.setProjectGroups(projectGroups);
        projectMetricsNotifier.selectProjectGroup(projectGroupId);

        final updatedProjectGroup = ProjectGroupModel(
          id: projectGroupId,
          name: "name1",
          projectIds: UnmodifiableListView([]),
        );
        final newProjectGroups = [updatedProjectGroup];

        projectMetricsNotifier.setProjectGroups(newProjectGroups);

        expect(
          projectMetricsNotifier.selectedProjectGroup.id,
          equals(projectGroupId),
        );
        expect(
          projectMetricsNotifier.selectedProjectGroup.name,
          equals(updatedProjectGroup.name),
        );
      },
    );

    test(
      ".setProjectGroups() selects the all projects project group if the selected one was deleted",
      () {
        const expectedSelectedProjectGroup = ProjectGroupDropdownItemViewModel(
          name: "All projects",
        );
        const projectGroupId = "groupId";

        final firstProjectGroup = ProjectGroupModel(
          id: projectGroupId,
          name: "name",
          projectIds: UnmodifiableListView([]),
        );
        final secondProjectGroup = ProjectGroupModel(
          id: "groupId2",
          name: "name1",
          projectIds: UnmodifiableListView([]),
        );

        final List<ProjectGroupModel> projectGroups = [
          firstProjectGroup,
          secondProjectGroup,
        ];

        projectMetricsNotifier.setProjectGroups(projectGroups);
        projectMetricsNotifier.selectProjectGroup(projectGroupId);

        expect(
          projectMetricsNotifier.selectedProjectGroup.id,
          equals(projectGroupId),
        );

        final newProjectGroups = [secondProjectGroup];

        projectMetricsNotifier.setProjectGroups(newProjectGroups);

        expect(
          projectMetricsNotifier.selectedProjectGroup,
          equals(expectedSelectedProjectGroup),
        );
      },
    );

    test(
      ".selectProjectGroup() filters a list of project metrics according to the given project group id",
      () {
        const projectId = "projectId";
        const projectGroupId = "groupId";
        const selectedProjectIds = [projectId];

        const projects = [
          ProjectModel(id: projectId, name: 'name'),
          ProjectModel(id: 'projectId2', name: 'name'),
        ];

        final List<ProjectGroupModel> projectGroups = [
          ProjectGroupModel(
            id: projectGroupId,
            name: "name",
            projectIds: UnmodifiableListView(selectedProjectIds),
          ),
          ProjectGroupModel(
            id: "groupId2",
            name: "name1",
            projectIds: UnmodifiableListView([]),
          ),
        ];

        projectMetricsNotifier.setProjects(projects, null);
        projectMetricsNotifier.setProjectGroups(projectGroups);
        projectMetricsNotifier.selectProjectGroup(projectGroupId);

        final projectMetricsTileIds = projectMetricsNotifier
            .projectsMetricsTileViewModels
            .map((tile) => tile.projectId)
            .toList();

        expect(
          projectMetricsTileIds,
          equals(selectedProjectIds),
        );
      },
    );

    test(
      ".selectProjectGroup() selects the project group with the given id",
      () {
        const projectGroupId = "id";

        final List<ProjectGroupModel> projectGroups = [
          ProjectGroupModel(
            id: projectGroupId,
            name: "name",
            projectIds: UnmodifiableListView([]),
          ),
          ProjectGroupModel(
            id: "id2",
            name: "name1",
            projectIds: UnmodifiableListView([]),
          ),
        ];

        projectMetricsNotifier.setProjectGroups(projectGroups);
        projectMetricsNotifier.selectProjectGroup(projectGroupId);

        expect(
          projectMetricsNotifier.selectedProjectGroup.id,
          equals(projectGroupId),
        );
      },
    );

    test(
      ".selectProjectGroup() doesn't select the project group if there is no project group with the given id",
      () {
        final projectGroups = [
          ProjectGroupModel(
            id: "id",
            name: "name",
            projectIds: UnmodifiableListView([]),
          ),
          ProjectGroupModel(
            id: "id2",
            name: "name1",
            projectIds: UnmodifiableListView([]),
          ),
        ];

        projectMetricsNotifier.setProjectGroups(projectGroups);

        final initialSelectedProjectGroup =
            projectMetricsNotifier.selectedProjectGroup;

        projectMetricsNotifier.selectProjectGroup("no_such_id");

        expect(
          projectMetricsNotifier.selectedProjectGroup,
          equals(initialSelectedProjectGroup),
        );
      },
    );

    test(
      ".setProjectGroups() resets project group dropdown items and selected project group to null if project groups are null",
      () {
        final projectGroups = [
          ProjectGroupModel(
            id: "id",
            name: "name",
            projectIds: UnmodifiableListView([]),
          ),
          ProjectGroupModel(
            id: "id2",
            name: "name1",
            projectIds: UnmodifiableListView([]),
          ),
        ];

        projectMetricsNotifier.setProjectGroups(projectGroups);

        expect(projectMetricsNotifier.selectedProjectGroup, isNotNull);
        expect(projectMetricsNotifier.projectGroupDropdownItems, isNotNull);

        projectMetricsNotifier.setProjectGroups(null);

        expect(projectMetricsNotifier.selectedProjectGroup, isNull);
        expect(projectMetricsNotifier.projectGroupDropdownItems, isNull);
      },
    );
  });
}

/// A stub implementation of the [ReceiveProjectMetricsUpdates].
class _ReceiveProjectMetricsUpdatesStub
    implements ReceiveProjectMetricsUpdates {
  /// A test [DashboardProjectMetrics] used in tests.
  static final _projectMetrics = DashboardProjectMetrics(
    projectId: 'id',
    performanceMetrics: PerformanceMetric(
      buildsPerformance: DateTimeSet.from([
        BuildPerformance(
          date: DateTime.now(),
          duration: const Duration(minutes: 14),
        )
      ]),
      averageBuildDuration: const Duration(minutes: 3),
    ),
    buildNumberMetrics: const BuildNumberMetric(
      numberOfBuilds: 1,
    ),
    buildResultMetrics: BuildResultMetric(
      buildResults: [
        BuildResult(
          date: DateTime.now(),
          duration: const Duration(minutes: 14),
          url: 'some url',
        ),
      ],
    ),
    coverage: Percent(0.2),
    stability: Percent(0.5),
    projectBuildStatusMetric: const ProjectBuildStatusMetric(
      status: BuildStatus.successful,
    ),
  );

  /// A [BehaviorSubject] that holds the [DashboardProjectMetrics] and provides a stream of them.
  ///
  /// The [BehaviorSubject.stream] is returned from [call] method.
  final BehaviorSubject<DashboardProjectMetrics> _metricsUpdatesSubject =
      BehaviorSubject();

  /// Creates the [_ReceiveProjectMetricsUpdatesStub] with the given [metrics].
  ///
  /// If no [metrics] passed or the `null` passed, the default project metrics used.
  _ReceiveProjectMetricsUpdatesStub({DashboardProjectMetrics metrics}) {
    _metricsUpdatesSubject.add(metrics ?? _projectMetrics);
  }

  /// Creates the [_ReceiveProjectMetricsUpdatesStub] that returns the stream
  /// that emits `null` from [call] method.
  _ReceiveProjectMetricsUpdatesStub.withNullMetrics() {
    _metricsUpdatesSubject.add(null);
  }

  @override
  Stream<DashboardProjectMetrics> call([ProjectIdParam params]) {
    return _metricsUpdatesSubject.stream;
  }

  ///  Detects if the stream, returned from [call] method has any listeners.
  bool get hasListener => _metricsUpdatesSubject.hasListener;
}
