// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/source/github_actions/client_factory/github_actions_source_client_factory.dart';
import 'package:ci_integration/source/github_actions/config/parser/github_actions_source_config_parser.dart';
import 'package:ci_integration/source/github_actions/config/validator_factory/github_actions_source_validator_factory.dart';
import 'package:ci_integration/source/github_actions/party/github_actions_source_party.dart';
import 'package:test/test.dart';

void main() {
  group("GithubActionsSourceParty", () {
    final party = GithubActionsSourceParty();

    test(
      "uses GithubActionsSourceClientFactory as a client factory",
      () {
        final clientFactory = party.clientFactory;

        expect(clientFactory, isA<GithubActionsSourceClientFactory>());
      },
    );

    test(
      "uses GithubActionsSourceConfigParser as a config parser",
      () {
        final configParser = party.configParser;

        expect(configParser, isA<GithubActionsSourceConfigParser>());
      },
    );

    test(
      "uses GithubActionsSourceValidatorFactory as a validator factory",
      () {
        final validatorFactory = party.configValidatorFactory;

        expect(validatorFactory, isA<GithubActionsSourceValidatorFactory>());
      },
    );
  });
}
