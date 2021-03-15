// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/base/presentation/widgets/decorated_container.dart';
import 'package:metrics/base/presentation/widgets/dropdown_menu.dart';
import 'package:metrics/base/presentation/widgets/svg_image.dart';
import 'package:metrics/common/presentation/metrics_theme/model/dropdown_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/widgets/metrics_input_placeholder.dart';
import 'package:metrics/dashboard/presentation/state/project_metrics_notifier.dart';
import 'package:metrics/dashboard/presentation/view_models/project_group_dropdown_item_view_model.dart';
import 'package:metrics/dashboard/presentation/widgets/project_groups_dropdown_body.dart';
import 'package:metrics/dashboard/presentation/widgets/project_groups_dropdown_item.dart';
import 'package:metrics/dashboard/presentation/widgets/project_groups_dropdown_menu.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/project_metrics_notifier_mock.dart';
import '../../../test_utils/test_injection_container.dart';

void main() {
  group("ProjectGroupsDropdownMenu", () {
    ProjectMetricsNotifier metricsNotifier;

    const firstDropdownItem = ProjectGroupDropdownItemViewModel(
      id: '1',
      name: 'name1',
    );

    const secondDropdownItem = ProjectGroupDropdownItemViewModel(
      id: '2',
      name: 'name2',
    );

    const dropdownItems = [firstDropdownItem, secondDropdownItem];

    final mouseRegionFinder = find.descendant(
      of: find.byType(ProjectGroupsDropdownMenu),
      matching: find.byType(MouseRegion).last,
    );

    final dropdownMenuFinder = find.byWidgetPredicate(
      (widget) => widget is DropdownMenu,
    );

    DecoratedContainer _getDecoratedContainer(WidgetTester tester) {
      return tester.widget<DecoratedContainer>(find.descendant(
        of: find.byType(ProjectGroupsDropdownMenu),
        matching: find.byType(DecoratedContainer),
      ));
    }

    setUp(() {
      metricsNotifier = ProjectMetricsNotifierMock();
      when(metricsNotifier.projectGroupDropdownItems).thenReturn(dropdownItems);
    });

    testWidgets(
      "applies the closed button background color from metrics theme",
      (tester) async {
        const backgroundColor = Colors.red;
        const theme = MetricsThemeData(
          dropdownTheme: DropdownThemeData(
            closedButtonBackgroundColor: backgroundColor,
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectGroupsDropdownMenuTestbed(
              theme: theme,
            ),
          );
        });

        final buttonContainer = _getDecoratedContainer(tester);

        final buttonDecoration = buttonContainer.decoration as BoxDecoration;

        expect(buttonDecoration.color, equals(backgroundColor));
      },
    );

    testWidgets(
      "applies the opened button background color from the metrics theme if the dropdown is opened",
      (tester) async {
        const backgroundColor = Colors.red;
        const theme = MetricsThemeData(
          dropdownTheme: DropdownThemeData(
            openedButtonBackgroundColor: backgroundColor,
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectGroupsDropdownMenuTestbed(
              theme: theme,
            ),
          );
        });

        await tester.tap(find.byType(ProjectGroupsDropdownMenu));
        await tester.pumpAndSettle();

        final buttonContainer = _getDecoratedContainer(tester);

        final buttonDecoration = buttonContainer.decoration as BoxDecoration;

        expect(buttonDecoration.color, equals(backgroundColor));
      },
    );

    testWidgets(
      "applies the hover background color from the metrics theme if the dropdown is hovered",
      (tester) async {
        const backgroundColor = Colors.red;
        const theme = MetricsThemeData(
          dropdownTheme: DropdownThemeData(
            hoverBackgroundColor: backgroundColor,
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectGroupsDropdownMenuTestbed(
              theme: theme,
            ),
          );
        });

        final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
        const pointerEnterEvent = PointerEnterEvent();
        mouseRegion.onEnter(pointerEnterEvent);

        await tester.pump();

        final buttonContainer = _getDecoratedContainer(tester);

        final buttonDecoration = buttonContainer.decoration as BoxDecoration;

        expect(buttonDecoration.color, equals(backgroundColor));
      },
    );

    testWidgets(
      "applies the closed button border color from the metrics theme if the dropdown is closed",
      (tester) async {
        const borderColor = Colors.red;
        const theme = MetricsThemeData(
          dropdownTheme: DropdownThemeData(
            closedButtonBorderColor: borderColor,
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectGroupsDropdownMenuTestbed(
              theme: theme,
            ),
          );
        });

        final buttonContainer = _getDecoratedContainer(tester);

        final buttonDecoration = buttonContainer.decoration as BoxDecoration;
        final boxBorder = buttonDecoration.border as Border;

        expect(boxBorder.top.color, equals(borderColor));
        expect(boxBorder.bottom.color, equals(borderColor));
        expect(boxBorder.right.color, equals(borderColor));
        expect(boxBorder.left.color, equals(borderColor));
      },
    );

    testWidgets(
      "applies the opened button border color from the metrics theme if the dropdown is opened",
      (tester) async {
        const borderColor = Colors.red;
        const theme = MetricsThemeData(
          dropdownTheme: DropdownThemeData(
            openedButtonBorderColor: borderColor,
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectGroupsDropdownMenuTestbed(
              theme: theme,
            ),
          );
        });

        await tester.tap(find.byType(ProjectGroupsDropdownMenu));
        await tester.pumpAndSettle();

        final buttonContainer = _getDecoratedContainer(tester);

        final buttonDecoration = buttonContainer.decoration as BoxDecoration;
        final boxBorder = buttonDecoration.border as Border;

        expect(boxBorder.top.color, equals(borderColor));
        expect(boxBorder.bottom.color, equals(borderColor));
        expect(boxBorder.right.color, equals(borderColor));
        expect(boxBorder.left.color, equals(borderColor));
      },
    );

    testWidgets(
      "applies the hover border color from the metrics theme if the dropdown is hovered",
      (tester) async {
        const borderColor = Colors.red;
        const theme = MetricsThemeData(
          dropdownTheme: DropdownThemeData(
            hoverBorderColor: borderColor,
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            const _ProjectGroupsDropdownMenuTestbed(
              theme: theme,
            ),
          );
        });

        final mouseRegion = tester.widget<MouseRegion>(mouseRegionFinder);
        const pointerEnterEvent = PointerEnterEvent();
        mouseRegion.onEnter(pointerEnterEvent);

        await tester.pump();

        final buttonContainer = _getDecoratedContainer(tester);

        final buttonDecoration = buttonContainer.decoration as BoxDecoration;
        final boxBorder = buttonDecoration.border as Border;

        expect(boxBorder.top.color, equals(borderColor));
        expect(boxBorder.bottom.color, equals(borderColor));
        expect(boxBorder.right.color, equals(borderColor));
        expect(boxBorder.left.color, equals(borderColor));
      },
    );

    testWidgets(
      "applies the text style from the metrics theme to the button text",
      (tester) async {
        const textStyle = TextStyle(fontSize: 13.0);

        const theme = MetricsThemeData(
          dropdownTheme: DropdownThemeData(
            textStyle: textStyle,
          ),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(
              metricsNotifier: metricsNotifier,
              theme: theme,
            ),
          );
        });

        final textContainer = tester.widget<Text>(find.descendant(
          of: find.byType(ProjectGroupsDropdownMenu),
          matching: find.byType(Text),
        ));

        expect(textContainer.style, equals(textStyle));
      },
    );

    Future<void> openDropdownMenu(WidgetTester tester) async {
      await tester.tap(find.byType(ProjectGroupsDropdownMenu));
      await tester.pumpAndSettle();
    }

    testWidgets(
      "contains the dropdown menu widget",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(metricsNotifier: metricsNotifier),
          );
        });

        expect(
          dropdownMenuFinder,
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "displays the metrics input loading placeholder if project group dropdown items are null",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(
              metricsNotifier: ProjectMetricsNotifierMock(),
            ),
          );
        });

        expect(find.byType(MetricsInputPlaceholder), findsOneWidget);
      },
    );

    testWidgets(
      "displays the metrics input loading placeholder if project group dropdown items are empty",
      (tester) async {
        final metricsNotifier = ProjectMetricsNotifierMock();
        when(metricsNotifier.projectGroupDropdownItems).thenReturn([]);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(metricsNotifier: metricsNotifier),
          );
        });

        expect(find.byType(MetricsInputPlaceholder), findsOneWidget);
      },
    );

    testWidgets(
      "does not overflow on a very long project group name",
      (tester) async {
        when(metricsNotifier.projectGroupDropdownItems).thenReturn(const [
          ProjectGroupDropdownItemViewModel(
            name:
                'Some very long name to test that project groups dropdown menu widget does not overflows with a very long text in it',
          ),
        ]);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(metricsNotifier: metricsNotifier),
          );
        });

        expect(
          tester.takeException(),
          isNull,
        );
      },
    );

    testWidgets(
      "applies the project group dropdown items to the dropdown menu widget",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(metricsNotifier: metricsNotifier),
          );
        });

        final dropdownMenu = tester.widget<DropdownMenu>(dropdownMenuFinder);

        expect(dropdownMenu.items, equals(dropdownItems));
      },
    );

    testWidgets(
      "displays a project groups dropdown body when opened",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(metricsNotifier: metricsNotifier),
          );
        });

        await openDropdownMenu(tester);

        expect(find.byType(ProjectGroupsDropdownBody), findsOneWidget);
      },
    );

    testWidgets(
      "displays the given items with the ProjectGroupDropdownItem widget",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(metricsNotifier: metricsNotifier),
          );
        });

        await openDropdownMenu(tester);

        final actualDropdownItems = tester
            .widgetList<ProjectGroupsDropdownItem>(
              find.byType(ProjectGroupsDropdownItem),
            )
            .map((item) => item.projectGroupDropdownItemViewModel)
            .toList();

        expect(listEquals(actualDropdownItems, dropdownItems), isTrue);
      },
    );

    testWidgets(
      "displays a dropdown button that contains the dropdown icon",
      (tester) async {
        const expectedAsset = 'icons/dropdown.svg';

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _ProjectGroupsDropdownMenuTestbed(metricsNotifier: metricsNotifier),
          );
        });

        final imageFinder = find.descendant(
          of: find.byType(ProjectGroupsDropdownMenu),
          matching: find.byType(SvgImage),
        );

        final actualImage = tester.widget<SvgImage>(imageFinder);

        expect(actualImage.src, equals(expectedAsset));
      },
    );

    testWidgets(
      "updates a project group items if they were updated in notifier",
      (tester) async {
        when(metricsNotifier.projectGroupDropdownItems)
            .thenReturn(dropdownItems);

        await mockNetworkImagesFor(
          () => tester.pumpWidget(_ProjectGroupsDropdownMenuTestbed(
            metricsNotifier: metricsNotifier,
          )),
        );

        metricsNotifier.notifyListeners();

        const expectedViewModels = [
          ProjectGroupDropdownItemViewModel(
            id: 'id',
            name: 'name',
          ),
          ProjectGroupDropdownItemViewModel(
            id: 'id1',
            name: 'name1',
          )
        ];

        when(metricsNotifier.projectGroupDropdownItems)
            .thenReturn(expectedViewModels);

        metricsNotifier.notifyListeners();

        await openDropdownMenu(tester);

        final dropdownItemWidgets =
            tester.widgetList<ProjectGroupsDropdownItem>(
          find.byType(ProjectGroupsDropdownItem),
        );

        final actualInitialViewModels = dropdownItemWidgets
            .map((widget) => widget.projectGroupDropdownItemViewModel)
            .where((viewModel) => viewModel.id != null)
            .toList();

        expect(
          listEquals(actualInitialViewModels, expectedViewModels),
          isTrue,
        );
      },
    );

    testWidgets(
      "sets the project group filter on tap on a project group item",
      (tester) async {
        when(metricsNotifier.projectGroupDropdownItems)
            .thenReturn(dropdownItems);

        await mockNetworkImagesFor(
          () => tester.pumpWidget(_ProjectGroupsDropdownMenuTestbed(
            metricsNotifier: metricsNotifier,
          )),
        );

        await openDropdownMenu(tester);

        final itemViewModel = metricsNotifier.projectGroupDropdownItems.first;

        await tester.tap(find.text(itemViewModel.name));
        await tester.pumpAndSettle();

        verify(metricsNotifier.selectProjectGroup(itemViewModel.id))
            .called(once);
      },
    );

    testWidgets(
      "displays the name of the selected project group",
      (tester) async {
        when(metricsNotifier.selectedProjectGroup)
            .thenReturn(firstDropdownItem);

        await mockNetworkImagesFor(
          () => tester.pumpWidget(_ProjectGroupsDropdownMenuTestbed(
            metricsNotifier: metricsNotifier,
          )),
        );

        expect(find.text(firstDropdownItem.name), findsOneWidget);
      },
    );

    testWidgets(
      "displays the name of the project group in one line",
      (tester) async {
        when(metricsNotifier.selectedProjectGroup)
            .thenReturn(firstDropdownItem);

        await mockNetworkImagesFor(
          () => tester.pumpWidget(_ProjectGroupsDropdownMenuTestbed(
            metricsNotifier: metricsNotifier,
          )),
        );

        final groupNameText = tester.widget<Text>(
          find.text(firstDropdownItem.name),
        );

        expect(groupNameText.maxLines, equals(1));
      },
    );
  });
}

/// A testbed class used to test the [ProjectGroupsDropdownMenu] widget.
class _ProjectGroupsDropdownMenuTestbed extends StatelessWidget {
  /// A [ProjectMetricsNotifier] used in tests.
  final ProjectMetricsNotifier metricsNotifier;

  /// A [MetricsThemeData] used in tests.
  final MetricsThemeData theme;

  /// Creates the testbed with the given [metricsNotifier].
  const _ProjectGroupsDropdownMenuTestbed({
    Key key,
    this.metricsNotifier,
    this.theme = const MetricsThemeData(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      metricsNotifier: metricsNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: theme,
        body: ProjectGroupsDropdownMenu(),
      ),
    );
  }
}
