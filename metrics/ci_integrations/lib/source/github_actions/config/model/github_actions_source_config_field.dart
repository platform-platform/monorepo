// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:collection';

import 'package:ci_integration/integration/interface/base/config/model/config_field.dart';
import 'package:ci_integration/source/github_actions/config/model/github_actions_source_config.dart';

/// A class that represents the [GithubActionsSourceConfig]'s fields.
class GithubActionsSourceConfigField extends ConfigField {
  /// A workflow identifier field of the [GithubActionsSourceConfig].
  static final GithubActionsSourceConfigField workflowIdentifier =
      GithubActionsSourceConfigField._('workflow_identifier');

  /// A repository name field of the [GithubActionsSourceConfig].
  static final GithubActionsSourceConfigField repositoryName =
      GithubActionsSourceConfigField._('repository_name');

  /// A repository owner field of the [GithubActionsSourceConfig].
  static final GithubActionsSourceConfigField repositoryOwner =
      GithubActionsSourceConfigField._('repository_owner');

  /// An access token field of the [GithubActionsSourceConfig].
  static final GithubActionsSourceConfigField accessToken =
      GithubActionsSourceConfigField._('access_token');

  /// A job name field of the [GithubActionsSourceConfig].
  static final GithubActionsSourceConfigField jobName =
      GithubActionsSourceConfigField._('job_name');

  /// A coverage artifact name field of the [GithubActionsSourceConfig].
  static final GithubActionsSourceConfigField coverageArtifactName =
      GithubActionsSourceConfigField._('coverage_artifact_name');

  /// A list containing all [GithubActionsSourceConfigField]s of
  /// the [GithubActionsSourceConfig].
  static final List<GithubActionsSourceConfigField> values =
      UnmodifiableListView([
    accessToken,
    workflowIdentifier,
    repositoryName,
    repositoryOwner,
    jobName,
    coverageArtifactName,
  ]);

  /// Creates an instance of the [GithubActionsSourceConfigField]
  /// with the given value.
  ///
  /// Throws an [ArgumentError] if the given [value] is `null`.
  GithubActionsSourceConfigField._(
    String value,
  ) : super(value);
}
