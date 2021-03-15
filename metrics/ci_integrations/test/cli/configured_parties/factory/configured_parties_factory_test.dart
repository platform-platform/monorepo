// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/config/model/raw_integration_config.dart';
import 'package:ci_integration/cli/configured_parties/factory/configured_parties_factory.dart';
import 'package:ci_integration/cli/parties/parties.dart';
import 'package:ci_integration/cli/parties/supported_integration_parties.dart';
import 'package:ci_integration/integration/interface/base/config/model/config.dart';
import 'package:ci_integration/integration/interface/base/config/parser/config_parser.dart';
import 'package:ci_integration/integration/interface/base/party/integration_party.dart';
import 'package:ci_integration/integration/interface/destination/config/model/destination_config.dart';
import 'package:ci_integration/integration/interface/destination/party/destination_party.dart';
import 'package:ci_integration/integration/interface/source/config/model/source_config.dart';
import 'package:ci_integration/integration/interface/source/party/source_party.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../test_util/destination_config_stub.dart';
import '../../test_util/mock/config_parser_mock.dart';
import '../../test_util/mock/parties_mock.dart';
import '../../test_util/source_config_stub.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ConfiguredPartiesFactory", () {
    const sourceConfigMap = {'source': 'config'};
    const destinationConfigMap = {'destination': 'config'};

    final rawConfig = RawIntegrationConfig(
      sourceConfigMap: sourceConfigMap,
      destinationConfigMap: destinationConfigMap,
    );

    final sourceConfig = SourceConfigStub();
    final destinationConfig = DestinationConfigStub();

    final sourceParties = PartiesMock<SourceParty>();
    final destinationParties = PartiesMock<DestinationParty>();

    final supportedParties = SupportedIntegrationParties(
      sourceParties: sourceParties,
      destinationParties: destinationParties,
    );

    final configuredPartiesFactory = ConfiguredPartiesFactory(
      supportedParties: supportedParties,
    );

    final sourceParty = _SourcePartyMock();
    final destinationParty = _DestinationPartyMock();

    final sourceConfigParser = ConfigParserMock<SourceConfig>();
    final destinationConfigParser = ConfigParserMock<DestinationConfig>();

    PostExpectation<T> whenParseConfig<T extends Config>(
      Parties parties,
      Map<String, dynamic> configMap,
      IntegrationParty party,
      ConfigParser<T> configParser,
    ) {
      when(parties.getParty(configMap)).thenReturn(party);
      when(party.configParser).thenReturn(configParser);

      return when(configParser.parse(configMap));
    }

    PostExpectation<SourceConfig> whenParseSourceConfig() {
      return whenParseConfig<SourceConfig>(
        sourceParties,
        sourceConfigMap,
        sourceParty,
        sourceConfigParser,
      );
    }

    PostExpectation<DestinationConfig> whenParseDestinationConfig() {
      return whenParseConfig<DestinationConfig>(
        destinationParties,
        destinationConfigMap,
        destinationParty,
        destinationConfigParser,
      );
    }

    tearDown(() {
      reset(sourceParties);
      reset(destinationParties);
      reset(sourceParty);
      reset(destinationParty);
      reset(sourceConfigParser);
      reset(destinationConfigParser);
    });

    test(
      "creates an instance with the given supported integration parties",
      () {
        final configuredPartiesFactory = ConfiguredPartiesFactory(
          supportedParties: supportedParties,
        );

        expect(
          configuredPartiesFactory.supportedParties,
          equals(supportedParties),
        );
      },
    );

    test(
      "creates an instance with the default supported integration parties, if the given one is null",
      () {
        final configuredPartiesFactory = ConfiguredPartiesFactory(
          supportedParties: null,
        );

        expect(configuredPartiesFactory.supportedParties, isNotNull);
      },
    );

    test(
      ".create() throws an ArgumentError if the given raw integration config is null",
      () {
        expect(
          () => configuredPartiesFactory.create(null),
          throwsArgumentError,
        );
      },
    );

    test(
      ".create() gets the source party from the supported integration parties' source parties",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        configuredPartiesFactory.create(rawConfig);

        verify(sourceParties.getParty(sourceConfigMap)).called(once);
      },
    );

    test(
      ".create() parses the source config map to the source config using the source config parser",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        configuredPartiesFactory.create(rawConfig);

        verify(sourceConfigParser.parse(sourceConfigMap)).called(once);
      },
    );

    test(
      ".create() gets the destination party from the supported integration parties' destination parties",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        configuredPartiesFactory.create(rawConfig);

        verify(destinationParties.getParty(destinationConfigMap)).called(once);
      },
    );

    test(
      ".create() parses the destination config map to the destination config using the destination config parser",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        configuredPartiesFactory.create(rawConfig);

        verify(
          destinationConfigParser.parse(destinationConfigMap),
        ).called(once);
      },
    );

    test(
      ".create() returns the configured parties with the configured source party containing the source party",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        final configuredParties = configuredPartiesFactory.create(rawConfig);

        final configuredSourceParty = configuredParties.configuredSourceParty;

        expect(configuredSourceParty.party, equals(sourceParty));
      },
    );

    test(
      ".create() returns the configured parties with the configured source party containing the parsed source config",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        final configuredParties = configuredPartiesFactory.create(rawConfig);

        final configuredSourceParty = configuredParties.configuredSourceParty;

        expect(configuredSourceParty.config, equals(sourceConfig));
      },
    );

    test(
      ".create() returns the configured parties with the configured destination party containing the destination party",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        final configuredParties = configuredPartiesFactory.create(rawConfig);

        final configuredDestinationParty =
            configuredParties.configuredDestinationParty;

        expect(configuredDestinationParty.party, equals(destinationParty));
      },
    );

    test(
      ".create() returns the configured parties with the configured destination party containing the parsed destination config",
      () {
        whenParseSourceConfig().thenReturn(sourceConfig);
        whenParseDestinationConfig().thenReturn(destinationConfig);

        final configuredParties = configuredPartiesFactory.create(rawConfig);

        final configuredDestinationParty =
            configuredParties.configuredDestinationParty;

        expect(configuredDestinationParty.config, equals(destinationConfig));
      },
    );
  });
}

class _SourcePartyMock extends Mock implements SourceParty {}

class _DestinationPartyMock extends Mock implements DestinationParty {}
