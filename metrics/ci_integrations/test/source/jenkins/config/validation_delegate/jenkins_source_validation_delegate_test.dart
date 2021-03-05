// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/jenkins/model/jenkins_instance_info.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_job.dart';
import 'package:ci_integration/client/jenkins/model/jenkins_user.dart';
import 'package:ci_integration/source/jenkins/config/validation_delegate/jenkins_source_validation_delegate.dart';
import 'package:ci_integration/source/jenkins/strings/jenkins_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/extensions/interaction_result_answer.dart';
import '../../test_utils/jenkins_client_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("JenkinsSourceValidationDelegate", () {
    const url = 'url';
    const message = 'message';
    final auth = BearerAuthorization('token');
    const jobName = 'job';

    const nullVersionInstanceInfo = JenkinsInstanceInfo(version: null);

    const anonymousUser = JenkinsUser(anonymous: true);
    const unAuthenticatedUser = JenkinsUser(authenticated: false);
    const anonymousUnAuthenticatedUser = JenkinsUser(
      authenticated: false,
      anonymous: true,
    );
    const user = JenkinsUser(
      name: 'user',
      authenticated: true,
      anonymous: false,
    );

    final client = JenkinsClientMock();
    final delegate = JenkinsSourceValidationDelegate(client);

    tearDown(() {
      reset(client);
    });

    test(
      "throws an ArgumentError if the given jenkins client is null",
      () {
        expect(
          () => JenkinsSourceValidationDelegate(null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given jenkins client",
      () {
        expect(
          () => JenkinsSourceValidationDelegate(client),
          returnsNormally,
        );
      },
    );

    test(
      ".validateJenkinsUrl() returns an error if the interaction with the client is not successful",
      () async {
        when(client.fetchJenkinsInstanceInfo(url)).thenErrorWith();

        final interactionResult = await delegate.validateJenkinsUrl(url);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateJenkinsUrl() returns an interaction with the message from the client if it is not null, and the interaction is not successful",
      () async {
        when(client.fetchJenkinsInstanceInfo(url)).thenErrorWith(null, message);

        final interactionResult = await delegate.validateJenkinsUrl(url);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(message));
      },
    );

    test(
      ".validateJenkinsUrl() returns an interaction with the not a jenkins url message if the message from the client is null, and the interaction is not successful",
      () async {
        when(client.fetchJenkinsInstanceInfo(url)).thenErrorWith();

        final interactionResult = await delegate.validateJenkinsUrl(url);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(JenkinsStrings.notAJenkinsUrl));
      },
    );

    test(
      ".validateJenkinsUrl() returns an error if the interaction with the client is null",
      () async {
        when(client.fetchJenkinsInstanceInfo(url)).thenSuccessWith(null);

        final interactionResult = await delegate.validateJenkinsUrl(url);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateJenkinsUrl() returns an interaction with the not a jenkins url message if the interaction with the client is null",
      () async {
        when(client.fetchJenkinsInstanceInfo(url)).thenSuccessWith(null);

        final interactionResult = await delegate.validateJenkinsUrl(url);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(JenkinsStrings.notAJenkinsUrl));
      },
    );

    test(
      ".validateJenkinsUrl() returns an error if the fetched instance info has the version equal to null",
      () async {
        when(
          client.fetchJenkinsInstanceInfo(url),
        ).thenSuccessWith(nullVersionInstanceInfo);

        final interactionResult = await delegate.validateJenkinsUrl(url);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateJenkinsUrl() returns an interaction with the not a jenkins url message if the fetched instance info has the version equal to null",
      () async {
        when(
          client.fetchJenkinsInstanceInfo(url),
        ).thenSuccessWith(nullVersionInstanceInfo);

        final interactionResult = await delegate.validateJenkinsUrl(url);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(JenkinsStrings.notAJenkinsUrl));
      },
    );

    test(
      ".validateJenkinsUrl() returns a successful interaction if the given jenkins url is valid",
      () async {
        const info = JenkinsInstanceInfo(version: '1.0');
        when(client.fetchJenkinsInstanceInfo(url)).thenSuccessWith(info);

        final interactionResult = await delegate.validateJenkinsUrl(url);

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateAuth() returns an error if the interaction with the client is not successful",
      () async {
        when(client.fetchJenkinsUser(auth)).thenErrorWith();

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the auth invalid message if the interaction with the client is not successful",
      () async {
        when(client.fetchJenkinsUser(auth)).thenErrorWith();

        final interactionResult = await delegate.validateAuth(auth);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(JenkinsStrings.authInvalid));
      },
    );

    test(
      ".validateAuth() returns an error if the interaction with the client is null",
      () async {
        when(client.fetchJenkinsUser(auth)).thenSuccessWith(null);

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the auth invalid message if the interaction with the client is null",
      () async {
        when(client.fetchJenkinsUser(auth)).thenSuccessWith(null);

        final interactionResult = await delegate.validateAuth(auth);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(JenkinsStrings.authInvalid));
      },
    );

    test(
      ".validateAuth() returns a successful interaction if the given auth is valid",
      () async {
        when(client.fetchJenkinsUser(auth)).thenSuccessWith(user);

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateAuth() returns a successful interaction if the user associated with the given auth is anonymous",
      () async {
        when(client.fetchJenkinsUser(auth)).thenSuccessWith(anonymousUser);

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the anonymous user message if the fetched user is anonymous",
      () async {
        when(client.fetchJenkinsUser(auth)).thenSuccessWith(anonymousUser);

        final interactionResult = await delegate.validateAuth(auth);
        final resultMessage = interactionResult.message;

        expect(resultMessage, contains(JenkinsStrings.anonymousUser));
      },
    );

    test(
      ".validateAuth() returns a successful interaction if the user associated with the given auth is unauthenticated",
      () async {
        when(
          client.fetchJenkinsUser(auth),
        ).thenSuccessWith(unAuthenticatedUser);

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the unauthenticated user message if the fetched user is unauthenticated",
      () async {
        when(
          client.fetchJenkinsUser(auth),
        ).thenSuccessWith(unAuthenticatedUser);

        final interactionResult = await delegate.validateAuth(auth);
        final resultMessage = interactionResult.message;

        expect(resultMessage, contains(JenkinsStrings.unAuthenticatedUser));
      },
    );

    test(
      ".validateAuth() returns a successful interaction if the user associated with the given auth is unauthenticated and anonymous",
      () async {
        when(
          client.fetchJenkinsUser(auth),
        ).thenSuccessWith(anonymousUnAuthenticatedUser);

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the unauthenticated user and anonymous user messages if the fetched user is unauthenticated and anonymous",
      () async {
        when(
          client.fetchJenkinsUser(auth),
        ).thenSuccessWith(anonymousUnAuthenticatedUser);

        final interactionResult = await delegate.validateAuth(auth);
        final resultMessage = interactionResult.message;

        expect(resultMessage, contains(JenkinsStrings.anonymousUser));
        expect(resultMessage, contains(JenkinsStrings.unAuthenticatedUser));
      },
    );

    test(
      ".validateJobName() returns an error if the interaction with the client is error",
      () async {
        when(client.fetchJob(jobName)).thenErrorWith();

        final interactionResult = await delegate.validateJobName(jobName);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateJobName() returns an interaction with the job does not exist message if the interaction with the client is error",
      () async {
        when(client.fetchJob(jobName)).thenErrorWith();

        final interactionResult = await delegate.validateJobName(jobName);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(JenkinsStrings.jobDoesNotExist));
      },
    );

    test(
      ".validateJobName() returns an error if the interaction with the client is null",
      () async {
        when(client.fetchJob(jobName)).thenSuccessWith(null);

        final interactionResult = await delegate.validateJobName(jobName);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateJobName() returns an interaction with the job does not exist message if the interaction with the client is null",
      () async {
        when(client.fetchJob(jobName)).thenSuccessWith(null);

        final interactionResult = await delegate.validateJobName(jobName);
        final resultMessage = interactionResult.message;

        expect(resultMessage, equals(JenkinsStrings.jobDoesNotExist));
      },
    );

    test(
      ".validateJobName() returns a successful interaction if the given job name is valid",
      () async {
        const job = JenkinsJob(name: 'job');
        when(client.fetchJob(jobName)).thenSuccessWith(job);

        final interactionResult = await delegate.validateJobName(jobName);

        expect(interactionResult.isSuccess, isTrue);
      },
    );
  });
}
