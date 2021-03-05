// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:equatable/equatable.dart';

/// A class that represents a Jenkins user.
class JenkinsUser extends Equatable {
  /// A name of this user.
  final String name;

  /// A flag that indicates whether the user is authenicated or not.
  final bool authenticated;

  /// A flag that indicates whether the user is anonymous or not.
  final bool anonymous;

  @override
  List<Object> get props => [name, authenticated, anonymous];

  /// Creates a new instance of the [JenkinsUser] with the given parameters.
  const JenkinsUser({
    this.name,
    this.anonymous,
    this.authenticated,
  });

  /// Creates a new instance of the [JenkinsUser] from the decoded JSON
  /// object.
  ///
  /// Returns `null` if the given [json] is `null`.
  factory JenkinsUser.fromJson(Map<String, dynamic> json) {
    if (json == null) return null;

    return JenkinsUser(
      name: json['name'] as String,
      anonymous: json['anonymous'] as bool,
      authenticated: json['authenticated'] as bool,
    );
  }

  /// Creates a list of [JenkinsUser]s from the given [list] of decoded JSON
  /// objects.
  ///
  /// Returns `null` if the given [list] is `null`.
  static List<JenkinsUser> listFromJson(List<dynamic> list) {
    return list?.map((json) {
      return JenkinsUser.fromJson(json as Map<String, dynamic>);
    })?.toList();
  }

  /// Converts this user instance into the JSON encodable [Map].
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'authenticated': authenticated,
      'anonymous': anonymous,
    };
  }

  @override
  String toString() {
    return 'JenkinsUser ${toJson()}';
  }
}
