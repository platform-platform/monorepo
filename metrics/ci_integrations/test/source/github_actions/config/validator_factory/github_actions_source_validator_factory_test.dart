// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/validation/model/validation_result_builder.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config.dart';
import 'package:ci_integration/source/github_actions/config/validation_delegate/github_actions_source_validation_delegate.dart';
import 'package:ci_integration/source/github_actions/config/validator_factory/github_actions_source_validator_factory.dart';
import 'package:test/test.dart';

void main() {
  group("GithubActionsSourceValidatorFactory", () {
    const validatorFactory = GithubActionsSourceValidatorFactory();

    final config = GithubActionsSourceConfig(
      accessToken: 'accessToken',
      repositoryOwner: 'repositoryOwner',
      repositoryName: 'repositoryName',
      workflowIdentifier: 'workflowIdentifier',
      jobName: 'jobName',
      coverageArtifactName: 'coverageArtifactName',
    );

    test(
      ".create() throws an ArgumentError if the given config is null",
      () {
        expect(() => validatorFactory.create(null), throwsArgumentError);
      },
    );

    test(
      ".create() returns a github actions source validator with the github actions source validation delegate",
      () {
        final validator = validatorFactory.create(config);

        expect(
          validator.validationDelegate,
          isA<GithubActionsSourceValidationDelegate>(),
        );
      },
    );

    test(
      ".create() returns a github actions source validator with the validation result builder",
      () {
        final validator = validatorFactory.create(config);

        expect(
          validator.validationResultBuilder,
          isA<ValidationResultBuilder>(),
        );
      },
    );
  });
}
