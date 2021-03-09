// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';
import 'package:ci_integration/source/jenkins/config/model/jenkins_source_config.dart';
import 'package:ci_integration/source/jenkins/config/model/jenkins_source_config_field.dart';
import 'package:ci_integration/source/jenkins/config/validation_delegate/jenkins_source_validation_delegate.dart';
import 'package:ci_integration/source/jenkins/config/validator/jenkins_source_validator.dart';
import 'package:ci_integration/source/jenkins/strings/jenkins_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/extensions/interaction_result_answer.dart';
import '../../../../test_utils/mock/validation_result_builder_mock.dart';

void main() {
  group("JenkinsSourceValidator", () {
    const url = 'url';
    const username = 'username';
    const jobName = 'job_name';
    const apiKey = 'api_key';
    const message = 'message';

    final config = JenkinsSourceConfig(
      url: url,
      username: username,
      apiKey: apiKey,
      jobName: jobName,
    );

    final auth = BasicAuthorization(username, apiKey);

    final validationDelegate = _JenkinsSourceValidationDelegateMock();
    final validationResultBuilder = ValidationResultBuilderMock();

    final validationResult = ValidationResult(const {});

    final validator = JenkinsSourceValidator(
      validationDelegate,
      validationResultBuilder,
    );

    PostExpectation<Future<InteractionResult>> whenValidateUrl() {
      return when(validationDelegate.validateJenkinsUrl(url));
    }

    PostExpectation<Future<InteractionResult>> whenValidateAuth() {
      return when(validationDelegate.validateAuth(auth));
    }

    PostExpectation<Future<InteractionResult>> whenValidateJobName() {
      return when(validationDelegate.validateJobName(jobName));
    }

    tearDown(() {
      reset(validationDelegate);
      reset(validationResultBuilder);
    });

    test(
      "throws an ArgumentError if the given validation delegate is null",
      () {
        expect(
          () => JenkinsSourceValidator(null, validationResultBuilder),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given validation result builder is null",
      () {
        expect(
          () => JenkinsSourceValidator(validationDelegate, null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates a new instance with the given parameters",
      () {
        final validator = JenkinsSourceValidator(
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
      ".validate() delegates the jenkins url validation to the validation delegate",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verify(validationDelegate.validateAuth(auth)).called(1);
      },
    );

    test(
      ".validate() sets the successful jenkins url field validation result if the jenkins url is valid",
      () async {
        whenValidateUrl().thenSuccessWith(null, message);
        whenValidateAuth().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.url,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure jenkins url field validation result if the jenkins url is invalid",
      () async {
        whenValidateUrl().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.url,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation result with the 'jenkins url invalid' additional context if the jenkins url validation fails",
      () async {
        whenValidateUrl().thenErrorWith();

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              JenkinsStrings.jenkinsUrlInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the auth if the jenkins url validation fails",
      () async {
        whenValidateUrl().thenErrorWith(null, message);

        await validator.validate(config);

        verifyNever(validationDelegate.validateAuth(any));
      },
    );

    test(
      ".validate() does not validate the job name if the jenkins url validation fails",
      () async {
        whenValidateUrl().thenErrorWith(null, message);

        await validator.validate(config);

        verifyNever(validationDelegate.validateJobName(any));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the jenkins url validation fails",
      () async {
        when(validationResultBuilder.build()).thenReturn(validationResult);
        whenValidateUrl().thenErrorWith(null, message);

        final result = await validator.validate(config);

        expect(result, equals(validationResult));
      },
    );

    test(
      ".validate() delegates the auth credentials validation to the validation delegate",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null, message);
        whenValidateJobName().thenSuccessWith(null);

        await validator.validate(config);

        verify(validationDelegate.validateAuth(auth)).called(1);
      },
    );

    test(
      ".validate() sets the succesful username field validation result if the auth credentials are valid",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null, message);
        whenValidateJobName().thenSuccessWith(null);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.username,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the succesful api key field validation result if the auth credentials are valid",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null, message);
        whenValidateJobName().thenSuccessWith(null);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.apiKey,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure username field validation result if the auth credentials are invalid",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.username,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure api key field validation result if the auth credentials are invalid",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.apiKey,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets empty results with the unknown field validation results with the 'auth invalid' additional context if the auth credentials validation fails",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setEmptyResults(
            const FieldValidationResult.unknown(
              JenkinsStrings.authInvalidInterruptReason,
            ),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() does not validate the job name if the auth credentials validation fails",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenErrorWith(null, message);

        await validator.validate(config);

        verifyNever(validationDelegate.validateJobName(any));
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the auth credentials validation fails",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenErrorWith(null, message);
        when(validationResultBuilder.build()).thenReturn(validationResult);

        final result = await validator.validate(config);

        expect(result, equals(validationResult));
      },
    );

    test(
      ".validate() delegates the job name validation to the validation delegate",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null);
        whenValidateJobName().thenSuccessWith(null);

        await validator.validate(config);

        verify(validationDelegate.validateJobName(jobName)).called(1);
      },
    );

    test(
      ".validate() sets the successful job name validation result if the job name is valid",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null);
        whenValidateJobName().thenSuccessWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.jobName,
            const FieldValidationResult.success(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() sets the failure job name validation result if the job name is invalid",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null);
        whenValidateJobName().thenErrorWith(null, message);

        await validator.validate(config);

        verify(
          validationResultBuilder.setResult(
            JenkinsSourceConfigField.jobName,
            const FieldValidationResult.failure(message),
          ),
        ).called(1);
      },
    );

    test(
      ".validate() returns a validation result built by the validation result builder if the job name validation fails",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null);
        whenValidateJobName().thenErrorWith(null, message);
        when(validationResultBuilder.build()).thenReturn(validationResult);

        final result = await validator.validate(config);

        expect(result, equals(validationResult));
      },
    );

    test(
      ".validate() returns a validation result build by the validation result builder if the config is valid",
      () async {
        whenValidateUrl().thenSuccessWith(null);
        whenValidateAuth().thenSuccessWith(null);
        whenValidateJobName().thenSuccessWith(null);
        when(validationResultBuilder.build()).thenReturn(validationResult);

        final result = await validator.validate(config);

        expect(result, equals(validationResult));
      },
    );
  });
}

class _JenkinsSourceValidationDelegateMock extends Mock
    implements JenkinsSourceValidationDelegate {}
