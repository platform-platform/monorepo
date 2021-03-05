// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/interface/source/party/source_party.dart';
import 'package:ci_integration/integration/stub/base/config/validator_factory/config_validator_factory_stub.dart';
import 'package:ci_integration/source/jenkins/adapter/jenkins_source_client_adapter.dart';
import 'package:ci_integration/source/jenkins/client_factory/jenkins_source_client_factory.dart';
import 'package:ci_integration/source/jenkins/config/model/jenkins_source_config.dart';
import 'package:ci_integration/source/jenkins/config/parser/jenkins_source_config_parser.dart';

/// An integration party for the Jenkins source integration.
class JenkinsSourceParty
    extends SourceParty<JenkinsSourceConfig, JenkinsSourceClientAdapter> {
  @override
  final JenkinsSourceClientFactory clientFactory =
      const JenkinsSourceClientFactory();

  @override
  final JenkinsSourceConfigParser configParser =
      const JenkinsSourceConfigParser();

  @override
  final ConfigValidatorFactory<JenkinsSourceConfig> configValidatorFactory =
      const ConfigValidatorFactoryStub();
}
