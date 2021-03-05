// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:ci_integration/cli/logger/mixin/logger_mixin.dart';
import 'package:ci_integration/client/github_actions/github_actions_client.dart';
import 'package:ci_integration/client/jenkins/builder/jenkins_url_builder.dart';
import 'package:ci_integration/client/jenkins/constants/tree_query.dart';
import 'package:ci_integration/client/jenkins/deserializer/jenkins_build_deserializer.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_build_artifact.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_building_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_instance_info.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_query_limits.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_user.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:ci_integration/util/url/url_utils.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

/// A callback for parsing Jenkins API response body.
typedef BodyParserCallback<T> = InteractionResult<T> Function(
  Map<String, dynamic> body,
);

/// A client for interactions with the Jenkins API.
class JenkinsClient with LoggerMixin {
  /// A [JenkinsUrlBuilder] this client uses to build API URLs.
  static const JenkinsUrlBuilder _jenkinsUrlBuilder = JenkinsUrlBuilder();

  /// The HTTP client for making requests to the Jenkins API.
  final Client _client = Client();

  /// A [Map] with HTTP headers to add to the default [headers] of this client.
  final Map<String, String> _headers;

  /// The authorization method used within HTTP requests.
  final AuthorizationBase authorization;

  /// The base URL of the Jenkins instance.
  final String jenkinsUrl;

  /// Creates an instance of [JenkinsClient] using [jenkinsUrl] and
  /// [authorization] method (see [AuthorizationBase] and implementers)
  /// provided.
  ///
  /// [jenkinsUrl] is required. Throws [ArgumentError] if it is `null` or empty.
  JenkinsClient({
    @required this.jenkinsUrl,
    this.authorization,
    Map<String, String> headers,
  }) : _headers = headers {
    if (jenkinsUrl == null || jenkinsUrl.isEmpty) {
      throw ArgumentError.value(
        jenkinsUrl,
        'jenkinsUrl',
        'must not be null or empty',
      );
    }
  }

