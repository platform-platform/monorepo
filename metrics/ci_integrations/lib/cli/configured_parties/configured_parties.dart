// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/configured_parties/configured_destination_party.dart';
import 'package:ci_integration/cli/configured_parties/configured_source_party.dart';
import 'package:ci_integration/integration/interface/destination/config/model/destination_config.dart';
import 'package:ci_integration/integration/interface/destination/party/destination_party.dart';
import 'package:ci_integration/integration/interface/source/config/model/source_config.dart';
import 'package:ci_integration/integration/interface/source/party/source_party.dart';
import 'package:meta/meta.dart';

/// A class that holds a [ConfiguredSourceParty] and a
/// [ConfiguredDestinationParty].
@immutable
class ConfiguredParties {
  /// A [ConfiguredSourceParty] that holds the [SourceConfig]
  /// and the [SourceParty] that accepts this config.
  final ConfiguredSourceParty configuredSourceParty;

  /// A [ConfiguredDestinationParty] that holds the [DestinationConfig]
  /// and the [DestinationParty] that accepts this config.
  final ConfiguredDestinationParty configuredDestinationParty;

  /// Creates a new instance of the [ConfiguredParties] with the given
  /// [configuredSourceParty] and [configuredDestinationParty].
  ///
  /// Throws an [ArgumentError] if any of the given parameters is `null`.
  ConfiguredParties({
    @required this.configuredSourceParty,
    @required this.configuredDestinationParty,
  }) {
    ArgumentError.checkNotNull(configuredSourceParty, 'configuredSourceParty');
    ArgumentError.checkNotNull(
      configuredDestinationParty,
      'configuredDestinationParty',
    );
  }
}
