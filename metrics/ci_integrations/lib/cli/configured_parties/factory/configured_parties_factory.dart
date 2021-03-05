// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/config/model/raw_integration_config.dart';
import 'package:ci_integration/cli/configured_parties/configured_destination_party.dart';
import 'package:ci_integration/cli/configured_parties/configured_parties.dart';
import 'package:ci_integration/cli/configured_parties/configured_source_party.dart';

import 'package:ci_integration/cli/parties/supported_integration_parties.dart';

/// A class that provides methods for creating [ConfiguredParties].
class ConfiguredPartiesFactory {
  /// An instance containing all the supported [IntegrationParty]s.
  final SupportedIntegrationParties supportedParties;

  /// Creates a new instance of the [ConfiguredPartiesFactory] with the given
  /// [supportedParties].
  ///
  /// If the given [supportedParties] is `null`, an instance
  /// of the [SupportedIntegrationParties] is used.
  ConfiguredPartiesFactory({
    SupportedIntegrationParties supportedParties,
  }) : supportedParties = supportedParties ?? SupportedIntegrationParties();

  /// Creates an instance of the [ConfiguredParties] using
  /// the given [rawIntegrationConfig].
  ///
  /// Throws an [ArgumentError] if the given [rawIntegrationConfig] is `null`.
  ConfiguredParties create(RawIntegrationConfig rawIntegrationConfig) {
    ArgumentError.checkNotNull(rawIntegrationConfig, 'rawIntegrationConfig');

    final sourceConfigMap = rawIntegrationConfig.sourceConfigMap;

    final sourceParties = supportedParties.sourceParties;
    final sourceParty = sourceParties.getParty(sourceConfigMap);

    final sourceConfigParser = sourceParty.configParser;
    final sourceConfig = sourceConfigParser.parse(sourceConfigMap);

    final destinationConfigMap = rawIntegrationConfig.destinationConfigMap;

    final destinationParties = supportedParties.destinationParties;
    final destinationParty = destinationParties.getParty(destinationConfigMap);

    final destinationConfigParser = destinationParty.configParser;
    final destinationConfig = destinationConfigParser.parse(
      destinationConfigMap,
    );

    final configuredSourceParty = ConfiguredSourceParty(
      config: sourceConfig,
      party: sourceParty,
    );
    final configuredDestinationParty = ConfiguredDestinationParty(
      config: destinationConfig,
      party: destinationParty,
    );

    return ConfiguredParties(
      configuredSourceParty: configuredSourceParty,
      configuredDestinationParty: configuredDestinationParty,
    );
  }
}
