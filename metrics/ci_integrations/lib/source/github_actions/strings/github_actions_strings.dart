// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// Holds the strings used across the Github Actions source integration.
class GithubActionsStrings {
  static const String tokenInvalid = 'The access token is invalid.';
  static const String repositoryOwnerNotFound =
      'A repository owner with a specified name does not exist.';
  static const String repositoryNotFound =
      'A repository with a specified name does not exist.';
  static const String workflowNotFound =
      'A workflow with a specified identifier does not exist.';

  static String tokenMissingScopes(String scopes) {
    return 'The access token does not have the required $scopes scope(s).';
  }
}
