// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/project_group_dialog_theme_data.dart';
import 'package:metrics/common/presentation/widgets/metrics_checkbox.dart';
import 'package:metrics/project_groups/presentation/state/project_groups_notifier.dart';
import 'package:metrics/project_groups/presentation/view_models/project_checkbox_view_model.dart';
import 'package:metrics/project_groups/presentation/widgets/project_checkbox_list_tile.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/project_groups_notifier_mock.dart';
import '../../../test_utils/test_injection_container.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ProjectCheckboxListTile", () {
    const metricsThemeData = MetricsThemeData(
      projectGroupDialogTheme: ProjectGroupDialogThemeData(
        checkedProjectTextStyle: TextStyle(
          color: Colors.blue,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
        uncheckedProjectTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16.0,
        ),
      ),
    );

    const projectCheckboxViewModel = ProjectCheckboxViewModel(
      id: 'id',
      name: 'name',
      isChecked: false,
    );

    testWidgets(
      "throws an AssertionError if the given project checkbox view model is null",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectCheckboxListTileTestbed(
          projectCheckboxViewModel: null,
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "displays the name of the given project checkbox view model",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectCheckboxListTileTestbed(
              projectCheckboxViewModel: projectCheckboxViewModel,
            ),
          );
        });

        final checkboxListTileFinder = find.text(
          projectCheckboxViewModel.name,
        );

        expect(checkboxListTileFinder, findsOneWidget);
      },
    );

    testWidgets(
      "applies the checkbox value corresponding to the project checkbox view model is checked value",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectCheckboxListTileTestbed(
              projectCheckboxViewModel: projectCheckboxViewModel,
            ),
          );
        });

        final widget = tester.widget<MetricsCheckbox>(
          find.byType(MetricsCheckbox),
        );

        expect(widget.value, equals(projectCheckboxViewModel.isChecked));
      },
    );

    testWidgets(
      "toggles the project checkbox status on tap",
      (WidgetTester tester) async {
        final projectGroupsNotifierMock = ProjectGroupsNotifierMock();

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectCheckboxListTileTestbed(
              projectGroupsNotifier: projectGroupsNotifierMock,
              projectCheckboxViewModel: projectCheckboxViewModel,
            ),
          );
        });

        final finder = find.text(projectCheckboxViewModel.name);
        await tester.tap(finder);
        await tester.pump();

        verify(
          projectGroupsNotifierMock.toggleProjectCheckedStatus(
            projectCheckboxViewModel.id,
          ),
        ).called(once);
      },
    );

    testWidgets(
      "applies the unchecked project name text style from theme to the name of the unchecked project",
      (WidgetTester tester) async {
        final themeUncheckedTextStyle =
            metricsThemeData.projectGroupDialogTheme.uncheckedProjectTextStyle;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _ProjectCheckboxListTileTestbed(
            metricsThemeData: metricsThemeData,
            projectCheckboxViewModel: projectCheckboxViewModel,
          ));
        });

        final text = tester.widget<Text>(
          find.text(projectCheckboxViewModel.name),
        );

        expect(text.style, equals(themeUncheckedTextStyle));
      },
    );

    testWidgets(
      "applies the checked project name text style from theme to the name of the checked project",
      (WidgetTester tester) async {
        const projectCheckboxViewModel = ProjectCheckboxViewModel(
          id: 'id',
          name: 'name',
          isChecked: true,
        );
        final themeCheckedTextStyle =
            metricsThemeData.projectGroupDialogTheme.checkedProjectTextStyle;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _ProjectCheckboxListTileTestbed(
            metricsThemeData: metricsThemeData,
            projectCheckboxViewModel: projectCheckboxViewModel,
          ));
        });

        final text = tester.widget<Text>(
          find.text(projectCheckboxViewModel.name),
        );

        expect(text.style, equals(themeCheckedTextStyle));
      },
    );
  });
}

/// A testbed class required to test the [ProjectCheckboxListTile] widget.
class _ProjectCheckboxListTileTestbed extends StatelessWidget {
  /// A [MetricsThemeData]to use in tests.
  final MetricsThemeData metricsThemeData;

  /// A [ProjectGroupsNotifier] that will be injected and used in tests.
  final ProjectGroupsNotifier projectGroupsNotifier;

  /// A view model with the data to display within this widget.
  final ProjectCheckboxViewModel projectCheckboxViewModel;

  /// Creates a new instance of the [_ProjectCheckboxListTileTestbed]
  /// with the given [projectCheckboxViewModel].
  ///
  /// The [metricsThemeData] defaults to an empty [MetricsThemeData] instance.
  const _ProjectCheckboxListTileTestbed({
    Key key,
    this.metricsThemeData = const MetricsThemeData(),
    this.projectCheckboxViewModel,
    this.projectGroupsNotifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      projectGroupsNotifier: projectGroupsNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: metricsThemeData,
        body: ProjectCheckboxListTile(
          projectCheckboxViewModel: projectCheckboxViewModel,
        ),
      ),
    );
  }
}
