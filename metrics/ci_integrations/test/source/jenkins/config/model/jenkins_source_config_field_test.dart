// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:collection';

import 'package:ci_integration/source/jenkins/config/model/jenkins_source_config_field.dart';
import 'package:test/test.dart';

void main() {
  group("JenkinsSourceConfigField", () {
    test(
      ".values is unmodifiable list view",
      () {
        expect(JenkinsSourceConfigField.values, isA<UnmodifiableListView>());
      },
    );

    test(
      ".values contains all jenkins source config fields",
      () {
        final expectedConfigFields = [
          JenkinsSourceConfigField.url,
          JenkinsSourceConfigField.jobName,
          JenkinsSourceConfigField.username,
          JenkinsSourceConfigField.apiKey,
        ];

        expect(
          JenkinsSourceConfigField.values,
          containsAll(expectedConfigFields),
        );
      },
    );
  });
}
