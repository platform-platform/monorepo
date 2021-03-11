// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/interface/base/config/validator/config_validator.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result_builder.dart';
import 'package:ci_integration/source/jenkins/config/model/jenkins_source_config.dart';
import 'package:ci_integration/source/jenkins/config/model/jenkins_source_config_field.dart';
import 'package:ci_integration/source/jenkins/config/validation_delegate/jenkins_source_validation_delegate.dart';
import 'package:ci_integration/source/jenkins/strings/jenkins_strings.dart';
import 'package:ci_integration/util/authorization/authorization.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:meta/meta.dart';

/// A class responsible for validating the [JenkinsSourceConfig].
class JenkinsSourceValidator implements ConfigValidator<JenkinsSourceConfig> {
  @override
  final JenkinsSourceValidationDelegate validationDelegate;

  @override
  final ValidationResultBuilder validationResultBuilder;

  /// Creates a new instance of the [JenkinsSourceValidator] with the given
  /// [validationDelegate] and [validationResultBuilder].
  ///
  /// Throws an [ArgumentError] if the given [validationDelegate] or
  /// [validationResultBuilder] is `null`.
  JenkinsSourceValidator(
    this.validationDelegate,
    this.validationResultBuilder,
  ) {
    ArgumentError.checkNotNull(validationDelegate, 'validationDelegate');
    ArgumentError.checkNotNull(
      validationResultBuilder,
      'validationResultBuilder',
    );
  }

  @override
  Future<ValidationResult> validate(JenkinsSourceConfig config) async {
    final jenkinsUrl = config.url;

    final jenkinsUrlInteraction = await validationDelegate.validateJenkinsUrl(
      jenkinsUrl,
    );

    _processInteraction(
      interaction: jenkinsUrlInteraction,
      field: JenkinsSourceConfigField.url,
    );

    if (jenkinsUrlInteraction.isError) {
      return _finalizeValidationResult(
        JenkinsStrings.jenkinsUrlInvalidInterruptReason,
      );
    }

    final username = config.username;
    final apiKey = config.apiKey;
    final auth = BasicAuthorization(username, apiKey);

    final authInteraction = await validationDelegate.validateAuth(auth);

    _processInteraction(
      interaction: authInteraction,
      field: JenkinsSourceConfigField.username,
    );
    _processInteraction(
      interaction: authInteraction,
      field: JenkinsSourceConfigField.apiKey,
    );

    if (authInteraction.isError) {
      return _finalizeValidationResult(
        JenkinsStrings.authInvalidInterruptReason,
      );
    }

    final jobName = config.jobName;
    final jobInteraction = await validationDelegate.validateJobName(jobName);

    _processInteraction(
      interaction: jobInteraction,
      field: JenkinsSourceConfigField.jobName,
    );

    return validationResultBuilder.build();
  }

  /// Processes the given [interaction].
  ///
  /// Maps the given [interaction] to a [FieldValidationResult] and
  /// sets the [field] validation result in [validationResultBuilder].
  void _processInteraction({
    @required InteractionResult interaction,
    @required JenkinsSourceConfigField field,
  }) {
    final fieldValidationResult = _mapInteractionToFieldValidationResult(
      interaction,
    );

    validationResultBuilder.setResult(field, fieldValidationResult);
  }

  /// Sets the empty results of the [validationResultBuilder] using the given
  /// [interruptReason] and builds the [ValidationResult]
  /// using the [validationResultBuilder].
  ValidationResult _finalizeValidationResult(String interruptReason) {
    _setEmptyFields(interruptReason);

    return validationResultBuilder.build();
  }

  /// Sets empty results of the [validationResultBuilder] to the
  /// [FieldValidationResult.unknown] with the given [interruptReason] as
  /// a [FieldValidationResult.additionalContext].
  void _setEmptyFields(String interruptReason) {
    final emptyFieldResult = FieldValidationResult.unknown(interruptReason);

    validationResultBuilder.setEmptyResults(emptyFieldResult);
  }

  /// Maps the given [interaction] to a [FieldValidationResult].
  ///
  /// Returns [FieldValidationResult.failure] if
  /// the [interaction.isError] is `true`.
  ///
  /// Otherwise, returns [FieldValidationResult.success].
  FieldValidationResult _mapInteractionToFieldValidationResult(
    InteractionResult interaction,
  ) {
    final additionalContext = interaction.message;

    if (interaction.isError) {
      return FieldValidationResult.failure(additionalContext);
    }

    return FieldValidationResult.success(additionalContext);
  }
}
