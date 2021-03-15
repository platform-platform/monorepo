// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/platform/web/browser_navigation_state/browser_navigation_state.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/history_mock.dart';
import '../../../test_utils/matchers.dart';

void main() {
  group("BrowserNavigationState", () {
    test("throws an AssertionError if the given history is null", () {
      expect(
        () => BrowserNavigationState(null),
        throwsAssertionError,
      );
    });

    test(".replaceState() delegates to the given history", () {
      const data = 'data';
      const title = 'metrics';
      const path = '/test';

      final history = HistoryMock();
      final navigationState = BrowserNavigationState(history);

      navigationState.replaceState(data, title, path);

      verify(history.replaceState(data, title, path)).called(once);
    });
  });
}
