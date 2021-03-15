// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/github_actions/github_actions_client.dart';
import 'package:ci_integration/integration/interface/base/config/validator/config_validator.dart';
import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/validation/model/validation_result_builder.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config_field.dart';
import 'package:ci_integration/source/github_actions/config/validation_delegate/github_actions_source_validation_delegate.dart';
import 'package:ci_integration/source/github_actions/config/validator/github_actions_source_validator.dart';
import 'package:ci_integration/util/authorization/authorization.dart';

/// A factory class that provides a method
/// for creating [GithubActionsSourceValidator].
class GithubActionsSourceValidatorFactory
    implements ConfigValidatorFactory<GithubActionsSourceConfig> {
  /// Creates a new instance of the [GithubActionsSourceValidatorFactory].
  const GithubActionsSourceValidatorFactory();

  @override
  ConfigValidator<GithubActionsSourceConfig> create(
    GithubActionsSourceConfig config,
  ) {
    ArgumentError.checkNotNull(config, 'config');

    final authorization = BearerAuthorization(config.accessToken);

    final githubActionsClient = GithubActionsClient(
      repositoryOwner: config.repositoryOwner,
      repositoryName: config.repositoryName,
      authorization: authorization,
    );

    final validationDelegate = GithubActionsSourceValidationDelegate(
      githubActionsClient,
    );

    final validationResultBuilder = ValidationResultBuilder.forFields(
      GithubActionsSourceConfigField.values,
    );

    return GithubActionsSourceValidator(
      validationDelegate,
      validationResultBuilder,
    );
  }
}
