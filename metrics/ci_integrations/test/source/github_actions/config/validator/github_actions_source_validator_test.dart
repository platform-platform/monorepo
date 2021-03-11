// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/github_actions/models/github_token.dart';
import 'package:ci_integration/client/github_actions/models/github_token_scope.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result_builder.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config_field.dart';
import 'package:ci_integration/source/github_actions/config/validation_delegate/github_actions_source_validation_delegate.dart';
import 'package:ci_integration/source/github_actions/config/validator/github_actions_source_validator.dart';
import 'package:ci_integration/source/github_actions/strings/github_actions_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/extensions/interaction_result_answer.dart';

void main() {
  group("GithubActionsSourceValidator", () {
    const accessToken = 'accessToken';
    const repositoryOwner = 'repositoryOwner';
    const repositoryName = 'repositoryName';
    const workflowId = 'workflowId';
    const jobName = 'jobName';
    const coverageArtifactName = 'coverageArtifactName';
    const message = 'message';

    final config = GithubActionsSourceConfig(
      repositoryOwner: repositoryOwner,
      repositoryName: repositoryName,
      workflowIdentifier: workflowId,
      jobName: jobName,
      coverageArtifactName: coverageArtifactName,
      accessToken: accessToken,
    );

    final auth = BearerAuthorization(accessToken);

    const githubToken = GithubToken(
      scopes: [GithubTokenScope.repo],
    );

    final validationDelegate = _GithubActionsSourceValidationDelegateMock();
    final validationResultBuilder = _ValidationResultBuilderMock();
    final validator = GithubActionsSourceValidator(
      validationDelegate,
      validationResultBuilder,
    );

    final field = GithubActionsSourceConfigField.workflowIdentifier;
    const result = FieldValidationResult.success();
    final validationResult = ValidationResult({
      field: result,
    });

    PostExpectation<Future<InteractionResult<GithubToken>>> whenValidateAuth() {
      return when(validationDelegate.validateAuth(auth));
    }

    PostExpectation<Future<InteractionResult<void>>>
        whenValidateRepositoryOwner() {
      whenValidateAuth().thenSuccessWith(githubToken, message);

      return when(
        validationDelegate.validateRepositoryOwner(repositoryOwner),
      );
    }

    PostExpectation<Future<InteractionResult<void>>>
        whenValidateRepositoryName() {
      whenValidateRepositoryOwner().thenSuccessWith(null, message);

      return when(
        validationDelegate.validateRepositoryName(
          repositoryName: repositoryName,
          repositoryOwner: repositoryOwner,
        ),
      );
    }

    PostExpectation<Future<InteractionResult<void>>> whenValidateWorkflowId() {
      whenValidateRepositoryName().thenSuccessWith(null, message);

      return when(
        validationDelegate.validateWorkflowId(workflowId),
      );
    }

    tearDown(() {
      reset(validationDelegate);
      reset(validationResultBuilder);
    });

    test(
      "throws an ArgumentError if the given validation delegate is null",
      () {
        expect(
          () => GithubActionsSourceValidator(null, validationResultBuilder),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given validation result builder is null",
      () {
        expect(
          () => GithubActionsSourceValidator(validationDelegate, null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates a new instance with the given parameters",
      () {
        final validator = GithubActionsSourceValidator(
          validationDelegate,
          validationResultBuilder,
        );

        expect(validator.validationDelegate, equals(validationDelegate));
        expect(
          validator.validationResultBuilder,
          equals(validationResultBuilder),
        );
      },
    );

    test(
      ".validate() delegates the access token validation to the validation delegate",
      () {
        whenValidateAuth().thenErrorWith();

        final expectedAuth = BearerAuthorization(accessToken);

        validator.validate(config);

        verify(validationDelegate.validateAuth(expectedAuth)).called(1);
      },
    );

    test(
      ".validate() sets the successful access token field validation result if the access token is valid",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();
        whenValidateAuth().thenSuccessWith(githubToken, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.accessToken,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure access token field validation result if the access token is invalid",
      () async {
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.accessToken,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'token invalid' additional context if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              GithubActionsStrings.tokenInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the repository owner if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(
          validationDelegate.validateRepositoryOwner(repositoryOwner),
        );
      },
    );

    test(
      ".validate() does not validate the repository name if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateRepositoryName(
          repositoryOwner: repositoryOwner,
          repositoryName: repositoryName,
        ));
      },
    );

    test(
      ".validate() does not validate the workflow identifier if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateWorkflowId(workflowId));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the access token validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateAuth().thenErrorWith();

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates the repository owner validation to the validation delegate",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateRepositoryOwner(repositoryOwner),
        ).called(1);
      },
    );

    test(
      ".validate() sets the successful repository owner field validation result if the repository owner is valid",
      () async {
        whenValidateRepositoryName().thenErrorWith();
        whenValidateRepositoryOwner().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryOwner,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure repository owner field validation result if the repository owner is invalid",
      () async {
        whenValidateRepositoryOwner().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryOwner,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'repository owner invalid' additional context if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              GithubActionsStrings.repositoryOwnerInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the repository name if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateRepositoryName(
          repositoryOwner: repositoryOwner,
          repositoryName: repositoryName,
        ));
      },
    );

    test(
      ".validate() does not validate the workflow identifier if the repository owner validation fails",
      () async {
        whenValidateRepositoryOwner().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateWorkflowId(workflowId));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the repository owner validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateRepositoryOwner().thenErrorWith();

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates repository name validation to the validation delegate",
      () async {
        whenValidateRepositoryName().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateRepositoryName(
            repositoryName: repositoryName,
            repositoryOwner: repositoryOwner,
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the successful repository name field validation result if the repository name is valid",
      () async {
        whenValidateWorkflowId().thenErrorWith();
        whenValidateRepositoryName().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryName,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure repository name field validation result if the repository name is invalid",
      () async {
        whenValidateRepositoryName().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.repositoryName,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'repository name invalid' additional context if the repository name validation fails",
      () async {
        whenValidateRepositoryName().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              GithubActionsStrings.repositoryNameInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the workflow identifier if the repository name validation fails",
      () async {
        whenValidateRepositoryName().thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validateWorkflowId(workflowId));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the repository name validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateRepositoryName().thenErrorWith(null, message);

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );

    test(
      ".validate() delegates validate workflow id validation to the validation delegate",
      () async {
        whenValidateWorkflowId().thenErrorWith();

        await validator.validate(config);

        verify(
          validationDelegate.validateWorkflowId(workflowId),
        ).called(1);
      },
    );

    test(
      ".validate() sets the successful workflow identifier field validation result if the workflow identifier is valid",
      () async {
        whenValidateWorkflowId().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.workflowIdentifier,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure workflow identifier field validation result if the workflow identifier is invalid",
      () async {
        whenValidateWorkflowId().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            GithubActionsSourceConfigField.workflowIdentifier,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'workflow identifier invalid' additional context if the workflow identifier validation fails",
      () async {
        whenValidateWorkflowId().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              GithubActionsStrings.workflowIdInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the workflow identifier validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);

        whenValidateWorkflowId().thenErrorWith();

        final actualResult = await validator.validate(config);

        expect(actualResult, equals(validationResult));
      },
    );
  });
}

class _GithubActionsSourceValidationDelegateMock extends Mock
    implements GithubActionsSourceValidationDelegate {}

class _ValidationResultBuilderMock extends Mock
    implements ValidationResultBuilder {}
