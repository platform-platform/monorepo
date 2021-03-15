// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/jenkins/jenkins_client.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build_artifact.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build_result.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_building_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_query_limits.dart';
import 'package:ci_integration/source/jenkins/adapter/jenkins_source_client_adapter.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:meta/meta.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/extensions/interaction_result_answer.dart';
import '../../../test_utils/matchers.dart';
import '../test_utils/jenkins_client_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("JenkinsSourceClientAdapter", () {
    const jobName = 'test-job';
    const defaultBuildNumber = 1;
    final defaultCoverage = Percent(0.6);
    const defaultDuration = Duration(seconds: 10);
    const defaultBuildUrl = 'buildUrl';
    const defaultArtifact = JenkinsBuildArtifact(
      fileName: 'coverage-summary.json',
      relativePath: 'coverage/coverage-summary.json',
    );
    final defaultDateTime = DateTime(2020);
    final defaultArtifactContent = <String, dynamic>{
      'pct': 0.6,
    };
    final defaultBuild = BuildData(coverage: defaultCoverage);
    const defaultJenkinsBuild = JenkinsBuild(artifacts: [defaultArtifact]);

    final jenkinsClientMock = JenkinsClientMock();
    final adapter = JenkinsSourceClientAdapter(jenkinsClientMock);
    final responses = _JenkinsClientResponse(jobName);

    const fetchLimit = 20;

    PostExpectation<Future<InteractionResult>> whenFetchBuilds({
      String jobName = jobName,
      JenkinsQueryLimits limits,
    }) {
      return when(jenkinsClientMock.fetchBuilds(
        jobName,
        limits: limits ?? anyNamed('limits'),
      ));
    }

    PostExpectation<Future<InteractionResult<Map<String, dynamic>>>>
        whenFetchCoverage({
      JenkinsBuild withJenkinsBuild,
    }) {
      when(jenkinsClientMock.fetchBuildByUrl(any))
          .thenSuccessWith(withJenkinsBuild);

      return when(jenkinsClientMock.fetchArtifact(withJenkinsBuild, any));
    }

    /// Creates a [JenkinsBuild] instance with the given [buildNumber]
    /// and default build arguments.
    JenkinsBuild createJenkinsBuild({
      @required int buildNumber,
      JenkinsBuildResult result = JenkinsBuildResult.success,
      bool building = false,
      List<JenkinsBuildArtifact> artifacts = const [defaultArtifact],
    }) {
      return JenkinsBuild(
        number: buildNumber,
        duration: defaultDuration,
        timestamp: defaultDateTime,
        result: result,
        url: defaultBuildUrl,
        building: building,
        artifacts: artifacts,
      );
    }

    /// Creates a list of [JenkinsBuild] using the given [buildNumbers].
    List<JenkinsBuild> createJenkinsBuilds({
      @required List<int> buildNumbers,
    }) {
      return buildNumbers.map((buildNumber) {
        return createJenkinsBuild(buildNumber: buildNumber);
      }).toList();
    }

    /// Creates a [BuildData] instance with the given [buildNumber]
    /// and default build arguments.
    BuildData createBuildData({
      @required int buildNumber,
      BuildStatus buildStatus = BuildStatus.successful,
    }) {
      return BuildData(
        buildNumber: buildNumber,
        startedAt: defaultDateTime,
        buildStatus: buildStatus,
        duration: defaultDuration,
        workflowName: jobName,
        url: defaultBuildUrl,
        coverage: defaultCoverage,
      );
    }

    setUp(() {
      reset(jenkinsClientMock);
      responses.reset();
    });

    test(
      ".fetchBuilds() fetches builds which are not building",
      () {
        final jenkinsBuilds = [
          createJenkinsBuild(buildNumber: 1, building: false),
          createJenkinsBuild(buildNumber: 2, building: true),
        ];
        final expected = [createBuildData(buildNumber: 1)];

        responses.addBuilds(jenkinsBuilds);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuilds() throws a StateError if a project with the given id is not found",
      () {
        whenFetchBuilds(jobName: 'test-non-job').thenAnswer(
          (_) => responses.error<JenkinsBuildingJob>(),
        );

        final result = adapter.fetchBuilds(
          'test-non-job',
          fetchLimit,
        );

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuilds() throws an ArgumentError if the given fetch limit value is less than 0",
      () {
        expect(() => adapter.fetchBuilds(jobName, -1), throwsArgumentError);
      },
    );

    test(
      ".fetchBuilds() fetches no more than the given fetch limit number of builds",
      () {
        final builds = createJenkinsBuilds(
          buildNumbers: List.generate(30, (index) => index),
        );
        responses.addBuilds(builds);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );

        expect(
          result,
          completion(hasLength(lessThanOrEqualTo(fetchLimit))),
        );
      },
    );

    test(
      ".fetchBuilds() maps fetched builds statuses according to specification",
      () async {
        const jenkinsResults = [
          JenkinsBuildResult.failure,
          JenkinsBuildResult.notBuild,
          JenkinsBuildResult.aborted,
          JenkinsBuildResult.unstable,
          JenkinsBuildResult.success,
          null,
        ];
        const expectedStatuses = [
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.successful,
          BuildStatus.unknown,
        ];
        final jenkinsBuilds = <JenkinsBuild>[];
        final expected = <BuildData>[];

        for (int i = 0;
            i < jenkinsResults.length && i < expectedStatuses.length;
            i++) {
          jenkinsBuilds.add(createJenkinsBuild(
            buildNumber: i + 1,
            result: jenkinsResults[i],
          ));
          expected.add(createBuildData(
            buildNumber: i + 1,
            buildStatus: expectedStatuses[i],
          ));
        }

        responses.addBuilds(jenkinsBuilds);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuilds() maps fetched builds startedAt date to the DateTime.now() if the timestamp is null",
      () async {
        const jenkinsBuild = JenkinsBuild(
          number: 2,
          timestamp: null,
          building: false,
          artifacts: [defaultArtifact],
        );

        responses.addBuilds([jenkinsBuild]);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuilds() maps fetched builds duration to the Duration.zero if the duration is null",
      () async {
        const jenkinsBuild = JenkinsBuild(
          number: 2,
          duration: null,
          building: false,
          artifacts: [defaultArtifact],
        );

        responses.addBuilds([jenkinsBuild]);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuilds() maps fetched url to the empty string if the url is null",
      () async {
        const jenkinsBuild = JenkinsBuild(
          number: 2,
          url: null,
          building: false,
          artifacts: [defaultArtifact],
        );

        responses.addBuilds([jenkinsBuild]);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = await adapter.fetchBuilds(
          jobName,
          fetchLimit,
        );
        final url = result.first.url;

        expect(url, equals(''));
      },
    );

    test(
      ".fetchBuildsAfter() fetches builds which are not building",
      () {
        const build = BuildData(buildNumber: 1);
        final jenkinsBuilds = [
          createJenkinsBuild(buildNumber: 1, building: false),
          createJenkinsBuild(buildNumber: 2, building: false),
          createJenkinsBuild(buildNumber: 3, building: true),
        ];
        final expected = [createBuildData(buildNumber: 2)];

        responses.addBuilds(jenkinsBuilds);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuildsAfter(jobName, build);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds statuses according to specification",
      () async {
        const startingBuildNumber = 1;
        const build = BuildData(buildNumber: startingBuildNumber);
        const jenkinsResults = [
          JenkinsBuildResult.failure,
          JenkinsBuildResult.notBuild,
          JenkinsBuildResult.aborted,
          JenkinsBuildResult.unstable,
          JenkinsBuildResult.success,
          null,
        ];
        const expectedStatuses = [
          BuildStatus.failed,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.unknown,
          BuildStatus.successful,
          BuildStatus.unknown,
        ];
        final jenkinsBuilds = <JenkinsBuild>[];
        final expected = <BuildData>[];

        for (int i = 0;
            i < jenkinsResults.length && i < expectedStatuses.length;
            i++) {
          jenkinsBuilds.add(createJenkinsBuild(
            buildNumber: i + startingBuildNumber + 1,
            result: jenkinsResults[i],
          ));
          expected.add(createBuildData(
            buildNumber: i + startingBuildNumber + 1,
            buildStatus: expectedStatuses[i],
          ));
        }

        responses.addBuilds(jenkinsBuilds);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuildsAfter(jobName, build);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() fetches new builds performed after the given build",
      () async {
        const build = BuildData(buildNumber: 2);
        final jenkinsBuilds = [
          createJenkinsBuild(buildNumber: 1),
          createJenkinsBuild(buildNumber: 2),
          createJenkinsBuild(buildNumber: 3),
        ];
        final expected = <BuildData>[
          createBuildData(buildNumber: 3),
        ];

        responses.addBuilds(jenkinsBuilds);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuildsAfter(jobName, build);

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsAfter() throws an ArgumentError if the given build is null",
      () {
        final result = adapter.fetchBuildsAfter(jobName, null);

        expect(result, throwsArgumentError);
      },
    );

    test(
      ".fetchBuildsAfter() throws a StateError if a project with the given id is not found",
      () {
        const build = BuildData(buildNumber: 1);

        whenFetchBuilds(jobName: 'test-non-job').thenAnswer(
          (_) => responses.error<JenkinsBuildingJob>(),
        );

        final result = adapter.fetchBuildsAfter('test-non-job', build);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchBuildsAfter() returns an empty list if there are no new builds",
      () {
        const build = BuildData(buildNumber: 1);
        responses.addBuilds(createJenkinsBuilds(buildNumbers: [1]));

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuildsAfter(jobName, build);

        expect(result, completion(isEmpty));
      },
    );

    test(
      ".fetchBuildsAfter() fetches new builds added during synchronization",
      () {
        const build = BuildData(buildNumber: 1);
        responses.addBuilds(createJenkinsBuilds(buildNumbers: [1, 2, 3]));
        bool additionalBuildsAdded = false;

        whenFetchBuilds().thenAnswer(
          (invocation) => responses.fetchBuilds(
            invocation,
            afterFetchCallback: additionalBuildsAdded
                ? null
                : () {
                    responses
                        .addBuilds(createJenkinsBuilds(buildNumbers: [4, 5]));
                    additionalBuildsAdded = true;
                  },
          ),
        );

        final result = adapter.fetchBuildsAfter(jobName, build);

        expect(result, completion(hasLength(4)));
      },
    );

    test(
      ".fetchBuildsAfter() returns builds if the given build has been deleted",
      () {
        const build = BuildData(buildNumber: 8);
        responses.addBuilds(createJenkinsBuilds(
          buildNumbers: [1, 3, 5, 7, 9, 11],
        ));

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = adapter.fetchBuildsAfter(jobName, build);

        expect(result, completion(hasLength(2)));
      },
    );

    test(
      ".fetchBuildsAfter() returns builds when new builds added during synchronization if the given build has been deleted",
      () {
        const build = BuildData(buildNumber: 2);
        responses.addBuilds(createJenkinsBuilds(buildNumbers: [1, 3, 5]));
        bool additionalBuildsAdded = false;

        whenFetchBuilds().thenAnswer(
          (invocation) => responses.fetchBuilds(
            invocation,
            afterFetchCallback: additionalBuildsAdded
                ? null
                : () {
                    responses.addBuilds(createJenkinsBuilds(
                      buildNumbers: [6, 7],
                    ));
                    additionalBuildsAdded = true;
                  },
          ),
        );

        final result = adapter.fetchBuildsAfter(jobName, build);

        expect(result, completion(hasLength(4)));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds startedAt date to the DateTime.now() if the timestamp is null",
      () async {
        const build = BuildData(buildNumber: 1);

        const jenkinsBuild = JenkinsBuild(
          number: 2,
          timestamp: null,
          building: false,
          artifacts: [defaultArtifact],
        );

        responses.addBuilds([jenkinsBuild]);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = await adapter.fetchBuildsAfter(jobName, build);
        final startedAt = result.first.startedAt;

        expect(startedAt, isNotNull);
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched builds duration to the Duration.zero if the duration is null",
      () async {
        const build = BuildData(buildNumber: 1);

        const jenkinsBuild = JenkinsBuild(
          number: 2,
          duration: null,
          building: false,
          artifacts: [defaultArtifact],
        );

        responses.addBuilds([jenkinsBuild]);

        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = await adapter.fetchBuildsAfter(jobName, build);
        final duration = result.first.duration;

        expect(duration, equals(Duration.zero));
      },
    );

    test(
      ".fetchBuildsAfter() maps fetched url to the empty string if the url is null",
      () async {
        const build = BuildData(buildNumber: 1);
        const jenkinsBuild = JenkinsBuild(
          number: 2,
          url: null,
          building: false,
          artifacts: [defaultArtifact],
        );

        responses.addBuilds([jenkinsBuild]);
        whenFetchBuilds().thenAnswer(responses.fetchBuilds);

        final result = await adapter.fetchBuildsAfter(jobName, build);
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
      ".fetchCoverage() fetches a coverage for the given build",
      () async {
        final expectedCoverage = defaultBuild.coverage;

        whenFetchCoverage(withJenkinsBuild: defaultJenkinsBuild)
            .thenSuccessWith(defaultArtifactContent);

        final actualCoverage = await adapter.fetchCoverage(defaultBuild);

        expect(actualCoverage, equals(expectedCoverage));
      },
    );

    test(
      ".fetchCoverage() returns null if fetching a jenkins build returns null",
      () async {
        whenFetchCoverage(withJenkinsBuild: null)
            .thenSuccessWith(defaultArtifactContent);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() returns null if the coverage summary artifact is not found",
      () async {
        final jenkinsBuild = createJenkinsBuild(
          buildNumber: defaultBuildNumber,
          artifacts: [],
        );

        whenFetchCoverage(withJenkinsBuild: jenkinsBuild)
            .thenSuccessWith(defaultArtifactContent);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() does not fetch any artifacts content if the coverage summary artifact is not found",
      () async {
        final jenkinsBuild = createJenkinsBuild(
          buildNumber: defaultBuildNumber,
          artifacts: [],
        );

        whenFetchCoverage(withJenkinsBuild: jenkinsBuild)
            .thenSuccessWith(defaultArtifactContent);

        await adapter.fetchCoverage(defaultBuild);

        verifyNever(jenkinsClientMock.fetchArtifactByRelativePath(any, any));
      },
    );

    test(
      ".fetchCoverage() returns null if an artifact content is null",
      () async {
        whenFetchCoverage(withJenkinsBuild: defaultJenkinsBuild)
            .thenSuccessWith(null);

        final result = await adapter.fetchCoverage(defaultBuild);

        expect(result, isNull);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if fetching the coverage artifact fails",
      () {
        whenFetchCoverage(withJenkinsBuild: defaultJenkinsBuild)
            .thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(
      ".fetchCoverage() throws a StateError if fetching a jenkins build fails",
      () {
        whenFetchCoverage(withJenkinsBuild: defaultJenkinsBuild)
            .thenSuccessWith(defaultArtifactContent);
        when(jenkinsClientMock.fetchBuildByUrl(any)).thenErrorWith();

        final result = adapter.fetchCoverage(defaultBuild);

        expect(result, throwsStateError);
      },
    );

    test(".dispose() closes the Jenkins client", () {
      adapter.dispose();

      verify(jenkinsClientMock.close()).called(once);
    });
  });
}

/// A class that provides methods for building [_JenkinsClientMock] responses.
class _JenkinsClientResponse {
  final String jobName;
  final List<JenkinsBuild> _builds = [];

  _JenkinsClientResponse(this.jobName);

  /// Adds the given [builds] list to the [_builds].
  void addBuilds(Iterable<JenkinsBuild> builds) {
    _builds.addAll(builds);
  }

  /// Builds the response for the [JenkinsClient.fetchBuilds] method.
  ///
  /// Uses [_builds] to create a response for the given [invocation].
  /// If [afterFetchCallback] is not null this method invokes it after a
  /// response building is finished.
  Future<InteractionResult<JenkinsBuildingJob>> fetchBuilds(
    Invocation invocation, {
    void Function() afterFetchCallback,
  }) {
    final limits =
        invocation.namedArguments[const Symbol('limits')] as JenkinsQueryLimits;

    final _result = JenkinsBuildingJob(
      name: jobName,
      fullName: jobName,
      url: 'url',
      firstBuild: _builds.first,
      lastBuild: _builds.last,
      builds: _applyLimits(limits).reversed.toList(),
    );

    if (afterFetchCallback != null) {
      afterFetchCallback();
    }

    return _wrapFuture(InteractionResult.success(result: _result));
  }

  /// Applies the given [limits] to the [_builds] list.
  List<JenkinsBuild> _applyLimits(JenkinsQueryLimits limits) {
    final _buildsToProcess = _builds.reversed.toList();

    final startIsNull = limits.lower == null;
    final startIsGreaterThanBuildsLength =
        !startIsNull && limits.lower > _buildsToProcess.length;
    final endIsNull = limits.upper == null;
    final endIsGreaterThanBuildsLength =
        !endIsNull && limits.upper > _buildsToProcess.length;

    if (startIsNull && (endIsNull || endIsGreaterThanBuildsLength)) {
      return _buildsToProcess;
    }

    if (startIsGreaterThanBuildsLength) {
      return [];
    }

    return endIsGreaterThanBuildsLength
        ? _buildsToProcess.sublist(limits.lower)
        : _buildsToProcess.sublist(limits.lower ?? 0, limits.upper);
  }

  /// Builds the response for the [JenkinsClient.fetchArtifactByRelativePath]
  /// method.
  Future<InteractionResult<Map<String, dynamic>>> artifact([_]) {
    final result = <String, dynamic>{
      'pct': 0.6,
    };
    return _wrapFuture(InteractionResult.success(result: result));
  }

  /// Builds the error response creating an [InteractionResult.error] instance.
  Future<InteractionResult<T>> error<T>() {
    return _wrapFuture(InteractionResult<T>.error());
  }

  /// Wraps the given [value] into the [Future.value].
  Future<T> _wrapFuture<T>(T value) {
    return Future.value(value);
  }

  /// Resets this [_JenkinsClientResponse] for a new test case to ensure
  /// different test cases have no hidden dependencies.
  void reset() {
    _builds.clear();
  }
}
