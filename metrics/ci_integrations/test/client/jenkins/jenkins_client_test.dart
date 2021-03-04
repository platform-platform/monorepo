// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:io';

import 'package:ci_integration/client/jenkins/constants/jenkins_constants.dart';
import 'package:ci_integration/client/jenkins/constants/tree_query.dart';
import 'package:ci_integration/client/jenkins/jenkins_client.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build_artifact.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build_result.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_building_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_multi_branch_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_query_limits.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:test/test.dart';

import 'test_utils/mock/jenkins_mock_server.dart';
import 'test_utils/test_data/jenkins_build_test_data.dart';

void main() {
  group("JenkinsClient", () {
    final jenkinsMockServer = JenkinsMockServer();

    JenkinsBuild firstBuild;
    JenkinsBuild lastBuild;

    final authorization = ApiKeyAuthorization(
      HttpHeaders.authorizationHeader,
      'test',
    );

    JenkinsClient jenkinsClient;
    JenkinsClient unauthorizedJenkinsClient;

    setUpAll(() async {
      await jenkinsMockServer.start();

      unauthorizedJenkinsClient = JenkinsClient(
        jenkinsUrl: jenkinsMockServer.url,
      );

      jenkinsClient = JenkinsClient(
        jenkinsUrl: jenkinsMockServer.url,
        authorization: authorization,
      );

      firstBuild = JenkinsBuild(
        number: 1,
        url: '${jenkinsMockServer.url}/1',
        apiUrl: JenkinsBuildTestData.getApiUrl(jenkinsMockServer.url, 1),
        duration: const Duration(),
        timestamp: DateTime(2000),
        result: JenkinsBuildResult.failure,
        artifacts: const [],
      );

      lastBuild = JenkinsBuild(
        number: 2,
        url: '${jenkinsMockServer.url}/2',
        apiUrl: JenkinsBuildTestData.getApiUrl(jenkinsMockServer.url, 2),
        duration: const Duration(),
        timestamp: DateTime(2000),
        result: JenkinsBuildResult.success,
        artifacts: const [
          JenkinsBuildArtifact(
            fileName: 'coverage.json',
            relativePath: 'coverage/coverage.json',
          ),
        ],
      );
    });

    tearDownAll(() async {
      await jenkinsMockServer.close();
      unauthorizedJenkinsClient.close();
      jenkinsClient.close();
    });

    test(
      "throws an ArgumentError if the given URL is null",
      () {
        expect(() => JenkinsClient(jenkinsUrl: null), throwsArgumentError);
      },
    );

    test(
      "throws an ArgumentError if the given URL is empty",
      () {
        expect(() => JenkinsClient(jenkinsUrl: ''), throwsArgumentError);
      },
    );

    test(
      ".headers contain the 'content-type' header with an application-json value",
      () {
        final headers = jenkinsClient.headers;

        expect(
          headers,
          containsPair(HttpHeaders.contentTypeHeader, ContentType.json.value),
        );
      },
    );

    test(
      ".headers contain the 'accept' header with an application-json value",
      () {
        final headers = jenkinsClient.headers;

        expect(
          headers,
          containsPair(HttpHeaders.acceptHeader, ContentType.json.value),
        );
      },
    );

    test(
      ".headers contains the given additional headers",
      () {
        const expectedKey = 'test-header';
        const expectedValue = 'test-value';
        const additionalHeaders = {
          expectedKey: expectedValue,
        };

        final jenkinsClient = JenkinsClient(
          jenkinsUrl: jenkinsMockServer.url,
          headers: additionalHeaders,
        );
        final headers = jenkinsClient.headers;

        expect(headers, containsPair(expectedKey, expectedValue));
      },
    );

    test(
      ".headers include authorization related header if provided",
      () {
        final headers = jenkinsClient.headers;
        final authHeader = authorization.toMap().entries.first;

        expect(
          headers,
          containsPair(authHeader.key, authHeader.value),
        );
      },
    );

    test(
      ".headers do not include authorization related header if client is not authorized",
      () {
        final headers = unauthorizedJenkinsClient.headers;
        final expectedHeaders = {
          HttpHeaders.contentTypeHeader: ContentType.json.value,
          HttpHeaders.acceptHeader: ContentType.json.value,
        };

        expect(headers, equals(expectedHeaders));
      },
    );

    test("fails to perform requests if not authorized", () {
      final result = unauthorizedJenkinsClient
          .fetchJob('test')
          .then((result) => result.isError);

      expect(result, completion(isTrue));
    });

    test(".fetchJob() fails if a job is not found", () {
      final result =
          jenkinsClient.fetchJob('name').then((result) => result.isError);

      expect(result, completion(isTrue));
    });

    test(".fetchJob() responds with a job", () {
      final result =
          jenkinsClient.fetchJob('test').then((result) => result.result);
      const expected = JenkinsMultiBranchJob(
        name: 'test',
        fullName: 'test',
        jobs: [],
      );

      expect(result, completion(equals(expected)));
    });

    test(
      ".fetchJobByFullName() fails if a job with the given full name is not found",
      () {
        final result = jenkinsClient
            .fetchJobByFullName('test/dev')
            .then((result) => result.isError);

        expect(result, completion(isTrue));
      },
    );

    test(
      ".fetchJobByFullName() responds with a job matching the given full name",
      () {
        final result = jenkinsClient
            .fetchJobByFullName('test/master')
            .then((result) => result.result);
        const expected = JenkinsBuildingJob(
          name: 'master',
          fullName: 'test/master',
          builds: [],
        );

        expect(result, completion(equals(expected)));
      },
    );

    test(".fetchJobs() fails if a job is not found", () {
      final result =
          jenkinsClient.fetchJobs('name').then((result) => result.isError);

      expect(result, completion(isTrue));
    });

    test(
      ".fetchJobs() responds with a list of jobs",
      () {
        final result =
            jenkinsClient.fetchJobs('test').then((result) => result.result);
        const expected = [
          JenkinsBuildingJob(
            name: 'master',
            fullName: 'test/master',
            builds: [],
          ),
        ];

        expect(result, completion(equals(expected)));
      },
    );

    test(".fetchJobs() applies limits to request if provided", () {
      final result = jenkinsClient
          .fetchJobs('test', limits: JenkinsQueryLimits.endBefore(0))
          .then((result) => result.result);
      const expected = [];

      expect(result, completion(equals(expected)));
    });

    test(
      ".fetchJobsByUrl() fails if a multi-branch job is not found",
      () {
        final result = jenkinsClient
            .fetchJobsByUrl('${jenkinsMockServer.url}/job/name')
            .then((result) => result.isError);

        expect(result, completion(isTrue));
      },
    );

    test(
      ".fetchJobsByUrl() responds with a list of jobs",
      () {
        final result = jenkinsClient
            .fetchJobsByUrl('${jenkinsMockServer.url}/job/test')
            .then((result) => result.result);
        const expected = [
          JenkinsBuildingJob(
            name: 'master',
            fullName: 'test/master',
            builds: [],
          ),
        ];

        expect(result, completion(equals(expected)));
      },
    );

    test(".fetchJobsByUrl() applies limits to request if provided", () {
      final result = jenkinsClient
          .fetchJobsByUrl(
            '${jenkinsMockServer.url}/job/test',
            limits: JenkinsQueryLimits.endBefore(0),
          )
          .then((result) => result.result);
      const expected = [];

      expect(result, completion(equals(expected)));
    });

    test(".fetchBuilds() fails if a building job is not found", () {
      final result = jenkinsClient
          .fetchBuilds('test/dev')
          .then((result) => result.isError);

      expect(result, completion(isTrue));
    });

    test(
      ".fetchBuilds() responds with a building job populated with builds related data",
      () {
        final result = jenkinsClient
            .fetchBuilds('test/master')
            .then((result) => result.result);

        final expected = JenkinsBuildingJob(
          name: 'master',
          fullName: 'test/master',
          builds: [firstBuild, lastBuild],
          firstBuild: firstBuild,
          lastBuild: lastBuild,
        );

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuilds() applies limits to request if provided",
      () {
        final result = jenkinsClient
            .fetchBuilds(
              'test/master',
              limits: JenkinsQueryLimits.endAt(1),
            )
            .then((result) => result.result);

        final expected = JenkinsBuildingJob(
          name: 'master',
          fullName: 'test/master',
          builds: [lastBuild],
          firstBuild: firstBuild,
          lastBuild: lastBuild,
        );

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildByUrl() fails if a build by the given url is not found",
      () async {
        final url = '${jenkinsMockServer.url}/job/test/2';

        final result = await jenkinsClient.fetchBuildByUrl(url);

        expect(result.isError, isTrue);
      },
    );

    test(
      ".fetchBuildByUrl() fetching a build matching the given url",
      () async {
        const jenkinsBuildNumber = 1;

        final url = '${jenkinsMockServer.url}/job/test/$jenkinsBuildNumber';
        final query = 'tree=${Uri.encodeQueryComponent(TreeQuery.build)}';
        final apiUrl = '$url${JenkinsConstants.jsonApiPath}?$query';

        final result = await jenkinsClient.fetchBuildByUrl(apiUrl);

        final expected = JenkinsBuild(
          number: jenkinsBuildNumber,
          url: url,
          apiUrl: apiUrl,
        );

        expect(result.result, equals(expected));
      },
    );

    test(".fetchBuildsByUrl() fails if a building job is not found", () {
      final result = jenkinsClient
          .fetchBuildsByUrl('${jenkinsMockServer.url}/job/test/job/dev')
          .then((result) => result.isError);

      expect(result, completion(isTrue));
    });

    test(
      ".fetchBuildsByUrl() responds with a building job populated with builds related data",
      () {
        final result = jenkinsClient
            .fetchBuildsByUrl('${jenkinsMockServer.url}/job/test/job/master')
            .then((result) => result.result);

        final expected = JenkinsBuildingJob(
          name: 'master',
          fullName: 'test/master',
          builds: [firstBuild, lastBuild],
          firstBuild: firstBuild,
          lastBuild: lastBuild,
        );

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchBuildsByUrl() applies limits to request if provided",
      () {
        final result = jenkinsClient
            .fetchBuildsByUrl(
              '${jenkinsMockServer.url}/job/test/job/master',
              limits: JenkinsQueryLimits.endAt(1),
            )
            .then((result) => result.result);

        final expected = JenkinsBuildingJob(
          name: 'master',
          fullName: 'test/master',
          builds: [lastBuild],
          firstBuild: firstBuild,
          lastBuild: lastBuild,
        );

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchArtifactsByBuildUrl() fails if build with the given url is not found",
      () {
        final url = '${jenkinsMockServer.url}/job/test/job/master/10';
        final result = jenkinsClient
            .fetchArtifactsByBuildUrl(url)
            .then((result) => result.isError);

        expect(result, completion(isTrue));
      },
    );

    test(
      ".fetchArtifactsByBuildUrl() responds with a list of artifacts for the build matching given url",
      () {
        final url = '${jenkinsMockServer.url}/job/test/job/master/1';
        final result = jenkinsClient
            .fetchArtifactsByBuildUrl(url)
            .then((result) => result.result);
        const expected = [
          JenkinsBuildArtifact(
            fileName: 'coverage.json',
            relativePath: 'coverage/coverage.json',
          ),
          JenkinsBuildArtifact(
            fileName: 'file.json',
            relativePath: 'files/file.json',
          ),
        ];

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchArtifactsByBuildUrl() applies limits to request if provided",
      () {
        final url = '${jenkinsMockServer.url}/job/test/job/master/1';
        final result = jenkinsClient
            .fetchArtifactsByBuildUrl(
              url,
              limits: JenkinsQueryLimits.endAt(1),
            )
            .then((result) => result.result);
        const expected = [
          JenkinsBuildArtifact(
            fileName: 'coverage.json',
            relativePath: 'coverage/coverage.json',
          ),
        ];

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchArtifactByRelativePath() fails if artifact is not found",
      () {
        final url = '${jenkinsMockServer.url}/job/test/job/master/10';
        final result = jenkinsClient
            .fetchArtifactByRelativePath(url, 'coverage/test.json')
            .then((result) => result.isError);

        expect(result, completion(isTrue));
      },
    );

    test(
      ".fetchArtifactByRelativePath() responds with an artifact content",
      () {
        final url = '${jenkinsMockServer.url}/job/test/job/master/1/';
        final result = jenkinsClient
            .fetchArtifactByRelativePath(url, 'coverage/coverage.json')
            .then((result) => result.result);
        const expected = <String, dynamic>{
          'coverage': 80,
          'total': 200,
          'pct': 40,
        };

        expect(result, completion(equals(expected)));
      },
    );

    test(
      ".fetchArtifact() fails if the given artifact is not found for the given build",
      () {
        final build = JenkinsBuild(
          url: '${jenkinsMockServer.url}/job/test/job/master/10',
        );
        const artifact = JenkinsBuildArtifact(
          fileName: 'test.json',
          relativePath: 'coverage/test.json',
        );
        final result = jenkinsClient
            .fetchArtifact(build, artifact)
            .then((result) => result.isError);

        expect(result, completion(isTrue));
      },
    );

    test(".fetchArtifact() responds with an artifact content", () {
      final build = JenkinsBuild(
        url: '${jenkinsMockServer.url}/job/test/job/master/1/',
      );
      const artifact = JenkinsBuildArtifact(
        fileName: 'coverage.json',
        relativePath: 'coverage/coverage.json',
      );
      final result = jenkinsClient
          .fetchArtifact(build, artifact)
          .then((result) => result.result);
      const expected = <String, dynamic>{
        'coverage': 80,
        'total': 200,
        'pct': 40,
      };

      expect(result, completion(equals(expected)));
    });

    test(
      ".fetchJenkinsInstanceInfo() throws an ArgumentError if the given jenkins url is null",
      () {
        expect(
          () => jenkinsClient.fetchJenkinsInstanceInfo(null),
          throwsArgumentError,
        );
      },
    );

    test(
      ".fetchJenkinsInstanceInfo() returns an error if the given jenkins url is not found",
      () async {
        final jenkinsUrl = '${jenkinsMockServer.url}/not_found/login';

        final interactionResult = await jenkinsClient.fetchJenkinsInstanceInfo(
          jenkinsUrl,
        );

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".fetchJenkinsInstanceInfo() returns an error if the given jenkins url does not exist",
      () async {
        final jenkinsUrl = '${jenkinsMockServer.url}/not-found';

        final interactionResult = await jenkinsClient.fetchJenkinsInstanceInfo(
          jenkinsUrl,
        );

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".fetchJenkinsInstanceInfo() returns jenkins instance info if the given jenkins url is valid",
      () async {
        final jenkinsUrl = jenkinsMockServer.url;

        final interactionResult = await jenkinsClient.fetchJenkinsInstanceInfo(
          jenkinsUrl,
        );

        final jenkinsInstanceInfo = interactionResult.result;

        expect(jenkinsInstanceInfo, isNotNull);
      },
    );

    test(
      ".fetchJenkinsUser() throws an ArgumentError if the given auth is null",
      () {
        expect(() => jenkinsClient.fetchJenkinsUser(null), throwsArgumentError);
      },
    );

    test(
      ".fetchJenkinsUser() returns an error if the given auth is not valid",
      () async {
        final auth = BearerAuthorization('invalid');

        final interactionResult = await jenkinsClient.fetchJenkinsUser(auth);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".fetchJenkinsUser() returns a jenkins user if the given auth is valid",
      () async {
        final interactionResult = await jenkinsClient.fetchJenkinsUser(
          authorization,
        );

        final jenkinsUser = interactionResult.result;

        expect(jenkinsUser, isNotNull);
      },
    );
  });
}
