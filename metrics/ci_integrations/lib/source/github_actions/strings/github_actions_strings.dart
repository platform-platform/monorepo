// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// Holds the strings used across the Github Actions source integration.
class GithubActionsStrings {
  static const String tokenInvalid = 'The access token is invalid.';
  static const String tokenInvalidInterruptReason =
      "Can't be validated as the provided access token is invalid.";
  static const String repositoryOwnerNotFound =
      'A repository owner with a specified name does not exist.';
  static const String repositoryOwnerInvalidInterruptReason =
      "Can't be validated as the provided repository owner is invalid.";
  static const String repositoryNotFound =
      'A repository with a specified name does not exist.';
  static const String repositoryNameInvalidInterruptReason =
      "Can't be validated as the provided repository name is invalid.";
  static const String workflowNotFound =
      'A workflow with a specified identifier does not exist.';
  static const String workflowIdentifierInvalid =
      'The workflow identifier is invalid.';
  static const String workflowIdInvalidInterruptReason =
      "Can't be validated as the provided workflow identifier is invalid.";
  static const String jobNameInvalid = 'The job name is invalid.';
  static const String noCompletedWorkflowRuns =
      "Can't be validated as there are no completed workflow runs.";
  static const String noSuccessfulWorkflowRuns =
      "Can't be validated as there are no successful workflow runs.";
  static const String jobsFetchingFailed =
      "Can't be validated as there is an error while fetching workflow run jobs.";
  static const String artifactsFetchingFailed =
      "Can't be validated as there is an error while fetching workflow run artifacts.";
  static const String coverageArtifactNameInvalid =
      'The coverage artifact name is invalid.';
  static const String notImplemented = 'Not implemented.';

  static String tokenMissingScopes(String scopes) {
    return 'The access token does not have the required $scopes scope(s).';
  }
}
