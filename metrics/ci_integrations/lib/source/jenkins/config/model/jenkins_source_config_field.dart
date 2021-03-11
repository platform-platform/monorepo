// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:collection';

import 'package:ci_integration/integration/interface/base/config/model/config_field.dart';
import 'package:ci_integration/source/jenkins/config/model/jenkins_source_config.dart';

/// A class that represents the [JenkinsSourceConfig]'s fields.
class JenkinsSourceConfigField extends ConfigField {
  /// A url field of the [JenkinsSourceConfig].
  static final JenkinsSourceConfigField url = JenkinsSourceConfigField._('url');

  /// A job name field of the [JenkinsSourceConfig].
  static final JenkinsSourceConfigField jobName =
      JenkinsSourceConfigField._('job_name');

  /// A username field of the [JenkinsSourceConfig].
  static final JenkinsSourceConfigField username =
      JenkinsSourceConfigField._('username');

  /// An api key field of the [JenkinsSourceConfig].
  static final JenkinsSourceConfigField apiKey =
      JenkinsSourceConfigField._('api_key');

  /// A list containing all [JenkinsSourceConfigField]s of
  /// the [JenkinsSourceConfig].
  static final List<JenkinsSourceConfigField> values = UnmodifiableListView([
    url,
    jobName,
    username,
    apiKey,
  ]);

  /// Creates an instance of the [JenkinsSourceConfigField] with the
  /// given value.
  ///
  /// Throws an [ArgumentError] if the given [value] is `null`.
  JenkinsSourceConfigField._(
    String value,
  ) : super(value);
}
