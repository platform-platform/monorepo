// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:io';

import 'package:api_mock_server/api_mock_server.dart';
import 'package:ci_integration/client/jenkins/constants/jenkins_constants.dart';
import 'package:ci_integration/client/jenkins/constants/tree_query.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build_artifact.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build_result.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_building_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_multi_branch_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_query_limits.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_user.dart';

import '../../../test_utils/mock_server_utils.dart';

/// A mock server for the Jenkins API.
class JenkinsMockServer extends ApiMockServer {
  @override
  List<RequestHandler> get handlers => [
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: _multiBranchJobResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/name/${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: MockServerUtils.notFoundResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/1${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: _buildResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/2${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: MockServerUtils.notFoundResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/job/master${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: _buildingJobResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/job/dev${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: MockServerUtils.notFoundResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/job/master/1${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: _artifactsResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/job/master/10${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: MockServerUtils.notFoundResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/job/master/1/artifact/coverage/coverage.json',
          ),
          dispatcher: _artifactContentResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/job/test/job/master/1/artifact/coverage/test.json',
          ),
          dispatcher: MockServerUtils.notFoundResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/login',
          ),
          dispatcher: _jenkinsVersionResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/not-found/login',
          ),
          dispatcher: MockServerUtils.notFoundResponse,
        ),
        RequestHandler.get(
          pathMatcher: ExactPathMatcher(
            '/me${JenkinsConstants.jsonApiPath}',
          ),
          dispatcher: _jenkinsUserResponse,
        ),
      ];

  @override
  List<AuthCredentials> get authCredentials => const [
        AuthCredentials(token: 'test'),
      ];

  /// Creates [JenkinsMultiBranchJob] instance.
  ///
  /// If [hasJobs] is `true` than populates resulting object with a list of
  /// [JenkinsJob]s. Otherwise, a list of jobs is empty. Defaults to `false`.
  /// If [hasJobs] and [limits] is not `null` then applies limits to the list
  /// of jobs.
  JenkinsMultiBranchJob _buildMultiBranchJob({
    bool hasJobs = false,
    JenkinsQueryLimits limits,
  }) {
    if (hasJobs) {
      final jobsList = [
        _buildBuildingJob(),
      ];

      return JenkinsMultiBranchJob(
        name: 'test',
        fullName: 'test',
        jobs: limits == null
            ? jobsList
            : jobsList.sublist(
                limits.lower, limits.upper == 0 ? 0 : limits.upper - 1),
      );
    } else {
      return const JenkinsMultiBranchJob(
        name: 'test',
        fullName: 'test',
        jobs: [],
      );
    }
  }

  /// Creates [JenkinsBuildingJob] instance.
  ///
  /// If [hasBuilds] is `true` than populates resulting object with a list of
  /// [JenkinsBuild]s. Otherwise, a list of builds is empty. Defaults to `false`.
  /// If [hasBuilds] and [limits] is not `null` then applies limits to the list
  /// of builds.
  JenkinsBuildingJob _buildBuildingJob({
    bool hasBuilds = false,
    JenkinsQueryLimits limits,
  }) {
    if (hasBuilds) {
      final firstBuild = JenkinsBuild(
        number: 1,
        url: '$url/1',
        duration: const Duration(),
        timestamp: DateTime(2000),
        result: JenkinsBuildResult.failure,
        artifacts: const [],
      );
      final lastBuild = JenkinsBuild(
        number: 2,
        url: '$url/2',
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

      final buildsList = [
        lastBuild,
        firstBuild,
      ];

      return JenkinsBuildingJob(
        name: 'master',
        fullName: 'test/master',
        builds: limits == null
            ? buildsList
            : buildsList.sublist(
                limits.lower, limits.upper == 0 ? 0 : limits.upper - 1),
        firstBuild: firstBuild,
        lastBuild: lastBuild,
      );
    } else {
      return const JenkinsBuildingJob(
        name: 'master',
        fullName: 'test/master',
        builds: [],
      );
    }
  }

  /// Checks whether a tree query parameter of the [request] contains [pattern].
  bool _treeQueryContains(HttpRequest request, Pattern pattern) {
    final requestQuery = request.uri.queryParameters['tree'];
    return requestQuery?.contains(pattern) ?? false;
  }

  /// Parses a tree query parameter of the [request] and extracts
  /// [JenkinsQueryLimits] that is placed [after] pattern.
  JenkinsQueryLimits _extractLimits(HttpRequest request, Pattern after) {
    final requestQuery = request.uri.queryParameters['tree'];
    final substring = requestQuery.replaceAll(after, '');
    final regexp = RegExp(r'\{[-\d,]+\}');
    final match = regexp.stringMatch(substring);
    return match == null ? null : JenkinsQueryLimits.fromQuery(match);
  }

  /// Responses with a [JenkinsMultiBranchJob] for the given [request].
  Future<void> _multiBranchJobResponse(HttpRequest request) async {
    JenkinsMultiBranchJob response;

    if (_treeQueryContains(request, RegExp(r'jobs\[[\w\W]+\]'))) {
      final limits = _extractLimits(request, RegExp(r'jobs\[[\w\W]+\]'));

      response = _buildMultiBranchJob(
        hasJobs: true,
        limits: limits,
      );
    } else {
      response = _buildMultiBranchJob();
    }

    await MockServerUtils.writeResponse(request, body: response);
  }

  /// Responses with a jenkins build for the given [request].
  Future<void> _buildResponse(HttpRequest request) async {
    const buildNumber = 1;
    final buildUrl = '$url/job/test/$buildNumber';
    final jenkinsBuild = JenkinsBuild(number: buildNumber, url: buildUrl);

    final response = jenkinsBuild.toJson();

    await MockServerUtils.writeResponse(request, body: response);
  }

  /// Responses with a [JenkinsBuildingJob] for the given [request].
  Future<void> _buildingJobResponse(HttpRequest request) async {
    JenkinsBuildingJob response;

    if (_treeQueryContains(request, TreeQuery.build)) {
      final limits = _extractLimits(request, 'builds[${TreeQuery.build}]');

      response = _buildBuildingJob(
        hasBuilds: true,
        limits: limits,
      );
    } else {
      response = _buildBuildingJob();
    }

    await MockServerUtils.writeResponse(request, body: response);
  }

  /// Responses with a list of [JenkinsBuildArtifact]s for the given [request].
  Future<void> _artifactsResponse(HttpRequest request) async {
    final _response = {
      'artifacts': [
        const JenkinsBuildArtifact(
          fileName: 'coverage.json',
          relativePath: 'coverage/coverage.json',
        ),
        const JenkinsBuildArtifact(
          fileName: 'file.json',
          relativePath: 'files/file.json',
        )
      ].map((art) => art.toJson()).toList(),
    };

    final limits = _extractLimits(request, 'artifacts');
    if (limits != null) {
      _response['artifacts'] = _response['artifacts']
          .sublist(limits.lower, limits.upper == 0 ? 0 : limits.upper - 1);
    }

    await MockServerUtils.writeResponse(request, body: _response);
  }

  /// Responses with artifact content for the given [request].
  Future<void> _artifactContentResponse(HttpRequest request) async {
    const artifactContent = <String, dynamic>{
      'coverage': 80,
      'total': 200,
      'pct': 40,
    };

    await MockServerUtils.writeResponse(request, body: artifactContent);
  }

  /// Responses with the Jenkins instance version in response headers
  /// and an empty body.
  Future<void> _jenkinsVersionResponse(HttpRequest request) async {
    const jenkinsVersionHeader = 'X-Jenkins';

    const headers = {jenkinsVersionHeader: '1.0'};

    await MockServerUtils.writeResponse(request, headers: headers);
  }

  /// Responses with the [JenkinsUser] for the given [request].
  Future<void> _jenkinsUserResponse(HttpRequest request) async {
    const jenkinsUser = JenkinsUser(
      name: 'name',
      authenticated: true,
      anonymous: true,
    );

    final responseBody = jenkinsUser.toJson();

    await MockServerUtils.writeResponse(request, body: responseBody);
  }
}
