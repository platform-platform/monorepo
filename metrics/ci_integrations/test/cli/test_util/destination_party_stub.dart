// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/interface/base/client_factory/integration_client_factory.dart';
import 'package:ci_integration/integration/interface/base/config/parser/config_parser.dart';
import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/interface/destination/client/destination_client.dart';
import 'package:ci_integration/integration/interface/destination/config/model/destination_config.dart';
import 'package:ci_integration/integration/interface/destination/party/destination_party.dart';

/// A stub implementation of the [DestinationParty] to use in tests.
class DestinationPartyStub implements DestinationParty {
  @override
  IntegrationClientFactory<DestinationConfig, DestinationClient>
      get clientFactory => null;

  @override
  ConfigParser<DestinationConfig> get configParser => null;

  @override
  ConfigValidatorFactory<DestinationConfig> get configValidatorFactory => null;

  @override
  bool acceptsConfig(Map<String, dynamic> config) => null;
}
