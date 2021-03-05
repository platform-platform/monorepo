// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/parties/parties.dart';
import 'package:ci_integration/destination/firestore/party/firestore_destination_party.dart';
import 'package:ci_integration/integration/interface/destination/party/destination_party.dart';

/// A class providing all the supported destination integrations.
class SupportedDestinationParties extends Parties<DestinationParty> {
  @override
  final List<DestinationParty> parties = List.unmodifiable([
    FirestoreDestinationParty(),
  ]);
}
