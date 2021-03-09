// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// Holds the strings used across the Jenkins source integration.
class JenkinsStrings {
  static const String notAJenkinsUrl =
      'The given URL is not a Jenkins URL or a custom authentication flow is used.';
  static const String authInvalid =
      'The given authorization credentials are invalid.';
  static const String jobDoesNotExist =
      'A job with such name does not exist, or the provided authorization credentials lack permissions to access a job with this name.';
  static const String anonymousUser =
      'The user with these authorization credentials is an anonymous user.';
  static const String unAuthenticatedUser =
      'The user with these authorization credentials is not authenticated.';
  static const String jenkinsUrlInvalidInterruptReason =
      "Can't be validated as the provided Jenkins URL is invalid.";
  static const String authInvalidInterruptReason =
      "Can't be validated as the provided authentication credentials are invalid.";
}
