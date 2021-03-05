// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/github_actions/mappers/github_token_scope_mapper.dart';
import 'package:ci_integration/client/github_actions/models/github_actions_workflow.dart';
import 'package:ci_integration/client/github_actions/models/github_repository.dart';
import 'package:ci_integration/client/github_actions/models/github_token.dart';
import 'package:ci_integration/client/github_actions/models/github_token_scope.dart';
import 'package:ci_integration/client/github_actions/models/github_user.dart';
import 'package:ci_integration/source/github_actions/config/validation_delegate/github_actions_source_validation_delegate.dart';
import 'package:ci_integration/source/github_actions/strings/github_actions_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/extensions/interaction_result_answer.dart';
import '../../test_utils/github_actions_client_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("GithubActionsSourceValidationDelegate", () {
    const id = 1;
    const repositoryOwner = 'owner';
    const repositoryName = 'name';
    const workflowId = 'workflow_id';

    const githubToken = GithubToken(
      scopes: [
        GithubTokenScope.repo,
      ],
    );

    const githubUser = GithubUser(
      id: id,
      login: repositoryOwner,
    );

    const githubRepository = GithubRepository(
      id: id,
      name: repositoryName,
      owner: githubUser,
    );

    const githubActionsWorkflow = GithubActionsWorkflow(
      path: workflowId,
    );

    final auth = BearerAuthorization('token');

    final client = GithubActionsClientMock();
    final delegate = GithubActionsSourceValidationDelegate(client);

    tearDown(() {
      reset(client);
    });

    test(
      "throws an ArgumentError if the given client is null",
      () {
        expect(
          () => GithubActionsSourceValidationDelegate(null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given client",
      () {
        expect(
          () => GithubActionsSourceValidationDelegate(client),
          returnsNormally,
        );
      },
    );

    test(
      ".validateAuth() returns an error if the token fetching failed",
      () async {
        when(client.fetchToken(auth)).thenErrorWith();

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the token invalid message if the token fetching failed",
      () async {
        when(client.fetchToken(auth)).thenErrorWith();

        final interactionResult = await delegate.validateAuth(auth);
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.tokenInvalid));
      },
    );

    test(
      ".validateAuth() returns an error if the token fetching result is null",
      () async {
        when(client.fetchToken(auth)).thenSuccessWith(null);

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the token invalid message if the token fetching result is null",
      () async {
        when(client.fetchToken(auth)).thenSuccessWith(null);

        final interactionResult = await delegate.validateAuth(auth);
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.tokenInvalid));
      },
    );

    test(
      ".validateAuth() returns an error if the fetched token does not have the required scope",
      () async {
        when(
          client.fetchToken(auth),
        ).thenSuccessWith(const GithubToken(scopes: []));

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the token scope not found message if the fetched token does not have the required scope",
      () async {
        final requiredScope = GithubTokenScopeMapper.repo;

        when(
          client.fetchToken(auth),
        ).thenSuccessWith(const GithubToken(scopes: []));

        final interactionResult = await delegate.validateAuth(auth);
        final message = interactionResult.message;

        expect(
          message,
          equals(
            GithubActionsStrings.tokenMissingScopes(requiredScope),
          ),
        );
      },
    );

    test(
      ".validateAuth() returns an error if the fetched token scopes are null",
      () async {
        when(client.fetchToken(auth)).thenSuccessWith(const GithubToken());

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction with the token scope not found message if the fetched token scopes are null",
      () async {
        final requiredScope = GithubTokenScopeMapper.repo;

        when(client.fetchToken(auth)).thenSuccessWith(const GithubToken());

        final interactionResult = await delegate.validateAuth(auth);
        final message = interactionResult.message;

        expect(
          message,
          equals(GithubActionsStrings.tokenMissingScopes(requiredScope)),
        );
      },
    );

    test(
      ".validateAuth() returns a successful interaction if the fetched Github token has required scope",
      () async {
        when(client.fetchToken(auth)).thenSuccessWith(githubToken);

        final interactionResult = await delegate.validateAuth(auth);

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateAuth() returns an interaction containing the fetched Github token if the fetched Github token has required scope",
      () async {
        when(client.fetchToken(auth)).thenSuccessWith(githubToken);

        final interactionResult = await delegate.validateAuth(auth);
        final token = interactionResult.result;

        expect(token, equals(githubToken));
      },
    );

    test(
      ".validateRepositoryOwner() returns an error if the repository owner fetching failed",
      () async {
        when(client.fetchGithubUser(repositoryOwner)).thenErrorWith();

        final interactionResult = await delegate.validateRepositoryOwner(
          repositoryOwner,
        );

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateRepositoryOwner() returns an interaction with the repository owner not found message if the repository owner fetching failed",
      () async {
        when(client.fetchGithubUser(repositoryOwner)).thenErrorWith();

        final interactionResult = await delegate.validateRepositoryOwner(
          repositoryOwner,
        );
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.repositoryOwnerNotFound));
      },
    );

    test(
      ".validateRepositoryOwner() returns an error if the repository owner fetching result is null",
      () async {
        when(client.fetchGithubUser(repositoryOwner)).thenSuccessWith(null);

        final interactionResult = await delegate.validateRepositoryOwner(
          repositoryOwner,
        );

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateRepositoryOwner() returns an interaction with the repository owner not found message if the repository owner fetching result is null",
      () async {
        when(client.fetchGithubUser(repositoryOwner)).thenSuccessWith(null);

        final interactionResult = await delegate.validateRepositoryOwner(
          repositoryOwner,
        );
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.repositoryOwnerNotFound));
      },
    );

    test(
      ".validateRepositoryOwner() returns a successful interaction if the given repository owner is valid",
      () async {
        when(
          client.fetchGithubUser(repositoryOwner),
        ).thenSuccessWith(githubUser);

        final interactionResult = await delegate.validateRepositoryOwner(
          repositoryOwner,
        );

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateRepositoryName() returns an error if the github repository fetching failed",
      () async {
        when(
          client.fetchGithubRepository(
            repositoryName: repositoryName,
            repositoryOwner: repositoryOwner,
          ),
        ).thenErrorWith();

        final interactionResult = await delegate.validateRepositoryName(
          repositoryName: repositoryName,
          repositoryOwner: repositoryOwner,
        );

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateRepositoryName() returns an interaction with the repository not found message if the github repository fetching failed",
      () async {
        when(
          client.fetchGithubRepository(
            repositoryName: repositoryName,
            repositoryOwner: repositoryOwner,
          ),
        ).thenErrorWith();

        final interactionResult = await delegate.validateRepositoryName(
          repositoryName: repositoryName,
          repositoryOwner: repositoryOwner,
        );
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.repositoryNotFound));
      },
    );

    test(
      ".validateRepositoryName() returns an error if the github repository fetching result is null",
      () async {
        when(
          client.fetchGithubRepository(
            repositoryName: repositoryName,
            repositoryOwner: repositoryOwner,
          ),
        ).thenSuccessWith(null);

        final interactionResult = await delegate.validateRepositoryName(
          repositoryName: repositoryName,
          repositoryOwner: repositoryOwner,
        );

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateRepositoryName() returns an interaction with the repository not found message if the github repository fetching result is null",
      () async {
        when(
          client.fetchGithubRepository(
            repositoryName: repositoryName,
            repositoryOwner: repositoryOwner,
          ),
        ).thenSuccessWith(null);

        final interactionResult = await delegate.validateRepositoryName(
          repositoryName: repositoryName,
          repositoryOwner: repositoryOwner,
        );
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.repositoryNotFound));
      },
    );

    test(
      ".validateRepositoryName() returns a successful interaction if the given repository name is valid",
      () async {
        when(
          client.fetchGithubRepository(
            repositoryName: repositoryName,
            repositoryOwner: repositoryOwner,
          ),
        ).thenSuccessWith(githubRepository);

        final interactionResult = await delegate.validateRepositoryName(
          repositoryName: repositoryName,
          repositoryOwner: repositoryOwner,
        );

        expect(interactionResult.isSuccess, isTrue);
      },
    );

    test(
      ".validateWorkflowId() returns an error if the workflow fetching failed",
      () async {
        when(client.fetchWorkflow(workflowId)).thenErrorWith();

        final interactionResult = await delegate.validateWorkflowId(workflowId);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateWorkflowId() returns an interaction with the workflow not found message if the workflow fetching failed",
      () async {
        when(client.fetchWorkflow(workflowId)).thenErrorWith();

        final interactionResult = await delegate.validateWorkflowId(workflowId);
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.workflowNotFound));
      },
    );

    test(
      ".validateWorkflowId() returns an error if the workflow fetching result is null",
      () async {
        when(client.fetchWorkflow(workflowId)).thenSuccessWith(null);

        final interactionResult = await delegate.validateWorkflowId(workflowId);

        expect(interactionResult.isError, isTrue);
      },
    );

    test(
      ".validateWorkflowId() returns an interaction with the workflow not found message if the workflow fetching result is null",
      () async {
        when(client.fetchWorkflow(workflowId)).thenSuccessWith(null);

        final interactionResult = await delegate.validateWorkflowId(workflowId);
        final message = interactionResult.message;

        expect(message, equals(GithubActionsStrings.workflowNotFound));
      },
    );

    test(
      ".validateWorkflowId() returns a successful interaction if the given workflow identifier is valid",
      () async {
        when(
          client.fetchWorkflow(workflowId),
        ).thenSuccessWith(githubActionsWorkflow);

        final interactionResult = await delegate.validateWorkflowId(workflowId);

        expect(interactionResult.isSuccess, isTrue);
      },
    );
  });
}
