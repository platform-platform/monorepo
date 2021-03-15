// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/common/presentation/navigation/route_configuration/route_configuration.dart';
import 'package:metrics/common/presentation/navigation/route_configuration/route_name.dart';
import 'package:test/test.dart';

import '../../../../test_utils/matchers.dart';

void main() {
  group("RouteConfiguration", () {
    test(
      "throws an AssertionError if the given name is null",
      () {
        expect(
          () => RouteConfiguration(name: null, authorizationRequired: true),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given authorization required is null",
      () {
        expect(
          () => RouteConfiguration(
            name: RouteName.login,
            authorizationRequired: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "creates an instance with the given parameters",
      () {
        const name = RouteName.login;
        const path = 'test_path';
        const authorizationRequired = false;

        const configuration = RouteConfiguration(
          name: name,
          path: path,
          authorizationRequired: authorizationRequired,
        );

        expect(configuration.name, equals(name));
        expect(configuration.path, equals(path));
        expect(
          configuration.authorizationRequired,
          equals(authorizationRequired),
        );
      },
    );
  });
}
