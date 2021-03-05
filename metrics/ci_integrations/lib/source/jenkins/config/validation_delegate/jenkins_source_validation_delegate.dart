// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/jenkins/jenkins_client.dart';
import 'package:ci_integration/integration/interface/base/config/validation_delegate/validation_delegate.dart';
import 'package:ci_integration/source/jenkins/strings/jenkins_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:ci_integration/util/model/interaction_result.dart';

/// A [ValidationDelegate] for the Jenkins source integration.
class JenkinsSourceValidationDelegate implements ValidationDelegate {
  /// A [JenkinsClient] used to perform calls to the Jenkins API.
  final JenkinsClient _client;

  /// Creates a new instance of the [JenkinsSourceValidationDelegate]
  /// with the given [JenkinsClient].
  ///
  /// Throws an [ArgumentError] if the given [JenkinsClient] is `null`.
  JenkinsSourceValidationDelegate(this._client) {
    ArgumentError.checkNotNull(_client, 'client');
  }

  /// Validates the given [jenkinsUrl].
  Future<InteractionResult<void>> validateJenkinsUrl(String jenkinsUrl) async {
    final instanceInfoInteraction = await _client.fetchJenkinsInstanceInfo(
      jenkinsUrl,
    );

    if (instanceInfoInteraction.isError) {
      final message =
          instanceInfoInteraction?.message ?? JenkinsStrings.notAJenkinsUrl;

      return InteractionResult.error(message: message);
    }

    final instanceInfo = instanceInfoInteraction.result;

    if (instanceInfo == null || instanceInfo.version == null) {
      return const InteractionResult.error(
        message: JenkinsStrings.notAJenkinsUrl,
      );
    }

    return const InteractionResult.success();
  }

  /// Validates the given [auth].
  Future<InteractionResult<void>> validateAuth(AuthorizationBase auth) async {
    final userInteraction = await _client.fetchJenkinsUser(auth);

    if (userInteraction.isError || userInteraction.result == null) {
      return const InteractionResult.error(message: JenkinsStrings.authInvalid);
    }

    final jenkinsUser = userInteraction.result;

    final authenticationInfo = StringBuffer();

    final isAnonymous = jenkinsUser.anonymous ?? true;
    if (isAnonymous) {
      authenticationInfo.writeln(JenkinsStrings.anonymousUser);
    }

    final isAuthenticated = jenkinsUser.authenticated ?? false;
    if (!isAuthenticated) {
      authenticationInfo.write(JenkinsStrings.unAuthenticatedUser);
    }

    if (authenticationInfo.isNotEmpty) {
      final message = 'Note: $authenticationInfo'.replaceAll('\n', ' ');

      return InteractionResult.success(message: message);
    }

    return const InteractionResult.success();
  }

  /// Validates the given [jobName].
  Future<InteractionResult<void>> validateJobName(String jobName) async {
    final jobInteraction = await _client.fetchJob(jobName);

    if (jobInteraction.isError || jobInteraction.result == null) {
      return const InteractionResult.error(
        message: JenkinsStrings.jobDoesNotExist,
      );
    }

    return const InteractionResult.success();
  }
}
