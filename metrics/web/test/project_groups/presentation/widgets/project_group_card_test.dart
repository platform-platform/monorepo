// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/decorated_container.dart';
import 'package:metrics/base/presentation/widgets/icon_label_button.dart';
import 'package:metrics/common/presentation/button/theme/style/metrics_button_style.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/project_group_card_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/project_group_dialog_theme_data.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/project_groups/presentation/state/project_groups_notifier.dart';
import 'package:metrics/project_groups/presentation/strings/project_groups_strings.dart';
import 'package:metrics/project_groups/presentation/view_models/delete_project_group_dialog_view_model.dart';
import 'package:metrics/project_groups/presentation/view_models/project_group_card_view_model.dart';
import 'package:metrics/project_groups/presentation/view_models/project_group_dialog_view_model.dart';
import 'package:metrics/project_groups/presentation/widgets/delete_project_group_dialog.dart';
import 'package:metrics/project_groups/presentation/widgets/edit_project_group_dialog.dart';
import 'package:metrics/project_groups/presentation/widgets/project_group_card.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/finder_util.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/project_groups_notifier_mock.dart';
import '../../../test_utils/test_injection_container.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ProjectGroupCard", () {
    const projectGroupCardViewModel = ProjectGroupCardViewModel(
      id: 'id1',
      name: 'name1',
      projectsCount: 1,
    );

    const primaryButtonColor = Colors.blue;
    const accentButtonColor = Colors.amberAccent;
    const testBorderColor = Colors.red;
    const testBackgroundColor = Colors.white;
    const testHoverColor = Colors.black;
    const testTitleStyle = TextStyle(color: Colors.grey);
    const testSubtitleStyle = TextStyle(color: Colors.black);
    const primaryButtonStyle = MetricsButtonStyle(
      color: primaryButtonColor,
    );
    const accentButtonStyle = MetricsButtonStyle(
      color: accentButtonColor,
    );
    const testBarrierColor = Colors.red;

    const testTheme = MetricsThemeData(
      projectGroupCardTheme: ProjectGroupCardThemeData(
        primaryButtonStyle: primaryButtonStyle,
        accentButtonStyle: accentButtonStyle,
        backgroundColor: testBackgroundColor,
        hoverColor: testHoverColor,
        borderColor: testBorderColor,
        titleStyle: testTitleStyle,
        subtitleStyle: testSubtitleStyle,
      ),
      projectGroupDialogTheme: ProjectGroupDialogThemeData(
        barrierColor: testBarrierColor,
      ),
    );

    final mouseRegionFinder = find.descendant(
      of: find.byType(ProjectGroupCard),
      matching: find.byType(MouseRegion),
    );

    Future<void> _enterProjectGroupCard(WidgetTester tester) async {
      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
      const pointerEnterEvent = PointerEnterEvent();
      mouseRegion.onEnter(pointerEnterEvent);

      await tester.pump();
    }

    Future<void> _exitProjectGroupCard(WidgetTester tester) async {
      final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
      const pointerExitEvent = PointerExitEvent();
      mouseRegion.onExit(pointerExitEvent);

      await tester.pump();
    }

    testWidgets(
      "throws an AssertionError if the given project group card view model is null",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _ProjectGroupCardTestbed(projectGroupCardViewModel: null),
        );

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "applies the background color from theme if widget is not hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _ProjectGroupCardTestbed(
            theme: testTheme,
            projectGroupCardViewModel: projectGroupCardViewModel,
          ),
        );

        await _exitProjectGroupCard(tester);

        final decoration = FinderUtil.findBoxDecoration(tester);

        expect(decoration.color, equals(testBackgroundColor));
      },
    );

    testWidgets(
      "applies the hover color from theme if the widget is hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        final decoration = FinderUtil.findBoxDecoration(tester);

        expect(decoration.color, equals(testHoverColor));
      },
    );

    testWidgets(
      "applies the border color from the metrics theme to the decorated container",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        final decoration = FinderUtil.findBoxDecoration(tester);
        final border = decoration.border as Border;

        expect(border.top.color, equals(testBorderColor));
        expect(border.bottom.color, equals(testBorderColor));
        expect(border.left.color, equals(testBorderColor));
        expect(border.right.color, equals(testBorderColor));
      },
    );

    testWidgets(
      "applies the title style from the metrics theme to the name text",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        final textWidget = tester.widget<Text>(
          find.text(projectGroupCardViewModel.name),
        );

        expect(textWidget.style, equals(testTitleStyle));
      },
    );

    testWidgets(
      "applies the subtitle style from the metrics theme to the count text",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        final textWidget = tester.widget<Text>(
          find.text(
            ProjectGroupsStrings.getProjectsCount(
              projectGroupCardViewModel.projectsCount,
            ),
          ),
        );

        expect(textWidget.style, equals(testSubtitleStyle));
      },
    );

    testWidgets(
      "applies the primary color from the metrics theme to the edit button label",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        final label = tester.widget<Text>(
          find.text(CommonStrings.edit),
        );

        expect(label.style.color, equals(primaryButtonColor));
      },
    );

    testWidgets(
      "applies the primary color from the metrics theme to the delete button label",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        final label = tester.widget<Text>(
          find.text(CommonStrings.delete),
        );

        expect(label.style.color, equals(accentButtonColor));
      },
    );

    testWidgets(
      "hides the edit button if the widget is not hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _ProjectGroupCardTestbed(
            projectGroupCardViewModel: projectGroupCardViewModel,
          ),
        );

        await _exitProjectGroupCard(tester);

        expect(find.text(CommonStrings.edit), findsNothing);
      },
    );

    testWidgets(
      "shows the edit button if the widget is hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        expect(find.text(CommonStrings.edit), findsOneWidget);
      },
    );

    testWidgets(
      "hides the delete button if the widget is not hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await _exitProjectGroupCard(tester);

        expect(find.text(CommonStrings.delete), findsNothing);
      },
    );

    testWidgets(
      "shows the delete button if the widget is hovered",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          theme: testTheme,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        expect(find.text(CommonStrings.delete), findsOneWidget);
      },
    );

    testWidgets(
      "displays a name",
      (WidgetTester tester) async {
        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        expect(
          find.widgetWithText(
              DecoratedContainer, projectGroupCardViewModel.name),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "displays a projects count",
      (WidgetTester tester) async {
        final projectsCountText = ProjectGroupsStrings.getProjectsCount(
          projectGroupCardViewModel.projectsCount,
        );

        await tester.pumpWidget(const _ProjectGroupCardTestbed(
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        expect(
          find.widgetWithText(DecoratedContainer, projectsCountText),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "applies the barrier color from the metrics theme to the edit project group dialog",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();
        when(projectGroupsNotifier.projectCheckboxViewModels).thenReturn([]);

        when(projectGroupsNotifier.projectGroupDialogViewModel).thenReturn(
          ProjectGroupDialogViewModel(
            selectedProjectIds: UnmodifiableListView([]),
          ),
        );

        await tester.pumpWidget(_ProjectGroupCardTestbed(
          projectGroupsNotifier: projectGroupsNotifier,
          projectGroupCardViewModel: projectGroupCardViewModel,
          theme: testTheme,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.edit),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpAndSettle();
        });

        final barrierFinder = find.byWidgetPredicate(
          (widget) =>
              widget is ModalBarrier && widget.color == testBarrierColor,
        );
        expect(barrierFinder, findsOneWidget);
      },
    );

    testWidgets(
      "shows the update project group dialog on tap on the edit button",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.projectGroupDialogViewModel).thenReturn(
          ProjectGroupDialogViewModel(
            selectedProjectIds: UnmodifiableListView([]),
          ),
        );

        await tester.pumpWidget(_ProjectGroupCardTestbed(
          projectGroupsNotifier: projectGroupsNotifier,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.edit),
        );

        await tester.pump();

        expect(find.byType(EditProjectGroupDialog), findsOneWidget);
      },
    );

    testWidgets(
      "inits project group dialog view model on tap on the edit button",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();
        const projectId = 'id1';

        when(projectGroupsNotifier.projectGroupDialogViewModel).thenReturn(
          ProjectGroupDialogViewModel(
            id: projectId,
            name: 'name',
            selectedProjectIds: UnmodifiableListView([]),
          ),
        );

        await tester.pumpWidget(
          _ProjectGroupCardTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
            projectGroupCardViewModel: projectGroupCardViewModel,
          ),
        );

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.edit),
        );

        verify(projectGroupsNotifier.initProjectGroupDialogViewModel(
          projectId,
        )).called(once);
      },
    );

    testWidgets(
      "does not open the edit project group dialog if the project group dialog view model is null",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        await tester.pumpWidget(_ProjectGroupCardTestbed(
          projectGroupsNotifier: projectGroupsNotifier,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.edit),
        );
        await tester.pump();

        verify(projectGroupsNotifier.initProjectGroupDialogViewModel(any))
            .called(once);
        expect(find.byType(ProjectGroupDialogViewModel), findsNothing);
      },
    );

    testWidgets(
      "shows the delete project group dialog on tap on the delete button",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.deleteProjectGroupDialogViewModel)
            .thenReturn(
          const DeleteProjectGroupDialogViewModel(
            id: "id",
            name: "name",
          ),
        );

        await tester.pumpWidget(_ProjectGroupCardTestbed(
          projectGroupsNotifier: projectGroupsNotifier,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.delete),
        );

        await tester.pump();

        expect(find.byType(DeleteProjectGroupDialog), findsOneWidget);
      },
    );

    testWidgets(
      "applies the barrier color from the metrics theme to the delete project group dialog",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(projectGroupsNotifier.deleteProjectGroupDialogViewModel)
            .thenReturn(
          const DeleteProjectGroupDialogViewModel(
            id: "id",
            name: "name",
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_ProjectGroupCardTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
            projectGroupCardViewModel: projectGroupCardViewModel,
            theme: testTheme,
          ));
        });

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.delete),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpAndSettle();
        });

        final barrierFinder = find.byWidgetPredicate(
          (widget) =>
              widget is ModalBarrier && widget.color == testBarrierColor,
        );
        expect(barrierFinder, findsOneWidget);
      },
    );

    testWidgets(
      "inits the delete project group dialog view model on tap on the delete button",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        when(
          projectGroupsNotifier.deleteProjectGroupDialogViewModel,
        ).thenReturn(
          const DeleteProjectGroupDialogViewModel(id: 'id1', name: 'name'),
        );

        await tester.pumpWidget(_ProjectGroupCardTestbed(
          projectGroupsNotifier: projectGroupsNotifier,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.delete),
        );

        verify(projectGroupsNotifier.initDeleteProjectGroupDialogViewModel(any))
            .called(once);
      },
    );

    testWidgets(
      "does not open the delete project group dialog if the delete project group dialog view model is null",
      (WidgetTester tester) async {
        final projectGroupsNotifier = ProjectGroupsNotifierMock();

        await tester.pumpWidget(_ProjectGroupCardTestbed(
          projectGroupsNotifier: projectGroupsNotifier,
          projectGroupCardViewModel: projectGroupCardViewModel,
        ));

        await mockNetworkImagesFor(() async {
          await _enterProjectGroupCard(tester);
        });

        await tester.tap(
          find.widgetWithText(IconLabelButton, CommonStrings.delete),
        );
        await tester.pump();

        verify(projectGroupsNotifier.initDeleteProjectGroupDialogViewModel(any))
            .called(once);
        expect(find.byType(DeleteProjectGroupDialog), findsNothing);
      },
    );
  });
}

/// A testbed widget, used to test the [ProjectGroupCard] widget.
class _ProjectGroupCardTestbed extends StatelessWidget {
  /// A project group card view model with project group data to display.
  final ProjectGroupCardViewModel projectGroupCardViewModel;

  /// A [ProjectGroupsNotifier] used in testbed.
  final ProjectGroupsNotifier projectGroupsNotifier;

  /// The [MetricsThemeData] used in testbed.
  final MetricsThemeData theme;

  /// Creates the [_ProjectGroupCardTestbed] with the given [theme]
  /// and the [projectGroupCardViewModel].
  const _ProjectGroupCardTestbed({
    Key key,
    this.theme = const MetricsThemeData(),
    this.projectGroupsNotifier,
    this.projectGroupCardViewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      projectGroupsNotifier: projectGroupsNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: theme,
        body: ProjectGroupCard(
          projectGroupCardViewModel: projectGroupCardViewModel,
        ),
      ),
    );
  }
}
