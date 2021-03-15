// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/svg_image.dart';
import 'package:metrics/common/presentation/button/widgets/metrics_negative_button.dart';
import 'package:metrics/common/presentation/button/widgets/metrics_neutral_button.dart';
import 'package:metrics/common/presentation/metrics_theme/model/delete_dialog_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/strings/common_strings.dart';
import 'package:metrics/common/presentation/toast/widgets/negative_toast.dart';
import 'package:metrics/common/presentation/toast/widgets/positive_toast.dart';
import 'package:metrics/project_groups/presentation/state/project_groups_notifier.dart';
import 'package:metrics/project_groups/presentation/strings/project_groups_strings.dart';
import 'package:metrics/project_groups/presentation/view_models/delete_project_group_dialog_view_model.dart';
import 'package:metrics/project_groups/presentation/widgets/delete_project_group_dialog.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/finder_util.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/project_groups_notifier_mock.dart';
import '../../../test_utils/test_injection_container.dart';

void main() {
  group("DeleteProjectGroupDialog", () {
    ProjectGroupsNotifier projectGroupsNotifier;
    const deleteProjectGroupDialogViewModel = DeleteProjectGroupDialogViewModel(
      id: 'id',
      name: 'name',
    );

    const backgroundColor = Colors.yellow;
    const titleTextStyle = TextStyle(color: Colors.black);
    const contentTextStyle = TextStyle(inherit: false, color: Colors.red);

    const metricsThemeData = MetricsThemeData(
      deleteDialogTheme: DeleteDialogThemeData(
        backgroundColor: backgroundColor,
        titleTextStyle: titleTextStyle,
        contentTextStyle: contentTextStyle,
      ),
    );

    final themeData = ThemeData(
      textTheme: const TextTheme(bodyText1: contentTextStyle),
    );

    final contentStyle = themeData.textTheme.bodyText1
        .merge(metricsThemeData.deleteDialogTheme.contentTextStyle);

    final cancelButtonFinder = find.widgetWithText(
      MetricsNeutralButton,
      CommonStrings.cancel,
    );

    final deleteButtonFinder = find.widgetWithText(
      MetricsNegativeButton,
      ProjectGroupsStrings.delete,
    );

    List<TextSpan> getContentTextSpans(WidgetTester tester) {
      final infoDialog = FinderUtil.findInfoDialog(tester);

      final content = infoDialog.content as RichText;
      final textSpan = content.text as TextSpan;
      return List<TextSpan>.from(textSpan.children);
    }

    setUp(() {
      projectGroupsNotifier = ProjectGroupsNotifierMock();
      when(projectGroupsNotifier.deleteProjectGroupDialogViewModel)
          .thenReturn(deleteProjectGroupDialogViewModel);
    });

    tearDown(() {
      reset(projectGroupsNotifier);
    });

    testWidgets(
      "applies the close icon to the info dialog widget",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        final infoDialog = FinderUtil.findInfoDialog(tester);

        final closeIconImage = infoDialog.closeIcon as SvgImage;

        expect(closeIconImage.src, equals('icons/close.svg'));
      },
    );

    testWidgets(
      "applies the background color from the metrics theme",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed(
            metricsThemeData: metricsThemeData,
          ));
        });

        final infoDialog = FinderUtil.findInfoDialog(tester);

        expect(infoDialog.backgroundColor, equals(backgroundColor));
      },
    );

    testWidgets(
      "displays the delete project group title",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        expect(
          find.text(ProjectGroupsStrings.deleteProjectGroup),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "applies the title style from the metrics theme",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed(
            metricsThemeData: metricsThemeData,
          ));
        });

        final title = tester.widget<Text>(
          find.text(ProjectGroupsStrings.deleteProjectGroup),
        );

        expect(title.style, equals(titleTextStyle));
      },
    );

    testWidgets(
      "displays the delete confirmation text",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        final infoDialog = FinderUtil.findInfoDialog(tester);

        final content = infoDialog.content as RichText;
        final textSpan = content.text as TextSpan;

        expect(textSpan.text, equals(ProjectGroupsStrings.deleteConfirmation));
      },
    );

    testWidgets(
      "applies the content style from the metrics theme",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            themeData: themeData,
            metricsThemeData: metricsThemeData,
          ));
        });

        final infoDialog = FinderUtil.findInfoDialog(tester);

        final content = infoDialog.content as RichText;
        final textSpan = content.text as TextSpan;

        expect(textSpan.style, equals(contentStyle));
      },
    );

    testWidgets(
      "displays the delete confirmation question text",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        final contentTextSpan = getContentTextSpans(tester);

        final confirmationTextFinder = contentTextSpan.any(
          (span) =>
              span.text == ProjectGroupsStrings.deleteConfirmationQuestion,
        );

        expect(confirmationTextFinder, isTrue);
      },
    );

    testWidgets(
      "displays the name of the project group to delete",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        final contentTextSpans = getContentTextSpans(tester);

        final isGroupNameDisplayed = contentTextSpans.any(
          (span) => span.text == ' ${deleteProjectGroupDialogViewModel.name} ',
        );

        expect(isGroupNameDisplayed, isTrue);
      },
    );

    testWidgets(
      "applies the text style from theme to the project group name to delete",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            metricsThemeData: metricsThemeData,
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        final boldContentStyle = contentStyle.copyWith(
          fontWeight: FontWeight.bold,
        );

        final contentTextSpans = getContentTextSpans(tester);

        final groupNameSpan = contentTextSpans.firstWhere(
          (span) => span.text == ' ${deleteProjectGroupDialogViewModel.name} ',
          orElse: () => null,
        );

        expect(groupNameSpan?.style, equals(boldContentStyle));
      },
    );

    testWidgets(
      "closes the dialog on tap on the cancel button",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        await tester.tap(cancelButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(DeleteProjectGroupDialog), findsNothing);
      },
    );

    testWidgets(
      "deletes the project group on tap on the delete button",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(deleteButtonFinder);
        await tester.pump();

        verify(projectGroupsNotifier.deleteProjectGroup(
          deleteProjectGroupDialogViewModel.id,
        )).called(once);
      },
    );

    testWidgets(
      "disables the delete button if the deleting is in progress",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        await tester.tap(deleteButtonFinder);
        await tester.pump();
        await tester.idle();

        final deleteButton = tester.widget<RaisedButton>(
          find.descendant(
            of: find.byType(MetricsNegativeButton),
            matching: find.byWidgetPredicate(
              (widget) => widget is RaisedButton,
            ),
          ),
        );

        expect(deleteButton.enabled, isFalse);
      },
    );

    testWidgets(
      "displays the deleting project group text on tap on the delete button",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        await tester.tap(deleteButtonFinder);
        await tester.pump();
        await tester.idle();

        final deletingProjectGroupFinder = find.widgetWithText(
          MetricsNegativeButton,
          ProjectGroupsStrings.deletingProjectGroup,
        );

        expect(deletingProjectGroupFinder, findsOneWidget);
      },
    );

    testWidgets(
      "closes the dialog if the project group deleting is successful",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _DeleteProjectGroupDialogTestbed());
        });

        await tester.tap(deleteButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(DeleteProjectGroupDialog), findsNothing);
      },
    );

    testWidgets(
      "does not close the dialog if the deleting is finished with an error",
      (tester) async {
        when(projectGroupsNotifier.projectGroupSavingError).thenReturn('error');

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(deleteButtonFinder);
        await tester.pumpAndSettle();

        expect(find.byType(DeleteProjectGroupDialog), findsOneWidget);
      },
    );

    testWidgets(
      "displays the delete project group button text if the deleting is finished with an error",
      (tester) async {
        when(projectGroupsNotifier.projectGroupSavingError).thenReturn('error');

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(deleteButtonFinder);
        await tester.pumpAndSettle();

        expect(deleteButtonFinder, findsOneWidget);
      },
    );

    testWidgets(
      "displays a negative toast with an error message if an action finished with en error",
      (tester) async {
        const message = 'error message';
        when(projectGroupsNotifier.projectGroupSavingError).thenReturn(message);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(find.text(ProjectGroupsStrings.delete));
        await tester.pump();

        expect(find.widgetWithText(NegativeToast, message), findsOneWidget);
      },
    );

    testWidgets(
      "resets a delete project group dialog view model on dispose",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(cancelButtonFinder);
        await tester.pumpAndSettle();

        verify(projectGroupsNotifier.resetDeleteProjectGroupDialogViewModel())
            .called(once);
      },
    );

    testWidgets(
      "displays a positive toast with a delete project group message if an action finished successfully",
      (tester) async {
        final message = ProjectGroupsStrings.getDeletedProjectGroupMessage(
          deleteProjectGroupDialogViewModel.name,
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_DeleteProjectGroupDialogTestbed(
            projectGroupsNotifier: projectGroupsNotifier,
          ));
        });

        await tester.tap(find.text(ProjectGroupsStrings.delete));
        await tester.pump();

        expect(find.widgetWithText(PositiveToast, message), findsOneWidget);
      },
    );
  });
}

