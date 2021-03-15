// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:metrics/feature_config/presentation/view_models/debug_menu_feature_config_view_model.dart';

import '../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values,

void main() {
  group("DebugMenuFeatureConfigViewModel", () {
    test(
      "throws an AssertionError if the given is enabled is null",
      () {
        expect(
          () => DebugMenuFeatureConfigViewModel(isEnabled: null),
          throwsAssertionError,
        );
      },
    );

    test(
      "creates an instance with the given is enabled value",
      () {
        const isEnabled = false;

        const viewModel = DebugMenuFeatureConfigViewModel(
          isEnabled: isEnabled,
        );

        expect(viewModel.isEnabled, equals(isEnabled));
      },
    );
  });
}
