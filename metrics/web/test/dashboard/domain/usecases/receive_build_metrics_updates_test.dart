// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/dashboard/domain/entities/collections/date_time_set.dart';
import 'package:metrics/dashboard/domain/entities/metrics/build_number_metric.dart';
import 'package:metrics/dashboard/domain/entities/metrics/build_performance.dart';
import 'package:metrics/dashboard/domain/entities/metrics/build_result.dart';
import 'package:metrics/dashboard/domain/entities/metrics/dashboard_project_metrics.dart';
import 'package:metrics/dashboard/domain/entities/metrics/performance_metric.dart';
import 'package:metrics/dashboard/domain/entities/metrics/project_build_status_metric.dart';
import 'package:metrics/dashboard/domain/repositories/metrics_repository.dart';
import 'package:metrics/dashboard/domain/usecases/parameters/project_id_param.dart';
import 'package:metrics/dashboard/domain/usecases/receive_project_metrics_updates.dart';
import 'package:metrics/util/date.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("ReceiveProjectMetricUpdates", () {
    const expectedBuildsToLoad =
        ReceiveProjectMetricsUpdates.buildsToLoadForChartMetrics;
    const expectedLoadingPeriod =
        ReceiveProjectMetricsUpdates.buildsLoadingPeriod;

    const projectId = 'projectId';
    final emptyBuildsStream = Stream<List<Build>>.value([]);
    final repository = _MetricsRepositoryStub();
    final receiveProjectMetricsUpdates =
        ReceiveProjectMetricsUpdates(repository);
    const extraBuildsToGenerate = 5;
    const numberOfBuildsToGenerate =
        expectedBuildsToLoad + extraBuildsToGenerate;

    List<Build> builds;
    Build lastBuild;
    DashboardProjectMetrics projectMetrics;

    setUpAll(() async {
      builds = _MetricsRepositoryStub.testBuilds;

      projectMetrics =
          await receiveProjectMetricsUpdates(const ProjectIdParam(projectId))
              .first;

      lastBuild = builds.first;
    });

    test("throws an AssertionError when the given repository is null", () {
      expect(
        () => ReceiveProjectMetricsUpdates(null),
        throwsAssertionError,
      );
    });

    test("subscribes to builds for common builds loading periods", () {
      final repository = _MetricsRepositoryMock();

      when(repository.latestProjectBuildsStream(any, any))
          .thenAnswer((_) => emptyBuildsStream);
      when(repository.lastSuccessfulBuildStream(any))
          .thenAnswer((_) => emptyBuildsStream);
      when(repository.projectBuildsFromDateStream(any, any))
          .thenAnswer((_) => emptyBuildsStream);

      final receiveProjectMetricsUpdates =
          ReceiveProjectMetricsUpdates(repository);

      receiveProjectMetricsUpdates(const ProjectIdParam('projectId'));

      verify(
        repository.projectBuildsFromDateStream(
          any,
          DateTime.now().subtract(expectedLoadingPeriod).date,
        ),
      ).called(equals(1));
    });

    test("subscribes to number of builds to load for chart metrics", () {
      final repository = _MetricsRepositoryMock();

      when(repository.latestProjectBuildsStream(any, any))
          .thenAnswer((_) => emptyBuildsStream);
      when(repository.lastSuccessfulBuildStream(any))
          .thenAnswer((_) => emptyBuildsStream);
      when(repository.projectBuildsFromDateStream(any, any))
          .thenAnswer((_) => emptyBuildsStream);

      final receiveProjectMetricsUpdates =
          ReceiveProjectMetricsUpdates(repository);

      receiveProjectMetricsUpdates(const ProjectIdParam('projectId'));

      verify(
        repository.latestProjectBuildsStream(any, expectedBuildsToLoad),
      ).called(equals(1));
    });

    test("subscribes to last successful build", () {
      final repository = _MetricsRepositoryMock();

      when(repository.latestProjectBuildsStream(any, any))
          .thenAnswer((_) => emptyBuildsStream);
      when(repository.lastSuccessfulBuildStream(any))
          .thenAnswer((_) => emptyBuildsStream);
      when(repository.projectBuildsFromDateStream(any, any))
          .thenAnswer((_) => emptyBuildsStream);

      final receiveProjectMetricsUpdates =
          ReceiveProjectMetricsUpdates(repository);

      receiveProjectMetricsUpdates(const ProjectIdParam('projectId'));

      verify(
        repository.lastSuccessfulBuildStream(any),
      ).called(equals(1));
    });

    test(
      "loads the build result metric for number of builds to load for chart metrics",
      () async {
        final builds = List.generate(
          numberOfBuildsToGenerate,
          (index) => Build(
            id: '$index',
            startedAt: DateTime.now()
                .subtract(Duration(days: numberOfBuildsToGenerate - index)),
            duration: const Duration(minutes: 10),
            coverage: Percent(0.5),
            buildStatus: BuildStatus.successful,
          ),
        );

        final repository = _MetricsRepositoryStub(builds: builds);

        final lastBuilds = builds.sublist(builds.length - expectedBuildsToLoad);

        final buildResults = lastBuilds
            .map((build) => BuildResult(
                  date: build.startedAt,
                  duration: build.duration,
                  buildStatus: build.buildStatus,
                  url: build.url,
                ))
            .toList();

        final receiveMetricUpdates = ReceiveProjectMetricsUpdates(repository);

        final metricsStream =
            receiveMetricUpdates(const ProjectIdParam(projectId));

        final metrics =
            await metricsStream.firstWhere((metrics) => metrics != null);

        expect(
          metrics.buildResultMetrics.buildResults,
          equals(buildResults),
        );
      },
    );

    test(
      "loads the stability metric for number of builds to load for chart metrics",
      () async {
        final buildStatuses = BuildStatus.values.toList();
        final builds = List<Build>.generate(
          numberOfBuildsToGenerate,
          (index) {
            return Build(
              id: '${index + 1}',
              startedAt: DateTime.now().subtract(const Duration(days: 1)),
              duration: const Duration(minutes: 1),
              coverage: Percent(0.1),
              buildStatus: (buildStatuses..shuffle()).first,
            );
          },
        );

        final repository = _MetricsRepositoryStub(builds: builds);

        final lastBuilds = builds.sublist(builds.length - expectedBuildsToLoad);
        final successfulBuilds = lastBuilds.where(
          (build) => build.buildStatus == BuildStatus.successful,
        );
        final expectedStabilityMetric =
            Percent(successfulBuilds.length / lastBuilds.length);

        final receiveProjectMetricsUpdates =
            ReceiveProjectMetricsUpdates(repository);

        final metricsStream =
            receiveProjectMetricsUpdates(const ProjectIdParam(projectId));

        final metrics =
            await metricsStream.firstWhere((metrics) => metrics != null);
        final actualStabilityMetric = metrics.stability;

        expect(actualStabilityMetric, equals(expectedStabilityMetric));
      },
    );

    test("loads the build number metric for common builds loading period", () {
      final actualBuildNumberMetrics = projectMetrics.buildNumberMetrics;

      final periodStartDate = DateTime.now().subtract(expectedLoadingPeriod);

      final buildsInPeriod = builds
          .where((element) => element.startedAt.isAfter(periodStartDate))
          .toList();

      final expectedBuildNumberMetric = BuildNumberMetric(
        numberOfBuilds: buildsInPeriod.length,
      );

      expect(actualBuildNumberMetrics, equals(expectedBuildNumberMetric));
    });

    test("loads the performance metric for common builds loading period", () {
      final actualPerformanceMetric = projectMetrics.performanceMetrics;

      final periodStartDate = DateTime.now().subtract(expectedLoadingPeriod);

      final buildsInPeriod = builds
          .where((build) => build.startedAt.isAfter(periodStartDate))
          .toList();

      final buildsPerformance = buildsInPeriod.map((build) => BuildPerformance(
            date: build.startedAt,
            duration: build.duration,
          ));

      final averageDuration = buildsInPeriod.fold<Duration>(
              const Duration(), (value, element) => value + element.duration) ~/
          buildsInPeriod.length;

      final expectedBuildNumberMetric = PerformanceMetric(
        buildsPerformance: DateTimeSet.from(buildsPerformance),
        averageBuildDuration: averageDuration,
      );

      expect(
        actualPerformanceMetric.buildsPerformance.length,
        equals(expectedBuildNumberMetric.buildsPerformance.length),
      );

      expect(
        actualPerformanceMetric.averageBuildDuration,
        equals(expectedBuildNumberMetric.averageBuildDuration),
      );
    });

    test("loads all fields in the performance metrics", () {
      final performanceMetrics = projectMetrics.performanceMetrics;
      final firstPerformanceMetric = performanceMetrics.buildsPerformance.last;

      final periodStartDate = DateTime.now().subtract(expectedLoadingPeriod);

      final buildsInPeriod = builds
          .where((element) => element.startedAt.isAfter(periodStartDate))
          .toList();

      expect(
        performanceMetrics.buildsPerformance.length,
        buildsInPeriod.length,
      );

      expect(
        firstPerformanceMetric.date,
        lastBuild.startedAt,
      );
      expect(
        firstPerformanceMetric.duration,
        lastBuild.duration,
      );
    });

    test("loads build number metric", () {
      final timestamp = DateTime.now();
      final buildsLoadingStartDate =
          timestamp.subtract(expectedLoadingPeriod).date;
      final thisWeekBuilds = builds
          .where((build) => build.startedAt.isAfter(buildsLoadingStartDate));

      final totalNumberOfBuilds = thisWeekBuilds.length;
      final buildNumberMetrics = projectMetrics.buildNumberMetrics;

      expect(buildNumberMetrics.numberOfBuilds, totalNumberOfBuilds);
    });

    test("loads all fields in the build result metrics", () {
      final buildResultMetrics = projectMetrics.buildResultMetrics;

      final firstBuildResult = buildResultMetrics.buildResults.last;

      expect(firstBuildResult.buildStatus, lastBuild.buildStatus);
      expect(firstBuildResult.duration, lastBuild.duration);
      expect(firstBuildResult.date, lastBuild.startedAt);
      expect(firstBuildResult.url, lastBuild.url);
    });

    test("loads coverage from last successful build", () {
      final actualCoverage = projectMetrics.coverage;
      final expectedCoverage =
          _MetricsRepositoryStub.lastSuccessfulBuild.coverage;

      expect(actualCoverage, expectedCoverage);
    });

    test("loads the project build status metric", () {
      final expectedProjectBuildStatus = ProjectBuildStatusMetric(
        status: _MetricsRepositoryStub.testBuilds.last.buildStatus,
      );
      final actualProjectBuildStatus = projectMetrics.projectBuildStatusMetric;

      expect(actualProjectBuildStatus, expectedProjectBuildStatus);
    });

    test("calculates stability metric", () {
      final actualStability = projectMetrics.stability;

      final successfulBuilds =
          builds.where((build) => build.buildStatus == BuildStatus.successful);
      final expectedStabilityValue = successfulBuilds.length / builds.length;

      expect(actualStability.value, expectedStabilityValue);
    });

    test(
      "creates empty project metrics if project has no builds",
      () async {
        final repository = _MetricsRepositoryStub(builds: []);
        final projectMetricsUpdates = ReceiveProjectMetricsUpdates(repository);
        final projectMetricsStream = projectMetricsUpdates(
          const ProjectIdParam(projectId),
        );
        final projectMetrics = await projectMetricsStream.first;

        const expectedProjectMetrics = DashboardProjectMetrics(
          projectId: projectId,
        );

        expect(projectMetrics, equals(expectedProjectMetrics));
      },
    );

    test(
      "creates project metrics with null coverage if there are no successful builds",
      () async {
        final builds = [
          Build(
            id: '1',
            startedAt: DateTime.now(),
            buildStatus: BuildStatus.failed,
            duration: const Duration(minutes: 10),
            coverage: Percent(0.4),
          ),
          Build(
            id: '2',
            startedAt: DateTime.now(),
            buildStatus: BuildStatus.unknown,
            duration: const Duration(minutes: 3),
            coverage: Percent(0.2),
          ),
        ];

        final repository = _MetricsRepositoryStub(builds: builds);
        final projectMetricsUpdates = ReceiveProjectMetricsUpdates(repository);
        final projectMetricsStream = projectMetricsUpdates(
          const ProjectIdParam(projectId),
        );
        final projectMetrics = await projectMetricsStream.first;

        expect(projectMetrics.coverage, isNull);
      },
    );
  });
}

