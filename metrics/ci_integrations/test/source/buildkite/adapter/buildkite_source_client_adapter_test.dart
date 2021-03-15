// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ci_integration/client/buildkite/models/buildkite_artifact.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_artifacts_page.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_build.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_build_state.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_builds_page.dart';
import 'package:ci_integration/source/buildkite/adapter/buildkite_source_client_adapter.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/extensions/interaction_result_answer.dart';
import '../../../test_utils/matchers.dart';
import '../test_utils/buildkite_client_mock.dart';
import '../test_utils/test_data/buildkite_test_data_generator.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("BuildkiteSourceClientAdapter", () {
    const pipelineSlug = "pipelineSlug";
    final testData = BuildkiteTestDataGenerator(
      pipelineSlug: pipelineSlug,
      coverage: Percent(0.5),
      webUrl: 'url',
      startedAt: DateTime(2020),
      finishedAt: DateTime(2021),
      duration: DateTime(2021).difference(DateTime(2020)),
    );

    const fetchLimit = 20;

    final buildkiteClientMock = BuildkiteClientMock();
    final adapter = BuildkiteSourceClientAdapter(
      buildkiteClient: buildkiteClientMock,
    );

    const coverageJson = <String, dynamic>{'pct': 0.5};
    final coverageBytes = utf8.encode(jsonEncode(coverageJson)) as Uint8List;

    const defaultArtifactsPage = BuildkiteArtifactsPage(values: [
      BuildkiteArtifact(filename: "coverage-summary.json"),
    ]);
    final emptyArtifactsPage = BuildkiteArtifactsPage(
      page: 1,
      nextPageUrl: testData.webUrl,
      values: const [],
    );
    final defaultBuildsPage = BuildkiteBuildsPage(
      values: testData.generateBuildkiteBuildsByNumbers(
        buildNumbers: [2, 1],
      ),
    );
    final defaultBuildData = testData.generateBuildDataByNumbers(
      buildNumbers: [2, 1],
    );
    final defaultBuild = testData.generateBuildData();

    PostExpectation<Future<InteractionResult<BuildkiteBuildsPage>>>
        whenFetchBuilds() {
      return when(
        buildkiteClientMock.fetchBuilds(
          pipelineSlug,
          state: BuildkiteBuildState.finished,
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        ),
      );
    }

    PostExpectation<Future<InteractionResult<BuildkiteArtifactsPage>>>
        whenFetchCoverage() {
      when(
        buildkiteClientMock.downloadArtifact(any),
      ).thenSuccessWith(coverageBytes);

      return when(
        buildkiteClientMock.fetchArtifacts(
          defaultBuild.workflowName,
          defaultBuild.buildNumber,
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        ),
      );
    }

    setUp(() {
      reset(buildkiteClientMock);
    });

    test("throws an ArgumentError if the given Buildkite client is null", () {
      expect(
        () => BuildkiteSourceClientAdapter(buildkiteClient: null),
        throwsArgumentError,
      );
    });

    test("creates an instance with the given parameters", () {
      final adapter = BuildkiteSourceClientAdapter(
        buildkiteClient: buildkiteClientMock,
      );

      expect(adapter.buildkiteClient, equals(buildkiteClientMock));
    });

    test(
      ".fetchBuilds() throws an ArgumentError if the given fetch limit is 0",
      () {
        expect(
          () => adapter.fetchBuilds(pipelineSlug, 0),
          throwsArgumentError,
        );
      },
    );

    test(
      ".fetchBuilds() throws an ArgumentError if the given fetch limit is a negative number",
      () {
        expect(
          () => adapter.fetchBuilds(pipelineSlug, -1),
          throwsArgumentError,
        );
      },
    );

    test(".fetchBuilds() fetches builds", () {
      whenFetchBuilds().thenSuccessWith(defaultBuildsPage);

      final result = adapter.fetchBuilds(pipelineSlug, fetchLimit);

      expect(result, completion(equals(defaultBuildData)));
    });

    test(
      ".fetchBuilds() returns no more than the given fetch limit number of builds",
      () {
        final builds = testData.generateBuildkiteBuildsByNumbers(
          buildNumbers: List.generate(30, (index) => index),
        );
        final buildsPage = BuildkiteBuildsPage(values: builds);

        whenFetchBuilds().thenSuccessWith(buildsPage);

        final result = adapter.fetchBuilds(pipelineSlug, fetchLimit);

        expect(
          result,
          completion(hasLength(lessThanOrEqualTo(fetchLimit))),
        );
      },
    );

    test(".fetchBuilds() skips blocked builds", () {
      final build = testData.generateBuildkiteBuild(blocked: true);
      final buildsPage = BuildkiteBuildsPage(values: [build]);

      whenFetchBuilds().thenSuccessWith(buildsPage);

      final result = adapter.fetchBuilds(pipelineSlug, fetchLimit);

      expect(result, completion(isEmpty));
    });

    test(
      ".fetchBuilds() fetches builds using pagination for builds",
      () async {
        final firstPage = BuildkiteBuildsPage(
          page: 1,
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [1],
          ),
        );
        final secondPage = BuildkiteBuildsPage(
          page: 2,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [2],
          ),
        );
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [1, 2],
        );

        whenFetchBuilds().thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage))
            .thenSuccessWith(secondPage);

        final result = adapter.fetchBuilds(pipelineSlug, fetchLimit);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuilds() throws a StateError if fetching a builds page fails",
      () {
        whenFetchBuilds().thenErrorWith();

        final result = adapter.fetchBuilds(pipelineSlug, fetchLimit);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws a StateError if paginating through builds fails",
      () {
        final firstPage = BuildkiteBuildsPage(
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [1],
          ),
        );

        whenFetchBuilds().thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage)).thenErrorWith();

        final result = adapter.fetchBuilds(
          pipelineSlug,
          fetchLimit,
        );

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() maps fetched builds states according to the specification",
      () {
        const states = [
          BuildkiteBuildState.passed,
          BuildkiteBuildState.failed,
          BuildkiteBuildState.canceled,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.scheduled,
          BuildkiteBuildState.blocked,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.finished,
          BuildkiteBuildState.running,
          BuildkiteBuildState.skipped,
          null,
        ];

        const expectedStates = [
          BuildStatus.successful,
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
        ];

        final expectedBuilds = testData.generateBuildDataByStates(
          states: expectedStates,
        );

        final builds = testData.generateBuildkiteBuildsByStates(
          states: states,
        );

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: builds));

        final result = adapter.fetchBuilds(pipelineSlug, fetchLimit);

        expect(result, completion(equals(expectedBuilds)));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' difference between the startedAt and finishedAt dates to the duration",
      () async {
        final build = testData.generateBuildkiteBuild();
        final start = build.startedAt;
        final finish = build.finishedAt;
        final expectedDuration = finish.difference(start);

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(
          pipelineSlug,
          fetchLimit,
        );
        final duration = result.first.duration;

        expect(duration, equals(expectedDuration));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the startedAt date is null",
      () async {
        final build = BuildkiteBuild(
          blocked: false,
          startedAt: null,
          finishedAt: DateTime.now(),
        );

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(
          pipelineSlug,
          fetchLimit,
        );
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the finishedAt date is null",
      () async {
        final build = BuildkiteBuild(
          blocked: false,
          startedAt: DateTime.now(),
          finishedAt: null,
        );

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(
          pipelineSlug,
          fetchLimit,
        );
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' url to the empty string if the url is null",
      () async {
        const build = BuildkiteBuild(
          blocked: false,
          webUrl: null,
        );

        whenFetchBuilds()
            .thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(
          pipelineSlug,
          fetchLimit,
        );
        final url = result.first.url;

        expect(url, equals(''));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' startedAt date to the finishedAt date if the startedAt date is null",
      () async {
        final finishedAt = DateTime.now();
        final build = BuildkiteBuild(
          blocked: false,
          startedAt: null,
          finishedAt: finishedAt,
        );

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(
          pipelineSlug,
          fetchLimit,
        );
        final startedAt = result.first.startedAt;

        expect(startedAt, equals(finishedAt));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds' startedAt date to the DateTime.now() date if the startedAt and finishedAt dates are null",
      () async {
        const build = BuildkiteBuild(
          blocked: false,
          startedAt: null,
          finishedAt: null,
        );

        whenFetchBuilds()
            .thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuilds(
          pipelineSlug,
          fetchLimit,
        );
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuildsAfter() throws an ArgumentError if the build is null",
      () {
        final result = adapter.fetchBuildsAfter(pipelineSlug, null);

        expect(result, throwsArgumentError);
      },
    );

    test(
      ".fetchBuildsAfter() fetches all builds after the given one",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );

        whenFetchBuilds().thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds with a greater build number than the given if the given number is not found",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 4);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [7, 6, 5, 3, 2, 1],
          ),
        );
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [7, 6, 5],
        );

        whenFetchBuilds().thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() returns an empty list if there are no new builds",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 4);
        final buildsPage = BuildkiteBuildsPage(
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3, 2, 1],
          ),
        );

        whenFetchBuilds().thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuildsAfter() skips the blocked builds",
      () {
        final build = testData.generateBuildkiteBuild(number: 2, blocked: true);
        final buildsPage = BuildkiteBuildsPage(values: [build]);
        final lastBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds().thenSuccessWith(buildsPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds using pagination for buildkite builds",
      () {
        final firstBuild = testData.generateBuildData(buildNumber: 1);
        final expected = testData.generateBuildDataByNumbers(
          buildNumbers: [4, 3, 2],
        );
        final firstPage = BuildkiteBuildsPage(
          page: 1,
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3],
          ),
        );
        final secondPage = BuildkiteBuildsPage(
          page: 2,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [2, 1],
          ),
        );

        whenFetchBuilds().thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage))
            .thenSuccessWith(secondPage);

        final result = adapter.fetchBuildsAfter(pipelineSlug, firstBuild);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if fetching a builds page fails",
      () {
        whenFetchBuilds().thenSuccessWith(defaultBuildsPage);

        when(buildkiteClientMock.fetchBuilds(
          any,
          state: anyNamed('state'),
          perPage: anyNamed('perPage'),
          page: anyNamed('page'),
        )).thenErrorWith();

        final lastBuild = testData.generateBuildData(buildNumber: 1);

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if paginating through Buildkite builds fails",
      () {
        final lastBuild = testData.generateBuildData(buildNumber: 1);
        final firstPage = BuildkiteBuildsPage(
          nextPageUrl: testData.webUrl,
          values: testData.generateBuildkiteBuildsByNumbers(
            buildNumbers: [4, 3],
          ),
        );

        whenFetchBuilds().thenSuccessWith(firstPage);

        when(buildkiteClientMock.fetchBuildsNext(firstPage)).thenErrorWith();

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds states according to the specification",
      () {
        const states = [
          BuildkiteBuildState.passed,
          BuildkiteBuildState.failed,
          BuildkiteBuildState.canceled,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.scheduled,
          BuildkiteBuildState.blocked,
          BuildkiteBuildState.notRun,
          BuildkiteBuildState.finished,
          BuildkiteBuildState.running,
          BuildkiteBuildState.skipped,
          null,
        ];

        const expectedStates = [
          BuildStatus.successful,
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
        ];

        final expectedBuilds = testData.generateBuildDataByStates(
          states: expectedStates,
        );

        final builds = testData.generateBuildkiteBuildsByStates(
          states: states,
        );
        final lastBuild = testData.generateBuildData(buildNumber: 0);

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: builds));

        final result = adapter.fetchBuildsAfter(pipelineSlug, lastBuild);

        expect(result, completion(equals(expectedBuilds)));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' difference between the startedAt and finishedAt dates to the duration",
      () async {
        final firstBuild = testData.generateBuildData(buildNumber: 1);
        final build = testData.generateBuildkiteBuild(number: 2);
        final start = build.startedAt;
        final finish = build.finishedAt;
        final expectedDuration = finish.difference(start);

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final duration = result.first.duration;

        expect(duration, equals(expectedDuration));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the startedAt date is null",
      () async {
        final build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: null,
          finishedAt: DateTime.now(),
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' difference between the startedAt and finishedAt dates to the Duration.zero if the finishedAt date is null",
      () async {
        final build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: DateTime.now(),
          finishedAt: null,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' startedAt date to the DateTime.now() date if the startedAt and finishedAt dates are null",
      () async {
        const build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: null,
          finishedAt: null,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds()
            .thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' url to an empty string if the url is null",
      () async {
        const build = BuildkiteBuild(
          number: 2,
          blocked: false,
          webUrl: null,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds()
            .thenSuccessWith(const BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final url = result.first.url;

        expect(url, equals(''));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds' startedAt date to the finishedAt date if the startedAt date is null",
      () async {
        final finishedAt = DateTime.now();
        final build = BuildkiteBuild(
          number: 2,
          blocked: false,
          startedAt: null,
          finishedAt: finishedAt,
        );
        final firstBuild = testData.generateBuildData(buildNumber: 1);

        whenFetchBuilds().thenSuccessWith(BuildkiteBuildsPage(values: [build]));

        final result = await adapter.fetchBuildsAfter(pipelineSlug, firstBuild);
        final startedAt = result.first.startedAt;

        expect(startedAt, equals(finishedAt));
      },
    );

    test(
      ".fetchCoverage() throws an ArgumentError if the given build is null",
      () {
        final result = adapter.fetchCoverage(null);

        expect(result, throwsArgumentError);
      },
    );

    test(".fetchCoverage() fetches coverage for the given build", () async {
      whenFetchCoverage().thenSuccessWith(defaultArtifactsPage);

      final result = await adapter.fetchCoverage(defaultBuild);

      expect(result, isNotNull);
    });

    test(
      ".fetchCoverage() returns null if the coverage summary artifact does not exist",
      () async {
        const artifactsPage = BuildkiteArtifactsPage(
          values: [BuildkiteArtifact(filename: 'test.json')],
        );

        whenFetchCoverage().thenSuccessWith(artifactsPage);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() does not download any artifacts if the coverage summary artifact does not exist",
      () async {
        const artifactsPage = BuildkiteArtifactsPage(
          values: [BuildkiteArtifact(filename: 'test.json')],
        );

        whenFetchCoverage().thenSuccessWith(artifactsPage);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
        verifyNever(buildkiteClientMock.downloadArtifact(any));
      },
    );

    test(
      ".fetchCoverage() returns null if an artifact bytes is null",
      () async {
        whenFetchCoverage().thenSuccessWith(defaultArtifactsPage);
        when(buildkiteClientMock.downloadArtifact(any)).thenSuccessWith(null);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() returns null if the JSON content parsing is failed",
      () async {
        const incorrectJson = "{pct : 100}";
        whenFetchCoverage().thenSuccessWith(defaultArtifactsPage);
        when(buildkiteClientMock.downloadArtifact(any)).thenSuccessWith(
          utf8.encode(incorrectJson) as Uint8List,
        );

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() fetches coverage using pagination for build artifacts",
      () async {
        const artifactsPage = BuildkiteArtifactsPage(
          values: [BuildkiteArtifact()],
          nextPageUrl: 'url',
        );
        whenFetchCoverage().thenSuccessWith(artifactsPage);
        when(buildkiteClientMock.fetchArtifactsNext(artifactsPage))
            .thenSuccessWith(defaultArtifactsPage);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNotNull);
        verify(
          buildkiteClientMock.fetchArtifactsNext(artifactsPage),
        ).called(once);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if fetching the coverage artifact fails",
      () {
        whenFetchCoverage().thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if paginating through coverage artifacts fails",
      () {
        whenFetchCoverage().thenSuccessWith(emptyArtifactsPage);
        when(buildkiteClientMock.fetchArtifactsNext(any)).thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if downloading a coverage artifact fails",
      () {
        whenFetchCoverage().thenSuccessWith(defaultArtifactsPage);
        when(buildkiteClientMock.downloadArtifact(any)).thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(".dispose() closes the Buildkite client", () {
      adapter.dispose();

      verify(buildkiteClientMock.close()).called(once);
    });
  });
}
