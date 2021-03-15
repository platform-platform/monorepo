// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/auth/domain/usecases/parameters/user_credentials_param.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:test/test.dart';

import '../../../../test_utils/matchers.dart';

void main() {
  group("UserCredentialsParam", () {
    test("throws an AssertionError if the given email is null", () {
      expect(
        () => UserCredentialsParam(
          email: null,
          password: Password("password"),
        ),
        throwsAssertionError,
      );
    });

    test("throws an AssertionError if the given password is null", () {
      expect(
        () => UserCredentialsParam(
          email: Email('email@mail.mail'),
          password: null,
        ),
        throwsAssertionError,
      );
    });
  });
}
