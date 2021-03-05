// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/interface/source/party/source_party.dart';
import 'package:ci_integration/source/buildkite/adapter/buildkite_source_client_adapter.dart';
import 'package:ci_integration/source/buildkite/client_factory/buildkite_source_client_factory.dart';
import 'package:ci_integration/source/buildkite/config/model/buildkite_source_config.dart';
import 'package:ci_integration/source/buildkite/config/parser/buildkite_source_config_parser.dart';
import 'package:ci_integration/source/buildkite/config/vaildator_factory/buildkite_source_validator_factory.dart';

/// An integration party for the Buildkite source integration.
class BuildkiteSourceParty
    extends SourceParty<BuildkiteSourceConfig, BuildkiteSourceClientAdapter> {
  @override
  final BuildkiteSourceClientFactory clientFactory =
      const BuildkiteSourceClientFactory();

  @override
  final BuildkiteSourceConfigParser configParser =
      const BuildkiteSourceConfigParser();

  @override
  final ConfigValidatorFactory<BuildkiteSourceConfig> configValidatorFactory =
      const BuildkiteSourceValidatorFactory();
}
