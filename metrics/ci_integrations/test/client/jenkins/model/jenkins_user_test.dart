// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/jenkins/model/jenkins_user.dart';
import 'package:test/test.dart';

void main() {
  group("JenkinsUser", () {
    const name = "name";
    const authenticated = true;
    const anonymous = true;

    const userJson = {
      'name': name,
      'authenticated': authenticated,
      'anonymous': anonymous,
    };

    const user = JenkinsUser(
      name: name,
      authenticated: authenticated,
      anonymous: anonymous,
    );

    test(
      "creates an instance with the given parameters",
      () {
        const user = JenkinsUser(
          name: name,
          authenticated: authenticated,
          anonymous: anonymous,
        );

        expect(user.name, equals(name));
        expect(user.authenticated, equals(authenticated));
        expect(user.anonymous, equals(anonymous));
      },
    );

    test(
      ".fromJson() returns null if the given json is null",
      () {
        final user = JenkinsUser.fromJson(null);

        expect(user, isNull);
      },
    );

    test(
      ".fromJson() creates an instance from the given json",
      () {
        final actualUser = JenkinsUser.fromJson(userJson);

        expect(actualUser, equals(user));
      },
    );

    test(
      ".listFromJson() returns null if the given list is null",
      () {
        final list = JenkinsUser.listFromJson(null);

        expect(list, isNull);
      },
    );

    test(
      ".listFromJson() returns an empty list if the given one is empty",
      () {
        final list = JenkinsUser.listFromJson([]);

        expect(list, isEmpty);
      },
    );

    test(
      ".listFromJson() creates a list of Jenkins users from the given list of JSON encodable objects",
      () {
        const anotherJson = {
          'name': '',
          'authenticated': true,
          'anonymous': true,
        };
        const anotherUser = JenkinsUser(
          name: '',
          authenticated: true,
          anonymous: true,
        );
        const jsonList = [userJson, anotherJson];
        const expectedList = [user, anotherUser];

        final userList = JenkinsUser.listFromJson(jsonList);

        expect(userList, equals(expectedList));
      },
    );

    test(
      ".toJson() converts an instance to the json encodable map",
      () {
        final json = user.toJson();

        expect(json, equals(userJson));
      },
    );

    test(
      ".toString() contains the json representaton of the jenkins user instance",
      () {
        final json = '${user.toJson()}';

        expect(user.toString(), contains(json));
      },
    );
  });
}