  /// Creates basic [Map] with headers for HTTP requests.
  ///
  /// If provided authorization method is not `null` then adds the result
  /// of [AuthorizationBase.toMap] method to headers.
  Map<String, String> get headers {
    return <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.value,
      HttpHeaders.acceptHeader: ContentType.json.value,
      if (_headers != null) ..._headers,
      if (authorization != null) ...authorization.toMap(),
    };
  }

  /// Converts a [JenkinsJob]'s full name to the path to this job.
  String _jobFullNameToPath(String jobFullName) {
    return UrlUtils.replacePathSeparators(jobFullName, 'job');
  }

  /// A method for handling Jenkins-specific HTTP responses.
  ///
  /// Awaits [responseFuture] and handles the result. If either the provided
  /// future throws or [HttpResponse.statusCode] is not equal to
  /// [successStatusCode] (defaults to [HttpStatus.ok]) this method will
  /// result with [InteractionResult.error]. Otherwise, delegates processing
  /// the [Response] to the [responseProcessor] callback.
  Future<InteractionResult<T>> _handleResponse<T>(
    Future<Response> responseFuture,
    ResponseProcessingCallback<T> responseProcessor,
  ) async {
    try {
      final response = await responseFuture;

      if (response.statusCode == HttpStatus.ok) {
        final responseBody = response.body;

        final json = responseBody.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>
            : null;

        final headers = response.headers;

        return responseProcessor(json, headers);
      } else {
        final reason = response.body == null || response.body.isEmpty
            ? response.reasonPhrase
            : response.body;
        return InteractionResult.error(
          message: 'Failed to perform an operation with code '
              '${response.statusCode}. Reason: $reason',
        );
      }
    } catch (error) {
      return InteractionResult.error(
        message: 'Failed to perform an operation. Error details: $error',
      );
    }
  }

  /// Retrieves [JenkinsJob] by provided [name].
  ///
  /// If the desired job is a part of another job then the top-level job's name
  /// should be included to the [topLevelPipelines] list.
  /// [topLevelPipelines] is optional and defaults to an empty list.
  ///
  /// If the desired job's full name is known, consider to use
  /// [fetchJobByFullName] method instead.
  Future<InteractionResult<JenkinsJob>> fetchJob(
    String name, {
    List<String> topLevelPipelines = const [],
  }) {
    logger.info('Fetching job by name: $name...');
    final jobs = (topLevelPipelines ?? []).toList()..add(name);

    return _fetchJob('job/${jobs?.join('/job/')}');
  }

  /// Retrieves [JenkinsJob] by provided [fullName].
  ///
  /// A Jenkins job's full name contains all top-level jobs' names in the
  /// following form: `<top-...-top-job>/.../<top-job>/<job>`. Unlike the
  /// [fetchJob] method, this one will parse [fullName] to detect top-level
  /// jobs and build a path to the desired job.
  Future<InteractionResult<JenkinsJob>> fetchJobByFullName(String fullName) {
    logger.info('Fetching job by full name: $fullName...');

    return _fetchJob(_jobFullNameToPath(fullName));
  }

  /// Retrieves [JenkinsJob] by provided [path].
  ///
  /// Both [fetchJob] and [fetchJobByFullName] delegate fetching job to this
  /// method.
  Future<InteractionResult<JenkinsJob>> _fetchJob(String path) {
    final fullUrl = _jenkinsUrlBuilder.build(
      jenkinsUrl,
      path: path,
      treeQuery: TreeQuery.job,
    );
    logger.info('Fetching job from the url: $fullUrl');

    return _handleResponse<JenkinsJob>(
      _client.get(fullUrl, headers: headers),
      (Map<String, dynamic> json, _) {
        return InteractionResult.success(
          result: JenkinsJob.fromJson(json),
        );
      },
    );
  }

  /// Retrieves jobs for the multi-branch job by its full name.
  ///
  /// Results with a list of [JenkinsJob]s.
  /// [limits] can be used to set the fetch limits (see [JenkinsQueryLimits]) -
  /// defaults to [JenkinsQueryLimits.empty].
  Future<InteractionResult<List<JenkinsJob>>> fetchJobs(
    String multiBranchJobFullName, {
    JenkinsQueryLimits limits = const JenkinsQueryLimits.empty(),
  }) {
    logger.info(
      'Fetching jobs for the multi-branch job by name: $multiBranchJobFullName...',
    );

    final path = _jobFullNameToPath(multiBranchJobFullName);
    final url = _jenkinsUrlBuilder.build(
      jenkinsUrl,
      path: path,
      treeQuery: 'jobs[${TreeQuery.job}]${limits.toQuery()}',
    );

    return _fetchJobs(url);
  }

  /// Retrieves jobs for the multi-branch job by its url.
  ///
  /// Results with a list of [JenkinsJob]s.
  /// [limits] can be used to set the fetch limits (see [JenkinsQueryLimits]) -
  /// defaults to [JenkinsQueryLimits.empty].
  Future<InteractionResult<List<JenkinsJob>>> fetchJobsByUrl(
    String multiBranchJobUrl, {
    JenkinsQueryLimits limits = const JenkinsQueryLimits.empty(),
  }) {
    logger.info(
      'Fetching jobs for the multi-branch job by url: $multiBranchJobUrl...',
    );

    final url = _jenkinsUrlBuilder.build(
      multiBranchJobUrl,
      treeQuery: '${TreeQuery.jobBase},'
          'jobs[${TreeQuery.job}]${limits.toQuery()}',
    );

    return _fetchJobs(url);
  }

  /// Retrieves jobs for the multi-branch job by the given URL.
  ///
  /// Both [fetchJobs] and [fetchJobsByUrl] delegate fetching jobs to this
  /// method.
  Future<InteractionResult<List<JenkinsJob>>> _fetchJobs(String url) {
    logger.info('Fetching jobs from the url: $url');

    return _handleResponse<List<JenkinsJob>>(
      _client.get(url, headers: headers),
      (Map<String, dynamic> json, _) {
        final list = json == null ? null : json['jobs'] as List<dynamic>;
        return InteractionResult.success(
          result: JenkinsJob.listFromJson(list),
        );
      },
    );
  }

  /// Retrieves [JenkinsBuildingJob] with builds specified by its full name.
  ///
  /// [limits] can be used to set the fetch limits (see [JenkinsQueryLimits]) -
  /// defaults to [JenkinsQueryLimits.empty].
  Future<InteractionResult<JenkinsBuildingJob>> fetchBuilds(
    String buildingJobFullName, {
    JenkinsQueryLimits limits = const JenkinsQueryLimits.empty(),
  }) {
    logger.info('Fetching builds by job full name: $buildingJobFullName...');

    final path = _jobFullNameToPath(buildingJobFullName);
    final url = _jenkinsUrlBuilder.build(
      jenkinsUrl,
      path: path,
      treeQuery: '${TreeQuery.jobBase},'
          'builds[${TreeQuery.build}]${limits.toQuery()},'
          'lastBuild[${TreeQuery.build}],firstBuild[${TreeQuery.build}]',
    );

    return _fetchBuilds(url);
  }

  /// Retrieves [JenkinsBuildingJob] with builds specified by the given URL.
  ///
  /// [limits] can be used to set the fetch limits (see [JenkinsQueryLimits]) -
  /// defaults to [JenkinsQueryLimits.empty].
  Future<InteractionResult<JenkinsBuildingJob>> fetchBuildsByUrl(
    String buildingJobUrl, {
    JenkinsQueryLimits limits = const JenkinsQueryLimits.empty(),
  }) {
    logger.info('Fetching builds by job url: $buildingJobUrl');

    final url = _jenkinsUrlBuilder.build(
      buildingJobUrl,
      treeQuery: '${TreeQuery.jobBase},'
          'builds[${TreeQuery.build}]${limits.toQuery()},'
          'lastBuild[${TreeQuery.build}],firstBuild[${TreeQuery.build}]',
    );

    return _fetchBuilds(url);
  }

  /// Fetches a [JenkinsBuild] by the given [buildUrl].
  Future<InteractionResult<JenkinsBuild>> fetchBuildByUrl(String buildUrl) {
    logger.info('Fetching a build by the URL: $buildUrl');

    return _handleResponse<JenkinsBuild>(
      _client.get(buildUrl, headers: headers),
      (Map<String, dynamic> json, _) {
        return InteractionResult.success(
          result: JenkinsBuildDeserializer.fromJson(json),
        );
      },
    );
  }

  /// Retrieves a building job by the given URL.
  ///
  /// Both [fetchBuilds] and [fetchBuildsByUrl] delegate fetching builds to this
  /// method.
  Future<InteractionResult<JenkinsBuildingJob>> _fetchBuilds(String url) {
    logger.info('Fetching builds from the url: $url');

    return _handleResponse<JenkinsBuildingJob>(
      _client.get(url, headers: headers),
      (Map<String, dynamic> json, _) {
        final builds = json['builds'] as List<dynamic>;
        json['builds'] = builds?.reversed?.toList();

        return InteractionResult.success(
          result: JenkinsBuildingJob.fromJson(json),
        );
      },
    );
  }

  /// Retrieves a list of [JenkinsBuildArtifact]s generated during the build
  /// specified by the provided [buildUrl].
  ///
  /// [limits] can be used to set the fetch limits (see [JenkinsQueryLimits]) -
  /// defaults to [JenkinsQueryLimits.empty].
  Future<InteractionResult<List<JenkinsBuildArtifact>>>
      fetchArtifactsByBuildUrl(
    String buildUrl, {
    JenkinsQueryLimits limits = const JenkinsQueryLimits.empty(),
  }) {
    final url = _jenkinsUrlBuilder.build(
      buildUrl,
      treeQuery: 'artifacts[${TreeQuery.artifacts}]${limits.toQuery()}',
    );

    logger.info('Fetching artifacts from the url: $url');

    return _handleResponse<List<JenkinsBuildArtifact>>(
      _client.get(url, headers: headers),
      (Map<String, dynamic> json, _) => InteractionResult.success(
        result: JenkinsBuildArtifact.listFromJson(
          json['artifacts'] as List<dynamic>,
        ),
      ),
    );
  }

  /// Retrieves the content of an artifact specified by the provided
  /// [relativePath] within the build specified by the provided [buildUrl].
  Future<InteractionResult<Map<String, dynamic>>> fetchArtifactByRelativePath(
    String buildUrl,
    String relativePath,
  ) {
    logger.info('Fetching artifacts by relative path: $relativePath');

    final url = '${buildUrl}artifact/$relativePath';

    return _fetchArtifact(url);
  }

  /// Retrieves the [buildArtifact]'s content generated during the [build].
  Future<InteractionResult<Map<String, dynamic>>> fetchArtifact(
    JenkinsBuild build,
    JenkinsBuildArtifact buildArtifact,
  ) {
    logger.info('Fetching artifact for build #${build.number}...');

    final url = '${build.url}artifact/${buildArtifact.relativePath}';

    return _fetchArtifact(url);
  }

  /// Retrieves the artifact's content by the given [url].
  ///
  /// Both [fetchArtifactByRelativePath] and [fetchArtifact] methods delegate
  /// fetching the artifact's content to this method.
  Future<InteractionResult<Map<String, dynamic>>> _fetchArtifact(String url) {
    logger.info('Fetching artifact from the url: $url');

    return _handleResponse<Map<String, dynamic>>(
      _client.get(url, headers: headers),
      (Map<String, dynamic> json, _) {
        return InteractionResult.success(result: json);
      },
    );
  }

  /// Fetches the [JenkinsInstanceInfo] by the given [jenkinsUrl].
  ///
  /// Throws an [ArgumentError] if the given [jenkinsUrl] is `null`.
  ///
  /// Returns [InteractionResult.error] if the given [jenkinsUrl] is not found
  /// or does not exist.
  Future<InteractionResult<JenkinsInstanceInfo>> fetchJenkinsInstanceInfo(
    String jenkinsUrl,
  ) async {
    ArgumentError.checkNotNull(jenkinsUrl, 'jenkinsUrl');

    logger.info('Fetching Jenkins instance info from the url: $jenkinsUrl');

    final url = '$jenkinsUrl/login';

    try {
      return _handleResponse(
        _client.get(url, headers: headers),
        (_, headers) {
          final jenkinsInstanceInfo = JenkinsInstanceInfo.fromMap(headers);

          return InteractionResult.success(result: jenkinsInstanceInfo);
        },
      );
    } on SocketException {
      return InteractionResult.error(
        message: 'The given URL ($jenkinsUrl) does not exist.',
      );
    }
  }

  /// Fetches the [JenkinsUser] using the given [auth].
  ///
  /// Throws an [ArgumentError] if the given [auth] is `null`.
  Future<InteractionResult<JenkinsUser>> fetchJenkinsUser(
    AuthorizationBase auth,
  ) async {
    ArgumentError.checkNotNull(auth, 'auth');

    logger.info('Fetching Jenkins user info from the url: $jenkinsUrl');

    final url = _jenkinsUrlBuilder.build(jenkinsUrl, path: 'whoAmI');

    final requestHeaders = {
      ...headers,
      ...auth.toMap(),
    };

    return _handleResponse(
      _client.get(url, headers: requestHeaders),
      (json, _) {
        final jenkinsUser = JenkinsUser.fromJson(json);

        return InteractionResult.success(result: jenkinsUser);
      },
    );
  }

  /// Closes the client and cleans up any resources associated with it.
  /// Similar to [Client.close].
  void close() {
    _client.close();
  }
}
