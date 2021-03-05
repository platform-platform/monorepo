// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/interface/base/client_factory/integration_client_factory.dart';
import 'package:ci_integration/integration/interface/base/config/parser/config_parser.dart';
import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/interface/source/client/source_client.dart';
import 'package:ci_integration/integration/interface/source/config/model/source_config.dart';
import 'package:ci_integration/integration/interface/source/party/source_party.dart';

/// A stub implementation of the [SourceParty] to use in tests.
class SourcePartyStub implements SourceParty {
  @override
  IntegrationClientFactory<SourceConfig, SourceClient> get clientFactory =>
      null;

  @override
  ConfigParser<SourceConfig> get configParser => null;

  @override
  ConfigValidatorFactory<SourceConfig> get configValidatorFactory => null;

  @override
  bool acceptsConfig(Map<String, dynamic> config) => null;
}
