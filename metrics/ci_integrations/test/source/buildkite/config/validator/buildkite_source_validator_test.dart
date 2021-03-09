// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/buildkite/models/buildkite_token.dart';
import 'package:ci_integration/client/buildkite/models/buildkite_token_scope.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';
import 'package:ci_integration/source/buildkite/config/model/buildkite_source_config.dart';
import 'package:ci_integration/source/buildkite/config/model/buildkite_source_config_field.dart';
import 'package:ci_integration/source/buildkite/config/validation_delegate/buildkite_source_validation_delegate.dart';
import 'package:ci_integration/source/buildkite/config/validator/buildkite_source_validator.dart';
import 'package:ci_integration/source/buildkite/strings/buildkite_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/extensions/interaction_result_answer.dart';
import '../../../../test_utils/mock/validation_result_builder_mock.dart';

void main() {
  group("BuildkiteSourceValidator", () {
    const accessToken = 'token';
    const organizationSlug = 'organization';
    const pipelineSlug = 'pipeline';
    const message = 'message';

    final config = BuildkiteSourceConfig(
      accessToken: accessToken,
      organizationSlug: organizationSlug,
      pipelineSlug: pipelineSlug,
    );

    final auth = BearerAuthorization(accessToken);

    const allRequiredScopesToken = BuildkiteToken(
      scopes: [
        BuildkiteTokenScope.readOrganizations,
        BuildkiteTokenScope.readPipelines,
      ],
    );
    const pipelineScopeToken = BuildkiteToken(
      scopes: [BuildkiteTokenScope.readPipelines],
    );
    const organizationScopeToken = BuildkiteToken(
      scopes: [BuildkiteTokenScope.readOrganizations],
    );

    final validationDelegate = _BuildkiteSourceValidationDelegateMock();
    final validationResultBuilder = ValidationResultBuilderMock();
    final validator = BuildkiteSourceValidator(
      validationDelegate,
      validationResultBuilder,
    );

    final field = BuildkiteSourceConfigField.pipelineSlug;
    const result = FieldValidationResult.success();
    final validationResult = ValidationResult({
      field: result,
    });

    PostExpectation<Future<InteractionResult<BuildkiteToken>>>
        whenValidateAuth() {
      return when(validationDelegate.validateAuth(auth));
    }

    PostExpectation<Future<InteractionResult>> whenValidateOrganizationSlug({
      BuildkiteToken accessToken,
    }) {
      whenValidateAuth().thenSuccessWith(accessToken);

      return when(
        validationDelegate.validateOrganizationSlug(organizationSlug),
      );
    }

    PostExpectation<Future<InteractionResult>> whenValidatePipelineSlug() {
      whenValidateOrganizationSlug(
        accessToken: allRequiredScopesToken,
      ).thenSuccessWith(null);

      return when(
        validationDelegate.validatePipelineSlug(pipelineSlug),
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
          () => BuildkiteSourceValidator(null, validationResultBuilder),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given validation result builder is null",
      () {
        expect(
          () => BuildkiteSourceValidator(validationDelegate, null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates a new instance with the given parameters",
      () {
        final validator = BuildkiteSourceValidator(
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
        whenValidateAuth().thenSuccessWith(pipelineScopeToken);

        final expectedAuth = BearerAuthorization(accessToken);

        validator.validate(config);

        verify(validationDelegate.validateAuth(expectedAuth)).called(1);
      },
    );

    test(
      ".validate() sets the successful access token field validation result if the access token is valid",
      () async {
        whenValidateAuth().thenSuccessWith(pipelineScopeToken, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            BuildkiteSourceConfigField.accessToken,
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
            BuildkiteSourceConfigField.accessToken,
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
              BuildkiteStrings.tokenInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the organization slug if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verifyNever(validationDelegate.validateOrganizationSlug(any));
      },
    );

    test(
      ".validate() does not validate the pipeline slug if the access token validation fails",
      () async {
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verifyNever(validationDelegate.validatePipelineSlug(any));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the access token validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateAuth().thenErrorWith(null, message);

        final result = await validator.validate(config);

        expect(result, equals(validationResult));
      },
    );

    test(
      ".validate() sets the unknown organization slug field validation result with the 'no scopes to validate organization' additional context if the access token has no scope to validate the organization slug",
      () async {
        whenValidateAuth().thenSuccessWith(pipelineScopeToken);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            BuildkiteSourceConfigField.organizationSlug,
            const FieldValidationResult.unknown(
              BuildkiteStrings.noScopesToValidateOrganization,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'organization can't be validated' additional context if the access token has no scope to validate the organization slug",
      () async {
        whenValidateAuth().thenSuccessWith(pipelineScopeToken);

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              BuildkiteStrings.organizationCantBeValidatedInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the organization slug if the access token has no scope to validate the organization slug",
      () async {
        whenValidateAuth().thenSuccessWith(pipelineScopeToken);

        await validator.validate(config);

        verifyNever(validationDelegate.validateOrganizationSlug(any));
      },
    );

    test(
      ".validate() does not validate the pipeline slug if the access token has no scope to validate the organization slug",
      () async {
        whenValidateAuth().thenSuccessWith(pipelineScopeToken);

        await validator.validate(config);

        verifyNever(validationDelegate.validatePipelineSlug(any));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the access token has no scope to validate the organization slug",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateAuth().thenSuccessWith(pipelineScopeToken);

        final result = await validator.validate(config);

        expect(result, equals(validationResult));
      },
    );

    test(
      ".validate() delegates organization slug validation to the validation delegate",
      () async {
        whenValidateOrganizationSlug(
          accessToken: organizationScopeToken,
        ).thenSuccessWith(null);

        await validator.validate(config);

        verify(
          validationDelegate.validateOrganizationSlug(organizationSlug),
        ).called(1);
      },
    );

    test(
      ".validate() sets the successful organization slug field validation result if the organization slug is valid",
      () async {
        whenValidateOrganizationSlug(
          accessToken: organizationScopeToken,
        ).thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            BuildkiteSourceConfigField.organizationSlug,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure organization slug field validation result if the organization slug is invalid",
      () async {
        whenValidateOrganizationSlug(
          accessToken: allRequiredScopesToken,
        ).thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            BuildkiteSourceConfigField.organizationSlug,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'organization slug is invalid' additional context after the organization slug validation fails",
      () async {
        whenValidateOrganizationSlug(
          accessToken: allRequiredScopesToken,
        ).thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              BuildkiteStrings.organizationInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the pipeline slug if the organization slug validation fails",
      () async {
        whenValidateOrganizationSlug(
          accessToken: allRequiredScopesToken,
        ).thenErrorWith();

        await validator.validate(config);

        verifyNever(validationDelegate.validatePipelineSlug(any));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the organization slug validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateOrganizationSlug(
          accessToken: allRequiredScopesToken,
        ).thenErrorWith();

        final result = await validator.validate(config);

        expect(result, equals(result));
      },
    );

    test(
      ".validate() sets the unknown pipeline slug field validation result with the 'no scopes to validate pipeline' if the access token hasn't scope to validate the pipeline slug",
      () async {
        whenValidateOrganizationSlug(
          accessToken: organizationScopeToken,
        ).thenSuccessWith(null);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            BuildkiteSourceConfigField.pipelineSlug,
            const FieldValidationResult.unknown(
              BuildkiteStrings.noScopesToValidatePipeline,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the pipeline slug if the access token hasn't scope to validate the pipeline slug",
      () async {
        whenValidateOrganizationSlug(
          accessToken: organizationScopeToken,
        ).thenSuccessWith(null);

        await validator.validate(config);

        verifyNever(validationDelegate.validatePipelineSlug(any));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the access token hasn't scope to validate the pipeline slug",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateOrganizationSlug(
          accessToken: organizationScopeToken,
        ).thenSuccessWith(null);

        final result = await validator.validate(config);

        expect(result, equals(result));
      },
    );

    test(
      ".validate() delegates the pipeline slug validation to the validation delegate",
      () async {
        whenValidatePipelineSlug().thenSuccessWith(null);

        await validator.validate(config);

        verify(
          validationDelegate.validatePipelineSlug(pipelineSlug),
        ).called(1);
      },
    );

    test(
      ".validate() sets the successful pipeline slug field validation result if the pipeline slug is valid",
      () async {
        whenValidatePipelineSlug().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            BuildkiteSourceConfigField.pipelineSlug,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure pipeline slug field validation result if the pipeline slug is invalid",
      () async {
        whenValidatePipelineSlug().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            BuildkiteSourceConfigField.pipelineSlug,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the pipeline slug validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidatePipelineSlug().thenErrorWith(null, message);

        final result = await validator.validate(config);

        expect(result, equals(result));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the config is valid",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidatePipelineSlug().thenSuccessWith(null);

        final result = await validator.validate(config);

        expect(result, equals(validationResult));
      },
    );
  });
}

class _BuildkiteSourceValidationDelegateMock extends Mock
    implements BuildkiteSourceValidationDelegate {}
