// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/parties/parties.dart';
import 'package:ci_integration/integration/interface/base/party/integration_party.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group("Parties", () {
    const config = {'config': 'test'};

    final firstParty = _IntegrationPartyMock();
    final secondParty = _IntegrationPartyMock();

    final partiesList = <IntegrationParty>[firstParty, secondParty];

    final parties = _PartiesFake(partiesList);

    tearDown(() {
      reset(firstParty);
      reset(secondParty);
    });

    test(
      ".getParty() throws an UnimplementedError, if the party that accepts the given config is not found",
      () {
        when(firstParty.acceptsConfig(config)).thenReturn(false);
        when(secondParty.acceptsConfig(config)).thenReturn(false);

        expect(() => parties.getParty(config), throwsUnimplementedError);
      },
    );

    test(
      ".getParty() returns the party from the parties list that accepts the given config",
      () {
        when(firstParty.acceptsConfig(config)).thenReturn(false);
        when(secondParty.acceptsConfig(config)).thenReturn(true);

        final actualParty = parties.getParty(config);

        expect(actualParty, equals(secondParty));
      },
    );

    test(
      ".getParty() returns the first party from the parties list that accepts the given config",
      () {
        when(firstParty.acceptsConfig(config)).thenReturn(true);
        when(secondParty.acceptsConfig(config)).thenReturn(true);

        final actualParty = parties.getParty(config);

        expect(actualParty, equals(firstParty));
      },
    );
  });
}

/// A fake class needed to test the [Parties] non-abstract methods.
class _PartiesFake extends Parties {
  @override
  final List<IntegrationParty> parties;

  /// Creates a new instance of the [_PartiesFake] with the given [parties].
  _PartiesFake(this.parties);
}

class _IntegrationPartyMock extends Mock implements IntegrationParty {}
