// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/configured_parties/configured_party.dart';
import 'package:ci_integration/integration/interface/base/client/integration_client.dart';
import 'package:ci_integration/integration/interface/base/config/model/config.dart';
import 'package:ci_integration/integration/interface/base/party/integration_party.dart';
import 'package:test/test.dart';

import '../test_util/source_config_stub.dart';
import '../test_util/source_party_stub.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ConfiguredParty", () {
    final config = SourceConfigStub();
    final party = SourcePartyStub();

    test(
      "throws an ArgumentError if the given config is null",
      () {
        expect(
          () => _ConfiguredPartyFake(config: null, party: party),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given party is null",
      () {
        expect(
          () => _ConfiguredPartyFake(config: config, party: null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given parameters",
      () {
        final configuredParty = _ConfiguredPartyFake(
          config: config,
          party: party,
        );

        expect(configuredParty.config, equals(config));
        expect(configuredParty.party, equals(party));
      },
    );
  });
}

/// A fake implementation of the [ConfiguredParty] class needed to test the
/// [ConfiguredParty] non-abstract methods.
class _ConfiguredPartyFake extends ConfiguredParty {
  /// Creates a new instance of the [_ConfiguredPartyFake] with the given
  /// parameters.
  _ConfiguredPartyFake({
    Config config,
    IntegrationParty<Config, IntegrationClient> party,
  }) : super(config, party);
}
