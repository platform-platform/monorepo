// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/interface/base/client/integration_client.dart';
import 'package:ci_integration/integration/interface/base/client_factory/integration_client_factory.dart';
import 'package:ci_integration/integration/interface/base/config/model/config.dart';
import 'package:ci_integration/integration/interface/base/config/parser/config_parser.dart';
import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/interface/base/party/integration_party.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../cli/test_util/mock/config_parser_mock.dart';

void main() {
  group("IntegrationParty", () {
    const config = <String, dynamic>{'config': 'test'};

    final configParser = ConfigParserMock();
    final integrationParty = _IntegrationPartyFake(configParser);

    tearDown(() {
      reset(configParser);
    });

    test(
      ".canServeConfig() delegates to config parser's .canParse() method",
      () {
        integrationParty.acceptsConfig(config);

        verify(configParser.canParse(config)).called(1);
      },
    );

    test(
      ".canServeConfig() returns the result of the config parser's .canParse() method",
      () {
        const expectedResult = true;

        when(configParser.canParse(config)).thenReturn(expectedResult);

        final result = integrationParty.acceptsConfig(config);

        expect(result, equals(expectedResult));
      },
    );
  });
}

/// A fake class needed to test the [IntegrationParty] non-abstract methods.
class _IntegrationPartyFake extends IntegrationParty {
  @override
  final ConfigParser<Config> configParser;

  @override
  IntegrationClientFactory<Config, IntegrationClient> get clientFactory => null;

  @override
  ConfigValidatorFactory<Config> get configValidatorFactory => null;

  /// Creates a new instance of the [_IntegrationPartyFake]
  /// with the given [configParser].
  _IntegrationPartyFake(this.configParser);
}
