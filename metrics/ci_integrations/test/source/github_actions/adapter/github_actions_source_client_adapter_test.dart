// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:ci_integration/client/github_actions/models/github_action_conclusion.dart';
import 'package:ci_integration/client/github_actions/models/workflow_run.dart';
import 'package:ci_integration/client/github_actions/models/workflow_run_artifact.dart';
import 'package:ci_integration/client/github_actions/models/workflow_run_artifacts_page.dart';
import 'package:ci_integration/client/github_actions/models/workflow_run_job.dart';
import 'package:ci_integration/client/github_actions/models/workflow_run_jobs_page.dart';
import 'package:ci_integration/client/github_actions/models/workflow_runs_page.dart';
import 'package:ci_integration/source/github_actions/adapter/github_actions_source_client_adapter.dart';
import 'package:ci_integration/util/archive/archive_helper.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/extensions/interaction_result_answer.dart';
import '../test_utils/github_actions_client_mock.dart';
import '../test_utils/test_data/github_actions_test_data_generator.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("GithubActionsSourceClientAdapter", () {
    const jobName = 'job';
    const fetchLimit = 28;
    final testData = GithubActionsTestDataGenerator(
      workflowIdentifier: 'workflow',
      jobName: jobName,
      coverageArtifactName: 'coverage-summary.json',
      coverage: Percent(0.6),
      url: 'url',
      startDateTime: DateTime(2020),
      completeDateTime: DateTime(2021),
      duration: DateTime(2021).difference(DateTime(2020)),
    );

    final archiveHelperMock = _ArchiveHelperMock();
    final archiveMock = _ArchiveMock();
    final githubActionsClientMock = GithubActionsClientMock();
    final adapter = GithubActionsSourceClientAdapter(
      githubActionsClient: githubActionsClientMock,
      archiveHelper: archiveHelperMock,
      workflowIdentifier: testData.workflowIdentifier,
      coverageArtifactName: testData.coverageArtifactName,
    );

    final coverageJson = <String, dynamic>{'pct': 0.6};
    final coverageBytes = utf8.encode(jsonEncode(coverageJson)) as Uint8List;

    final emptyWorkflowRunJobsPage = WorkflowRunJobsPage(
      page: 1,
      nextPageUrl: testData.url,
      values: const [],
    );
    final defaultRunsPage = WorkflowRunsPage(
      values: testData.generateWorkflowRunsByNumbers(
        runNumbers: [2, 1],
      ),
    );
    final defaultJobsPage = WorkflowRunJobsPage(
      values: [testData.generateWorkflowRunJob()],
    );
    final defaultArtifactsPage = WorkflowRunArtifactsPage(values: [
      WorkflowRunArtifact(name: testData.coverageArtifactName),
    ]);
    final defaultBuildData = testData.generateBuildDataByNumbers(
      buildNumbers: [2, 1],
    );
    final defaultBuild = testData.generateBuildData();
    const defaultWorkflowRun = WorkflowRun();

    final artifactsPage = WorkflowRunArtifactsPage(
      values: const [WorkflowRunArtifact()],
      nextPageUrl: testData.url,
    );

    PostExpectation<Uint8List> whenDecodeCoverage({
      Uint8List withArtifactBytes,
    }) {
      when(githubActionsClientMock.downloadRunArtifactZip(any))
          .thenSuccessWith(withArtifactBytes);

      when(archiveHelperMock.decodeArchive(withArtifactBytes))
          .thenReturn(archiveMock);

      return when(
        archiveHelperMock.getFileContent(archiveMock, 'coverage-summary.json'),
      );
    }

    PostExpectation<Future<InteractionResult<WorkflowRunArtifactsPage>>>
        whenFetchCoverage({
      WorkflowRun withWorkflowRun,
    }) {
      when(githubActionsClientMock.fetchWorkflowRunByUrl(any))
          .thenSuccessWith(withWorkflowRun);

      return when(githubActionsClientMock.fetchRunArtifacts(
        any,
        perPage: anyNamed('perPage'),
        page: anyNamed('page'),
      ));
    }

    PostExpectation<Future<InteractionResult<WorkflowRunsPage>>>
        whenFetchWorkflowRuns({
      WorkflowRunJobsPage withJobsPage,
    }) {
      when(githubActionsClientMock.fetchRunJobs(
        any,
        status: anyNamed('status'),
        perPage: anyNamed('perPage'),
        page: anyNamed('page'),
      )).thenSuccessWith(withJobsPage);

      return when(
        githubActionsClientMock.fetchWorkflowRuns(
          any,
          status: anyNamed('status'),
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        ),
      );
    }

    setUp(() {
      reset(githubActionsClientMock);
      reset(archiveHelperMock);
    });

    test(
      "throws an ArgumentError if the given Github Actions client is null",
      () {
        expect(
          () => GithubActionsSourceClientAdapter(
            githubActionsClient: null,
            archiveHelper: archiveHelperMock,
            workflowIdentifier: testData.workflowIdentifier,
            coverageArtifactName: testData.coverageArtifactName,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given archive helper is null",
      () {
        expect(
          () => GithubActionsSourceClientAdapter(
            githubActionsClient: githubActionsClientMock,
            archiveHelper: null,
            workflowIdentifier: testData.workflowIdentifier,
            coverageArtifactName: testData.coverageArtifactName,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given workflow identifier is null",
      () {
        expect(
          () => GithubActionsSourceClientAdapter(
            githubActionsClient: githubActionsClientMock,
            archiveHelper: archiveHelperMock,
            workflowIdentifier: null,
            coverageArtifactName: testData.coverageArtifactName,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given coverage artifact name is null",
      () {
        expect(
          () => GithubActionsSourceClientAdapter(
            githubActionsClient: githubActionsClientMock,
            archiveHelper: archiveHelperMock,
            workflowIdentifier: testData.workflowIdentifier,
            coverageArtifactName: null,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given parameters",
      () {
        final adapter = GithubActionsSourceClientAdapter(
          githubActionsClient: githubActionsClientMock,
          archiveHelper: archiveHelperMock,
          workflowIdentifier: testData.workflowIdentifier,
          coverageArtifactName: testData.coverageArtifactName,
        );

        expect(adapter.githubActionsClient, equals(githubActionsClientMock));
        expect(adapter.archiveHelper, equals(archiveHelperMock));
        expect(
          adapter.workflowIdentifier,
          equals(testData.workflowIdentifier),
        );
        expect(
          adapter.coverageArtifactName,
          equals(testData.coverageArtifactName),
        );
      },
    );

    test(
      ".fetchBuilds() throws an ArgumentError if the given fetch limit is 0",
      () {
        expect(
          () => adapter.fetchBuilds(jobName, 0),
          throwsArgumentError,
        );
      },
    );

    test(
      ".fetchBuilds() throws an ArgumentError if the given fetch limit is a negative number",
      () {
        expect(
          () => adapter.fetchBuilds(jobName, -1),
          throwsArgumentError,
        );
      },
    );

    test(".fetchBuilds() fetches builds", () {
      whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
          .thenSuccessWith(defaultRunsPage);

      final result = adapter.fetchBuilds(jobName, fetchLimit);

      expect(result, completion(equals(defaultBuildData)));
    });

    test(
      ".fetchBuilds() returns no more than the given fetch limit number of builds",
      () {
        const fetchLimit = 12;
        final workflowRuns = testData.generateWorkflowRunsByNumbers(
          runNumbers: List.generate(30, (index) => index),
        );

        final workflowRunsPage = WorkflowRunsPage(values: workflowRuns);

        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
            .thenSuccessWith(workflowRunsPage);

        final result = adapter.fetchBuilds(jobName, fetchLimit);

        expect(
          result,
          completion(
            hasLength(lessThanOrEqualTo(fetchLimit)),
          ),
        );
      },
    );

    test(
      ".fetchBuilds() does not fetch builds of the skipped jobs",
      () {
        final workflowRunJob = testData.generateWorkflowRunJob(
          conclusion: GithubActionConclusion.skipped,
        );

        final workflowRunJobsPage = WorkflowRunJobsPage(
          values: [workflowRunJob],
        );

        whenFetchWorkflowRuns(withJobsPage: workflowRunJobsPage)
            .thenSuccessWith(defaultRunsPage);

        final result = adapter.fetchBuilds(jobName, fetchLimit);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuilds() fetches builds using pagination for workflow run jobs",
      () {
        whenFetchWorkflowRuns(withJobsPage: emptyWorkflowRunJobsPage)
            .thenSuccessWith(defaultRunsPage);

        when(githubActionsClientMock.fetchRunJobsNext(emptyWorkflowRunJobsPage))
            .thenSuccessWith(defaultJobsPage);

        final result = adapter.fetchBuilds(jobName, fetchLimit);

        expect(result, completion(equals(defaultBuildData)));
      },
    );

    test(
      ".fetchBuilds() throws a StateError if fetching a workflow runs page fails",
      () {
        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage).thenErrorWith();

        final result = adapter.fetchBuilds(jobName, fetchLimit);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws a StateError if fetching the workflow run jobs fails",
      () {
        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
            .thenSuccessWith(defaultRunsPage);

        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        )).thenErrorWith();

        final result = adapter.fetchBuilds(jobName, fetchLimit);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws a StateError if paginating through run jobs fails",
      () {
        whenFetchWorkflowRuns(withJobsPage: emptyWorkflowRunJobsPage)
            .thenSuccessWith(defaultRunsPage);

        when(githubActionsClientMock.fetchRunJobsNext(emptyWorkflowRunJobsPage))
            .thenErrorWith();

        final result = adapter.fetchBuilds(jobName, fetchLimit);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() maps fetched builds statuses according to specification",
      () {
        const conclusions = [
          GithubActionConclusion.success,
          GithubActionConclusion.failure,
          GithubActionConclusion.timedOut,
          GithubActionConclusion.cancelled,
          GithubActionConclusion.neutral,
          GithubActionConclusion.actionRequired,
          null,
        ];

        const expectedStatuses = [
          BuildStatus.successful,
          BuildStatus.failed,
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
        ];

        final expectedBuilds = testData.generateBuildDataByStatuses(
          statuses: expectedStatuses,
        );

        final workflowRuns = testData.generateWorkflowRunsByNumbers(
          runNumbers: [1, 2, 3, 4, 5, 6, 7],
        );
        final workflowRunsPage = WorkflowRunsPage(values: workflowRuns);

        final workflowRunJobs = testData.generateWorkflowRunJobsByConclusions(
            conclusions: conclusions);

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);

        for (int i = 0; i < workflowRuns.length; ++i) {
          final run = workflowRuns[i];

          when(githubActionsClientMock.fetchRunJobs(
            run.id,
            status: anyNamed('status'),
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          )).thenSuccessWith(
            WorkflowRunJobsPage(values: [workflowRunJobs[i]]),
          );
        }

        final result = adapter.fetchBuilds(jobName, fetchLimit);

        expect(result, completion(equals(expectedBuilds)));
      },
    );

    test(
      ".fetchBuilds() maps fetched run jobs' startedAt date to the completedAt date if the startedAt date is null",
      () async {
        final completedAt = DateTime.now();
        const workflowRun = WorkflowRun(number: 1);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        final workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: null,
          completedAt: completedAt,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final startedAt = result.first.startedAt;

        expect(startedAt, equals(completedAt));
      },
    );

    test(
      ".fetchBuilds() maps fetched run jobs' startedAt date to the DateTime.now() date if the startedAt and completedAt dates are null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        const workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: null,
          completedAt: null,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          const WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuilds() maps fetched run jobs' duration to the Duration.zero if the startedAt date is null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        final workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: null,
          completedAt: DateTime.now(),
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuilds() maps fetched run jobs' duration to the Duration.zero if the completedAt date is null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        final workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: DateTime.now(),
          completedAt: null,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuilds() maps fetched run jobs' url to the empty string if the url is null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        const workflowRunJob = WorkflowRunJob(
          name: jobName,
          url: null,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          const WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final url = result.first.url;

        expect(url, equals(''));
      },
    );

    test(
      ".fetchBuildsAfter() fetches all builds after the given one",
      () {
        final runsPage = WorkflowRunsPage(
          values: testData.generateWorkflowRunsByNumbers(
            runNumbers: [4, 3, 2, 1],
          ),
        );

        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
            .thenSuccessWith(runsPage);

        final result = adapter.fetchBuildsAfter(jobName, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds with a greater run number than the given if the given number is not found",
      () {
        final runsPage = WorkflowRunsPage(
          values: testData.generateWorkflowRunsByNumbers(
            runNumbers: [7, 6, 5, 3, 2, 1],
          ),
        );

        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [7, 6, 5],
        );

        final lastBuild = testData.generateBuildData(buildNumber: 4);

        whenFetchWorkflowRuns(
          withJobsPage: defaultJobsPage,
        ).thenSuccessWith(runsPage);

        final result = adapter.fetchBuildsAfter(jobName, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() returns an empty list if there are no new builds",
      () {
        final runsPage = WorkflowRunsPage(
          values: testData.generateWorkflowRunsByNumbers(
            runNumbers: [4, 3, 2, 1],
          ),
        );

        final lastBuild = testData.generateBuildData(buildNumber: 4);

        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
            .thenSuccessWith(runsPage);

        final result = adapter.fetchBuildsAfter(jobName, lastBuild);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuildsAfter() does not fetch the skipped builds",
      () {
        const workflowRunJobsPage = WorkflowRunJobsPage(values: [
          WorkflowRunJob(conclusion: GithubActionConclusion.skipped)
        ]);

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchWorkflowRuns(withJobsPage: workflowRunJobsPage)
            .thenSuccessWith(defaultRunsPage);

        final result = adapter.fetchBuildsAfter(jobName, lastBuild);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds using pagination for workflow runs",
      () {
        final firstPage = WorkflowRunsPage(
          page: 1,
          nextPageUrl: testData.url,
          values: testData.generateWorkflowRunsByNumbers(
            runNumbers: [4, 3],
          ),
        );
        final secondPage = WorkflowRunsPage(
          page: 2,
          values: testData.generateWorkflowRunsByNumbers(
            runNumbers: [2, 1],
          ),
        );

        final firstBuild = testData.generateBuildData(buildNumber: 1);
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );

        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
            .thenSuccessWith(firstPage);

        when(githubActionsClientMock.fetchWorkflowRunsNext(firstPage))
            .thenSuccessWith(secondPage);

        final result = adapter.fetchBuildsAfter(jobName, firstBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds using pagination for run jobs",
      () {
        final runsPage = WorkflowRunsPage(
          values: testData.generateWorkflowRunsByNumbers(
            runNumbers: [4, 3, 2, 1],
          ),
        );

        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchWorkflowRuns(withJobsPage: emptyWorkflowRunJobsPage)
            .thenSuccessWith(runsPage);

        when(githubActionsClientMock.fetchRunJobsNext(emptyWorkflowRunJobsPage))
            .thenSuccessWith(defaultJobsPage);

        final result = adapter.fetchBuildsAfter(jobName, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if fetching a workflow runs page fails",
      () {
        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
            .thenSuccessWith(defaultRunsPage);

        when(githubActionsClientMock.fetchWorkflowRuns(
          any,
          status: anyNamed('status'),
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        )).thenErrorWith();

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(jobName, firstBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if paginating through workflow runs fails",
      () {
        final firstPage = WorkflowRunsPage(
          nextPageUrl: testData.url,
          values: testData.generateWorkflowRunsByNumbers(
            runNumbers: [4, 3],
          ),
        );

        whenFetchWorkflowRuns(withJobsPage: defaultJobsPage)
            .thenSuccessWith(firstPage);

        when(githubActionsClientMock.fetchWorkflowRunsNext(firstPage))
            .thenErrorWith();

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(jobName, firstBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if fetching the run job fails",
      () {
        whenFetchWorkflowRuns().thenSuccessWith(defaultRunsPage);

        when(githubActionsClientMock.fetchRunJobs(
          any,
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        )).thenErrorWith();

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(jobName, firstBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if paginating through run jobs fails",
      () {
        whenFetchWorkflowRuns(withJobsPage: emptyWorkflowRunJobsPage)
            .thenSuccessWith(defaultRunsPage);

        when(githubActionsClientMock.fetchRunJobsNext(emptyWorkflowRunJobsPage))
            .thenErrorWith();

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(jobName, firstBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds statuses according to specification",
      () {
        const conclusions = [
          GithubActionConclusion.success,
          GithubActionConclusion.failure,
          GithubActionConclusion.timedOut,
          GithubActionConclusion.cancelled,
          GithubActionConclusion.neutral,
          GithubActionConclusion.actionRequired,
          null,
        ];

        const expectedStatuses = [
          BuildStatus.successful,
          BuildStatus.failed,
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
        ];

        final expectedBuilds = testData.generateBuildDataByStatuses(
          statuses: expectedStatuses,
        );

        final workflowRuns = testData.generateWorkflowRunsByNumbers(
          runNumbers: [1, 2, 3, 4, 5, 6, 7],
        );
        final workflowRunsPage = WorkflowRunsPage(values: workflowRuns);

        final workflowRunJobs = testData.generateWorkflowRunJobsByConclusions(
            conclusions: conclusions);

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);

        for (int i = 0; i < workflowRuns.length; ++i) {
          final run = workflowRuns[i];

          when(githubActionsClientMock.fetchRunJobs(
            run.id,
            status: anyNamed('status'),
            page: anyNamed('page'),
            perPage: anyNamed('perPage'),
          )).thenSuccessWith(
            WorkflowRunJobsPage(values: [workflowRunJobs[i]]),
          );
        }

        final firstBuild = testData.generateBuildData(buildNumber: 0);

        final result = adapter.fetchBuildsAfter(jobName, firstBuild);

        expect(result, completion(equals(expectedBuilds)));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched run jobs' startedAt date to the completedAt date if the startedAt date is null",
      () async {
        final completedAt = DateTime.now();
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        final workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: null,
          completedAt: completedAt,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = await adapter.fetchBuildsAfter(
          jobName,
          firstBuild,
        );
        final startedAt = result.first.startedAt;

        expect(startedAt, equals(completedAt));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched run jobs' startedAt date to the DateTime.now() date if the startedAt and completedAt dates are null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        const workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: null,
          completedAt: null,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          const WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = await adapter.fetchBuildsAfter(
          jobName,
          firstBuild,
        );
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched run jobs' duration to the Duration.zero if the startedAt date is null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        final workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: null,
          completedAt: DateTime.now(),
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = await adapter.fetchBuildsAfter(
          jobName,
          firstBuild,
        );
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched run jobs' duration to the Duration.zero if the completedAt date is null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        final workflowRunJob = WorkflowRunJob(
          name: jobName,
          startedAt: DateTime.now(),
          completedAt: null,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = await adapter.fetchBuildsAfter(
          jobName,
          firstBuild,
        );
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched run jobs' url to the empty string if the url is null",
      () async {
        const workflowRun = WorkflowRun(number: 2);
        const workflowRunsPage = WorkflowRunsPage(values: [workflowRun]);
        const workflowRunJob = WorkflowRunJob(
          name: jobName,
          url: null,
        );

        whenFetchWorkflowRuns().thenSuccessWith(workflowRunsPage);
        when(githubActionsClientMock.fetchRunJobs(
          any,
          status: anyNamed('status'),
          page: anyNamed('page'),
          perPage: anyNamed('perPage'),
        )).thenSuccessWith(
          const WorkflowRunJobsPage(values: [workflowRunJob]),
        );

        final firstBuild = testData.generateBuildData(buildNumber: 1);

        final result = await adapter.fetchBuildsAfter(
          jobName,
          firstBuild,
        );
        final url = result.first.url;

        expect(url, equals(''));
      },
    );

    test(
      ".fetchCoverage() throws an ArgumentError if the given build is null",
      () {
        final result = adapter.fetchCoverage(null);

        expect(result, throwsArgumentError);
      },
    );

    test(
      ".fetchCoverage() fetches coverage for the given build",
      () async {
        final expectedCoverage = defaultBuild.coverage;

        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(defaultArtifactsPage);
        whenDecodeCoverage(withArtifactBytes: coverageBytes)
            .thenReturn(coverageBytes);

        final actualCoverage = await adapter.fetchCoverage(defaultBuild);

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchCoverage() returns null if fetching a workflow run for the given build returns null",
      () async {
        whenFetchCoverage(withWorkflowRun: null)
            .thenSuccessWith(defaultArtifactsPage);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() returns null if the coverage summary artifact is not found",
      () async {
        const artifactsPage = WorkflowRunArtifactsPage(
          values: [WorkflowRunArtifact(name: 'test.json')],
        );
        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(artifactsPage);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() does not download any artifacts if the coverage summary artifact is not found",
      () async {
        const artifactsPage = WorkflowRunArtifactsPage(
          values: [WorkflowRunArtifact(name: 'test.json')],
        );

        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(artifactsPage);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
        verifyNever(githubActionsClientMock.downloadRunArtifactZip(any));
      },
    );

    test(
      ".fetchCoverage() returns null if an artifact archive does not contain the coverage summary json",
      () async {
        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(defaultArtifactsPage);
        whenDecodeCoverage(withArtifactBytes: coverageBytes).thenReturn(null);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() fetches coverage using pagination for run artifacts",
      () async {
        final expectedCoverage = defaultBuild.coverage;

        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(artifactsPage);
        whenDecodeCoverage(withArtifactBytes: coverageBytes)
            .thenReturn(coverageBytes);
        when(githubActionsClientMock.fetchRunArtifactsNext(artifactsPage))
            .thenSuccessWith(defaultArtifactsPage);

        final actualCoverage = await adapter.fetchCoverage(defaultBuild);

        expect(actualCoverage, equals(expectedCoverage));
        verify(
          githubActionsClientMock.fetchRunArtifactsNext(artifactsPage),
        ).called(1);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if fetching a workflow run fails for the given build",
      () {
        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(artifactsPage);
        when(githubActionsClientMock.fetchWorkflowRunByUrl(any))
            .thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if fetching the coverage artifact fails",
      () {
        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun).thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if paginating through coverage artifacts fails",
      () {
        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(artifactsPage);
        when(githubActionsClientMock.fetchRunArtifactsNext(artifactsPage))
            .thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if downloading an artifact archive fails",
      () {
        whenFetchCoverage(withWorkflowRun: defaultWorkflowRun)
            .thenSuccessWith(defaultArtifactsPage);
        when(githubActionsClientMock.downloadRunArtifactZip(any))
            .thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".dispose() closes the Github Actions client",
      () {
        adapter.dispose();

        verify(githubActionsClientMock.close()).called(1);
      },
    );
  });
}

class _ArchiveHelperMock extends Mock implements ArchiveHelper {}

class _ArchiveMock extends Mock implements Archive {}
