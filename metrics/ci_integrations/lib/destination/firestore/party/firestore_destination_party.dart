// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/destination/firestore/adapter/firestore_destination_client_adapter.dart';
import 'package:ci_integration/destination/firestore/client_factory/firestore_destination_client_factory.dart';
import 'package:ci_integration/destination/firestore/config/model/firestore_destination_config.dart';
import 'package:ci_integration/destination/firestore/config/parser/firestore_destination_config_parser.dart';
import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/interface/destination/party/destination_party.dart';
import 'package:ci_integration/integration/stub/base/config/validator_factory/config_validator_factory_stub.dart';

/// An integration party for the Firestore destination integration.
class FirestoreDestinationParty extends DestinationParty<
    FirestoreDestinationConfig, FirestoreDestinationClientAdapter> {
  @override
  final FirestoreDestinationClientFactory clientFactory =
      const FirestoreDestinationClientFactory();

  @override
  final FirestoreDestinationConfigParser configParser =
      const FirestoreDestinationConfigParser();

  @override
  final ConfigValidatorFactory<FirestoreDestinationConfig>
      configValidatorFactory = const ConfigValidatorFactoryStub();
}