/// A stub implementation of [MetricsRepository] used in tests.
class _MetricsRepositoryStub implements MetricsRepository {
  /// A last successful build used in tests.
  static final Build lastSuccessfulBuild = Build(
    id: '2',
    startedAt: DateTime.now().subtract(const Duration(days: 1)),
    duration: const Duration(minutes: 6),
    coverage: Percent(0.1),
    buildStatus: BuildStatus.unknown,
  );

  /// A test [Build]s used in tests.
  static final List<Build> testBuilds = [
    Build(
      id: '1',
      startedAt: DateTime.now(),
      duration: const Duration(minutes: 10),
      coverage: Percent(0.1),
      buildStatus: BuildStatus.failed,
    ),
    lastSuccessfulBuild,
    Build(
      id: '3',
      startedAt: DateTime.now().subtract(const Duration(days: 2)),
      duration: const Duration(minutes: 3),
      coverage: Percent(0.1),
      buildStatus: BuildStatus.successful,
    ),
    Build(
      id: '4',
      startedAt: DateTime.now().subtract(const Duration(days: 3)),
      duration: const Duration(minutes: 8),
      coverage: Percent(0.1),
      buildStatus: BuildStatus.failed,
    ),
    Build(
      id: '5',
      startedAt: DateTime.now().subtract(const Duration(days: 4)),
      duration: const Duration(minutes: 12),
      coverage: Percent(0.1),
      buildStatus: BuildStatus.failed,
    ),
    Build(
      id: '6',
      startedAt: DateTime.now().subtract(const Duration(days: 8)),
      duration: const Duration(minutes: 12),
      coverage: Percent(0.1),
      buildStatus: BuildStatus.failed,
    ),
  ];

  /// A list of [Build]s used in this stub.
  List<Build> _builds;

  /// Creates a new instance of this stub.
  _MetricsRepositoryStub({List<Build> builds}) {
    _builds = builds ?? testBuilds;
  }

  @override
  Stream<List<Build>> latestProjectBuildsStream(String projectId, int limit) {
    List<Build> latestBuilds = _builds;

    if (latestBuilds.length > limit) {
      latestBuilds = latestBuilds.sublist(0, limit);
    }

    return Stream.value(latestBuilds);
  }

  @override
  Stream<List<Build>> projectBuildsFromDateStream(
      String projectId, DateTime from) {
    return Stream.value(
        _builds.where((build) => build.startedAt.isAfter(from)).toList());
  }

  @override
  Stream<List<Build>> lastSuccessfulBuildStream(String projectId) {
    final lastSuccessfulBuild = _builds.firstWhere(
      (build) => build.buildStatus == BuildStatus.successful,
      orElse: () => null,
    );

    if (lastSuccessfulBuild == null) return Stream.value([]);

    return Stream.value([lastSuccessfulBuild]);
  }
}

class _MetricsRepositoryMock extends Mock implements MetricsRepository {}
