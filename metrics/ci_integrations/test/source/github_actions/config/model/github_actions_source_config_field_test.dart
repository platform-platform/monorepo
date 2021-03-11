// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:collection';

import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config_field.dart';
import 'package:test/test.dart';

void main() {
  group("GithubActionsSourceConfigField", () {
    test(
      ".values is unmodifiable list view",
      () {
        expect(
          GithubActionsSourceConfigField.values,
          isA<UnmodifiableListView>(),
        );
      },
    );

    test(
      ".values contains all github actions source config fields",
      () {
        final expectedConfigFields = [
          GithubActionsSourceConfigField.accessToken,
          GithubActionsSourceConfigField.repositoryOwner,
          GithubActionsSourceConfigField.repositoryName,
          GithubActionsSourceConfigField.workflowIdentifier,
          GithubActionsSourceConfigField.jobName,
          GithubActionsSourceConfigField.coverageArtifactName,
        ];

        expect(
          GithubActionsSourceConfigField.values,
          containsAll(expectedConfigFields),
        );
      },
    );
  });
}
