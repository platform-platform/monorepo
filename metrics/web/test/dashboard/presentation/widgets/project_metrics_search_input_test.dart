// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/common/presentation/widgets/metrics_input_placeholder.dart';
import 'package:metrics/dashboard/presentation/state/project_metrics_notifier.dart';
import 'package:metrics/dashboard/presentation/widgets/project_metrics_search_input.dart';
import 'package:metrics/dashboard/presentation/widgets/projects_search_input.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/project_metrics_notifier_mock.dart';
import '../../../test_utils/test_injection_container.dart';

void main() {
  group("ProjectMetricsSearchInput", () {
    testWidgets(
      "displays the metrics input placeholder if project metrics are loading",
      (tester) async {
        final notifier = ProjectMetricsNotifierMock();
        when(notifier.isMetricsLoading).thenReturn(true);

        await tester.pumpWidget(_ProjectMetricsSearchInputTestbed(
          metricsNotifier: notifier,
        ));

        expect(find.byType(MetricsInputPlaceholder), findsOneWidget);
      },
    );

    testWidgets(
      "displays the project search input if project metrics are not loading",
      (tester) async {
        final notifier = ProjectMetricsNotifierMock();
        when(notifier.isMetricsLoading).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectMetricsSearchInputTestbed(
            metricsNotifier: notifier,
          ));
        });

        expect(find.byType(ProjectSearchInput), findsOneWidget);
      },
    );

    testWidgets(
      "filters the projects by the given name on project search input value changes",
      (tester) async {
        const searchText = "search";
        final notifier = ProjectMetricsNotifierMock();
        when(notifier.isMetricsLoading).thenReturn(false);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectMetricsSearchInputTestbed(
            metricsNotifier: notifier,
          ));
        });

        await tester.enterText(find.byType(ProjectSearchInput), searchText);

        verify(notifier.filterByProjectName(searchText)).called(once);
      },
    );
  });
}

/// A testbed class required to test the [ProjectMetricsSearchInput] widget.
class _ProjectMetricsSearchInputTestbed extends StatelessWidget {
  /// A [ProjectMetricsNotifier] that will injected and used in tests.
  final ProjectMetricsNotifier metricsNotifier;

  /// Creates an instance of the project metrics search input testbed
  /// with the given [metricsNotifier].
  const _ProjectMetricsSearchInputTestbed({
    Key key,
    this.metricsNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetricsThemedTestbed(
      body: TestInjectionContainer(
        metricsNotifier: metricsNotifier,
        child: ProjectMetricsSearchInput(),
      ),
    );
  }
}
