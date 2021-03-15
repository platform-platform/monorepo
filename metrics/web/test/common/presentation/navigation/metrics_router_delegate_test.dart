// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/navigation/metrics_page/metrics_page.dart';
import 'package:metrics/common/presentation/navigation/metrics_page/metrics_page_factory.dart';
import 'package:metrics/common/presentation/navigation/metrics_router_delegate.dart';
import 'package:metrics/common/presentation/navigation/route_configuration/route_name.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/navigation_state_mock.dart';
import '../../../test_utils/route_configuration_stub.dart';

void main() {
  group("MetricsRouterDelegate", () {
    const configuration = RouteConfigurationStub(name: RouteName.dashboard);

    final navigationNotifierMock = _NavigationNotifierMock();
    final navigationState = NavigationStateMock();
    final metricsRouterDelegate = MetricsRouterDelegate(navigationNotifierMock);
    final pages = UnmodifiableListView<MetricsPage>([]);

    tearDown(() {
      reset(navigationNotifierMock);
    });

    test(
      "throws an AssertionError if the given navigation notifier is null",
      () {
        expect(
          () => MetricsRouterDelegate(null),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given navigation observers are null",
      () {
        expect(
          () => MetricsRouterDelegate(
            navigationNotifierMock,
            navigatorObservers: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      ".currentConfiguration provides the current route configuration from the navigation notifier",
      () {
        when(navigationNotifierMock.currentConfiguration).thenReturn(
          configuration,
        );

        expect(
          metricsRouterDelegate.currentConfiguration,
          equals(configuration),
        );
      },
    );

    test(
      ".navigatorKey provides the global object key with a value equals to the given navigator notifier",
      () {
        final navigationNotifier = NavigationNotifier(
          MetricsPageFactory(),
          navigationState,
        );
        final routerDelegate = MetricsRouterDelegate(navigationNotifier);

        final expectedKey = GlobalObjectKey<NavigatorState>(navigationNotifier);
        final actualKey = routerDelegate.navigatorKey;

        expect(actualKey, equals(expectedKey));
      },
    );

    test(
      "notifies listeners once the given navigation notifier notifies listeners",
      () {
        final metricsPageFactory = MetricsPageFactory();
        final navigationNotifier = NavigationNotifier(
          metricsPageFactory,
          navigationState,
        );
        final metricsRouterDelegate = MetricsRouterDelegate(navigationNotifier);

        bool isCalled = false;
        metricsRouterDelegate.addListener(() => isCalled = true);

        navigationNotifier.notifyListeners();

        expect(isCalled, isTrue);
      },
    );

    test(
      ".setInitialRoutePath() delegates call to the navigation notifier",
      () async {
        await metricsRouterDelegate.setInitialRoutePath(configuration);

        verify(navigationNotifierMock.handleInitialRoutePath(configuration))
            .called(equals(1));
      },
    );

    test(
      ".setNewRoutePath() delegates call to the navigation notifier",
      () async {
        await metricsRouterDelegate.setNewRoutePath(configuration);

        verify(navigationNotifierMock.handleNewRoutePath(configuration))
            .called(equals(1));
      },
    );

    test(
      ".build() returns the navigator widget",
      () {
        when(navigationNotifierMock.pages).thenReturn(pages);

        final actualWidget = metricsRouterDelegate.build(null);

        expect(actualWidget, isA<Navigator>());
      },
    );

    test(
      "applies the navigator key to the navigator widget",
      () {
        when(navigationNotifierMock.pages).thenReturn(pages);

        final expectedKey = metricsRouterDelegate.navigatorKey;

        final navigatorWidget = metricsRouterDelegate.build(null) as Navigator;

        final actualKey = navigatorWidget.key;

        expect(actualKey, equals(expectedKey));
      },
    );

    test(
      "applies a list of pages from the given navigation notifier to the navigator widget",
      () {
        final expectedPages = UnmodifiableListView(
          const [MetricsPage(child: Text('test'))],
        );
        when(navigationNotifierMock.pages).thenReturn(expectedPages);

        final metricsRouterDelegate = MetricsRouterDelegate(
          navigationNotifierMock,
        );

        final navigatorWidget = metricsRouterDelegate.build(null) as Navigator;

        final actualPages = navigatorWidget.pages;

        expect(actualPages, equals(expectedPages));
      },
    );

    test(
      "applies an empty list to the navigator observers if the given parameter is not specified",
      () {
        when(navigationNotifierMock.pages).thenReturn(pages);

        final metricsRouterDelegate = MetricsRouterDelegate(
          navigationNotifierMock,
        );

        final navigator = metricsRouterDelegate.build(null) as Navigator;

        expect(navigator.observers, equals([]));
      },
    );

    test(
      "applies the given navigator observers to the navigator widget",
      () {
        when(navigationNotifierMock.pages).thenReturn(pages);

        final expectedNavigatorObservers = [NavigatorObserver()];

        final metricsRouterDelegate = MetricsRouterDelegate(
          navigationNotifierMock,
          navigatorObservers: expectedNavigatorObservers,
        );

        final navigator = metricsRouterDelegate.build(null) as Navigator;

        expect(navigator.observers, equals(expectedNavigatorObservers));
      },
    );

    test(
      "on pop page callback returns the route pop result",
      () {
        const expectedResult = true;
        final routeMock = _MaterialPageRouteMock();

        when(navigationNotifierMock.pages).thenReturn(pages);
        when(routeMock.didPop(any)).thenReturn(expectedResult);

        final metricsRouterDelegate = MetricsRouterDelegate(
          navigationNotifierMock,
        );

        final navigator = metricsRouterDelegate.build(null) as Navigator;
        final actualResult = navigator.onPopPage(routeMock, () => {});

        expect(actualResult, equals(expectedResult));
      },
    );

    test(
      "on pop page callback delegates to the navigation notifier if the route successfully pops",
      () {
        when(navigationNotifierMock.pages).thenReturn(pages);

        final metricsRouterDelegate = MetricsRouterDelegate(
          navigationNotifierMock,
        );

        final navigator = metricsRouterDelegate.build(null) as Navigator;

        final routeMock = _MaterialPageRouteMock();
        when(routeMock.didPop(any)).thenReturn(true);

        navigator.onPopPage(routeMock, () => {});

        verify(navigationNotifierMock.pop()).called(equals(1));
      },
    );

    test(
      "on pop page callback does not delegate to the navigation notifier if the route pop fails",
      () {
        when(navigationNotifierMock.pages).thenReturn(pages);

        final metricsRouterDelegate = MetricsRouterDelegate(
          navigationNotifierMock,
        );

        final navigator = metricsRouterDelegate.build(null) as Navigator;

        final routeMock = _MaterialPageRouteMock();
        when(routeMock.didPop(any)).thenReturn(false);

        navigator.onPopPage(routeMock, () => {});

        verifyNever(navigationNotifierMock.pop());
      },
    );
  });
}

class _NavigationNotifierMock extends Mock implements NavigationNotifier {}

class _MaterialPageRouteMock extends Mock implements MaterialPageRoute {}
