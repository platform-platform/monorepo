// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/parties/parties.dart';
import 'package:ci_integration/integration/interface/source/party/source_party.dart';
import 'package:ci_integration/source/buildkite/party/buildkite_source_party.dart';
import 'package:ci_integration/source/github_actions/party/github_actions_source_party.dart';
import 'package:ci_integration/source/jenkins/party/jenkins_source_party.dart';

/// A class providing all the supported source integrations.
class SupportedSourceParties extends Parties<SourceParty> {
  @override
  final List<SourceParty> parties = List.unmodifiable([
    JenkinsSourceParty(),
    GithubActionsSourceParty(),
    BuildkiteSourceParty(),
  ]);
}