/// A testbed class required to test the [DeleteProjectGroupDialog] widget.
///
/// Dismisses all shown [Toast]s on dispose.
class _DeleteProjectGroupDialogTestbed extends StatefulWidget {
  /// A [ProjectGroupsNotifier] that will be injected and used in tests.
  final ProjectGroupsNotifier projectGroupsNotifier;

  /// The [MetricsThemeData] used in testbed.
  final MetricsThemeData metricsThemeData;

  /// The [ThemeData] used in testbed.
  final ThemeData themeData;

  /// Creates a new instance of the [_DeleteProjectGroupDialogTestbed]
  /// with the given [projectGroupsNotifier], [metricsThemeData]
  /// and [themeData].
  ///
  /// The [metricsThemeData] defaults to an empty [MetricsThemeData].
  const _DeleteProjectGroupDialogTestbed({
    Key key,
    this.projectGroupsNotifier,
    this.metricsThemeData = const MetricsThemeData(),
    this.themeData,
  }) : super(key: key);

  @override
  __DeleteProjectGroupDialogTestbedState createState() =>
      __DeleteProjectGroupDialogTestbedState();
}

class __DeleteProjectGroupDialogTestbedState
    extends State<_DeleteProjectGroupDialogTestbed> {
  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      projectGroupsNotifier: widget.projectGroupsNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: widget.metricsThemeData,
        themeData: widget.themeData,
        body: DeleteProjectGroupDialog(),
      ),
    );
  }

  @override
  void dispose() {
    ToastManager().dismissAll();
    super.dispose();
  }
}
