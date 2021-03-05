// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/interface/base/client/integration_client.dart';
import 'package:ci_integration/integration/interface/base/client_factory/integration_client_factory.dart';
import 'package:ci_integration/integration/interface/base/config/model/config.dart';
import 'package:ci_integration/integration/interface/base/config/parser/config_parser.dart';
import 'package:ci_integration/integration/interface/base/config/validator/config_validator.dart';
import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';

/// An abstract class representing an integration party.
abstract class IntegrationParty<T extends Config, K extends IntegrationClient> {
  /// A client factory for this integration party.
  ///
  /// Used to create [IntegrationClient]s for this integration party.
  IntegrationClientFactory<T, K> get clientFactory;

  /// A configuration parser for this integration party.
  ///
  /// Used to parse configurations related to this integration party.
  ConfigParser<T> get configParser;

  /// A configuration validator factory for this integration party.
  ///
  /// Used to create [ConfigValidator]s for this integration party.
  ConfigValidatorFactory<T> get configValidatorFactory;

  /// Checks whether this party accepts the given [config].
  bool acceptsConfig(Map<String, dynamic> config) {
    return configParser.canParse(config);
  }
}
