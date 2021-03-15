// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/metrics_page/metrics_page_factory.dart';
import 'package:metrics/common/presentation/navigation/route_configuration/route_name.dart';
import 'package:metrics/common/presentation/navigation/state/navigation_notifier.dart';
import 'package:metrics/common/presentation/pages/loading_page.dart';
import 'package:mockito/mockito.dart';

import '../../../../test_utils/matchers.dart' as matchers;
import '../../../../test_utils/navigation_state_mock.dart';

void main() {
  group("NavigationNotifier", () {
    final pageFactory = MetricsPageFactory();
    final navigationState = NavigationStateMock();

    NavigationNotifier notifier;

    void prepareNotifier() {
      notifier.handleAppInitialized(isAppInitialized: true);

      notifier.handleAuthenticationUpdates(isLoggedIn: false);
    }

    setUp(() {
      notifier = NavigationNotifier(pageFactory, navigationState);
      prepareNotifier();
    });

    final isLoginPageName = equals(MetricsRoutes.login.path);
    final isDashboardPageName = equals(MetricsRoutes.dashboard.path);
    final isProjectGroupsPageName = equals(MetricsRoutes.projectGroups.path);
    final isLoadingPageName = equals(MetricsRoutes.loading.path);

    test(
      "throws an AssertionError if the given page factory is null",
      () {
        expect(
          () => NavigationNotifier(null, navigationState),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if the given navigation state is null",
      () {
        expect(
          () => NavigationNotifier(pageFactory, null),
          throwsAssertionError,
        );
      },
    );

    test(
      "creates an instance with the given parameters",
      () {
        expect(
          () => NavigationNotifier(pageFactory, navigationState),
          returnsNormally,
        );
      },
    );

    test(
      ".pages is an unmodifiable list view",
      () {
        expect(notifier.pages, isA<UnmodifiableListView>());
      },
    );

    test(
      ".handleAuthenticationUpdates() clears pages and pushes to the login page when the user logs out",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.dashboard);

        notifier.handleAuthenticationUpdates(isLoggedIn: false);

        final pages = notifier.pages;
        final currentPage = pages.last;

        expect(pages, hasLength(1));
        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".handleAppInitialized() throws an argument error if the given is app initialized is null",
      () {
        expect(
          () => notifier.handleAppInitialized(isAppInitialized: null),
          throwsArgumentError,
        );
      },
    );

    test(
      ".handleAppInitialized() redirects to the dashboard page when the app is initialized and the redirect route is loading page",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleInitialRoutePath(MetricsRoutes.loading);

        notifier.handleAppInitialized(isAppInitialized: true);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isDashboardPageName);
      },
    );

    test(
      ".handleAppInitialized() redirects to the dashboard page when the app is initialized and the redirect route is null",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleAppInitialized(isAppInitialized: true);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isDashboardPageName);
      },
    );

    test(
      ".handleAppInitialized() redirects to the redirect route when the app is initialized",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleInitialRoutePath(MetricsRoutes.projectGroups);

        notifier.handleAppInitialized(isAppInitialized: true);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isProjectGroupsPageName);
      },
    );

    test(
      ".handleAppInitialized() clears the redirect route after redirect",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleInitialRoutePath(MetricsRoutes.projectGroups);

        notifier.handleAppInitialized(isAppInitialized: true);
        notifier.handleAppInitialized(isAppInitialized: true);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isDashboardPageName);
      },
    );

    test(
      ".handleAppInitialized() clears pages before redirect",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleInitialRoutePath(MetricsRoutes.loading);
        notifier.push(MetricsRoutes.dashboard);

        notifier.handleAppInitialized(isAppInitialized: true);

        final pages = notifier.pages;

        expect(pages, hasLength(equals(1)));
      },
    );

    test(
      ".pop() does nothing if pages are empty",
      () {
        final expectedPages = notifier.pages;

        notifier.pop();

        final actualPages = notifier.pages;

        expect(actualPages, equals(expectedPages));
      },
    );

    test(
      ".pop() does nothing if pages contain one page",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.dashboard);

        final expectedPages = notifier.pages;

        notifier.pop();

        final actualPages = notifier.pages;

        expect(actualPages, equals(expectedPages));
      },
    );

    test(
      ".pop() removes the current page",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.push(MetricsRoutes.dashboard);
        notifier.push(MetricsRoutes.projectGroups);

        notifier.pop();

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isDashboardPageName);
      },
    );

    test(
      ".pop() sets the previous rote configuration to current configuration",
      () {
        final expectedConfiguration = MetricsRoutes.dashboard;
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.push(expectedConfiguration);
        notifier.push(MetricsRoutes.projectGroups);

        notifier.pop();

        expect(notifier.currentConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".push() pushes the loading page if the app is not initialized",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.push(MetricsRoutes.dashboard);

        final currentPage = notifier.pages.last;

        expect(currentPage.child, isA<LoadingPage>());
      },
    );

    test(
      ".push() pushes the loading page with the given route path as a name if the app is not initialized",
      () {
        final configuration = MetricsRoutes.dashboard;

        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.push(configuration);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, equals(configuration.path));
      },
    );

    test(
      ".push() pushes the given page if the user is logged in and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.dashboard);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isDashboardPageName);
      },
    );

    test(
      ".push() pushes the login page if the user is not logged in, the given page requires authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.dashboard);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".push() pushes the given page if the user is not logged in, the given page does not require authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.loading);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoadingPageName);
      },
    );

    test(
      ".push() updates the current configuration",
      () {
        final expectedConfiguration = MetricsRoutes.dashboard;
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.push(expectedConfiguration);

        expect(notifier.currentConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".pushReplacement() pushes the loading page if the app is not initialized",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.pushReplacement(MetricsRoutes.dashboard);

        final currentPage = notifier.pages.last;

        expect(currentPage.child, isA<LoadingPage>());
      },
    );

    test(
      ".pushReplacement() pushes the loading page with the given route path as a name if the app is not initialized",
      () {
        final configuration = MetricsRoutes.dashboard;
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.pushReplacement(configuration);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, equals(configuration.path));
      },
    );

    test(
      ".pushReplacement() replaces the current page if pages are not empty",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.dashboard);

        final expectedLength = notifier.pages.length;

        notifier.pushReplacement(MetricsRoutes.projectGroups);

        final actualLength = notifier.pages.length;

        expect(actualLength, equals(expectedLength));
      },
    );

    test(
      ".pushReplacement() adds the new page if pages are empty",
      () {
        final notifier = NavigationNotifier(pageFactory, navigationState);
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        final expectedLength = notifier.pages.length + 1;

        notifier.pushReplacement(MetricsRoutes.projectGroups);

        final actualLength = notifier.pages.length;

        expect(actualLength, equals(expectedLength));
      },
    );

    test(
      ".pushReplacement() replaces the current page with the given one if the user is logged in and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.dashboard);

        notifier.pushReplacement(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isProjectGroupsPageName);
      },
    );

    test(
      ".pushReplacement() replaces the current page with the login page if the user is not logged in, the given page requires authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.loading);

        notifier.pushReplacement(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".pushReplacement() replaces the current page with the given page if the user is not logged in, the given page does not require authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.loading);

        notifier.pushReplacement(MetricsRoutes.login);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".pushReplacement() updates the current configuration",
      () {
        const expectedConfiguration = MetricsRoutes.loading;
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.login);

        notifier.pushReplacement(expectedConfiguration);

        expect(notifier.currentConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".pushStateReplacement() pushes the loading page if the app is not initialized",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.pushStateReplacement(MetricsRoutes.dashboard);

        final currentPage = notifier.pages.last;

        expect(currentPage.child, isA<LoadingPage>());
      },
    );

    test(
      ".pushStateReplacement() pushes the loading page with the given route path as a name if the app is not initialized",
      () {
        final configuration = MetricsRoutes.dashboard;
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.pushStateReplacement(configuration);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, equals(configuration.path));
      },
    );

    test(
      ".pushStateReplacement() replaces the current page if pages are not empty",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.dashboard);

        final expectedLength = notifier.pages.length;

        notifier.pushStateReplacement(MetricsRoutes.projectGroups);

        final actualLength = notifier.pages.length;

        expect(actualLength, equals(expectedLength));
      },
    );

    test(
      ".pushStateReplacement() adds the new page if pages are empty",
      () {
        final notifier = NavigationNotifier(pageFactory, navigationState);
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        final expectedLength = notifier.pages.length + 1;

        notifier.pushStateReplacement(MetricsRoutes.projectGroups);

        final actualLength = notifier.pages.length;

        expect(actualLength, equals(expectedLength));
      },
    );

    test(
      ".pushStateReplacement() replaces the current page with the given one if the user is logged in and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.dashboard);

        notifier.pushStateReplacement(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isProjectGroupsPageName);
      },
    );

    test(
      ".pushStateReplacement() replaces the current page with the login page if the user is not logged in, the given page requires authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.loading);

        notifier.pushStateReplacement(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".pushStateReplacement() replaces the current page with the given page if the user is not logged in, the given page does not require authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.loading);

        notifier.pushStateReplacement(MetricsRoutes.login);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".pushStateReplacement() updates the current configuration",
      () {
        const expectedConfiguration = MetricsRoutes.loading;
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.login);

        notifier.pushStateReplacement(expectedConfiguration);

        expect(notifier.currentConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".pushStateReplacement() replaces the navigation state path with the pushed route configuration path",
      () {
        const expectedConfiguration = MetricsRoutes.loading;
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.login);

        notifier.pushStateReplacement(expectedConfiguration);

        verify(navigationState.replaceState(
          any,
          any,
          notifier.currentConfiguration.path,
        ));
      },
    );

    test(
      ".pushAndRemoveUntil() pushes the loading page if the app is not initialized",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.pushAndRemoveUntil(
          MetricsRoutes.dashboard,
          (page) => true,
        );

        final currentPage = notifier.pages.last;

        expect(currentPage.child, isA<LoadingPage>());
      },
    );

    test(
      ".pushAndRemoveUntil() pushes the loading page with the given route path as a name if the app is not initialized",
      () {
        final configuration = MetricsRoutes.dashboard;
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.pushAndRemoveUntil(
          configuration,
          (page) => true,
        );

        final currentPage = notifier.pages.last;

        expect(currentPage.name, equals(configuration.path));
      },
    );

    test(
      ".pushAndRemoveUntil() removes all underlying routes that don't satisfy the given predicate",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.push(MetricsRoutes.projectGroups);
        notifier.push(MetricsRoutes.login);
        notifier.push(MetricsRoutes.debugMenu);

        notifier.pushAndRemoveUntil(
          MetricsRoutes.dashboard,
          (page) => page.name == MetricsRoutes.dashboard.path,
        );

        final pages = notifier.pages;

        final containsNotDashboard = pages.any(
          (page) => page.name != MetricsRoutes.dashboard.path,
        );

        expect(containsNotDashboard, isFalse);
      },
    );

    test(
      ".pushAndRemoveUntil() does not remove the underlying routes after the predicate meets satisfying route",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.push(MetricsRoutes.projectGroups);
        notifier.push(MetricsRoutes.dashboard);
        notifier.push(MetricsRoutes.login);
        notifier.push(MetricsRoutes.debugMenu);

        notifier.pushAndRemoveUntil(
          MetricsRoutes.dashboard,
          (page) => page.name.contains(RouteName.dashboard.value),
        );

        final pages = notifier.pages;

        final containsProjectGroups = pages.any(
          (page) => page.name == MetricsRoutes.projectGroups.path,
        );

        expect(containsProjectGroups, isTrue);
      },
    );

    test(
      ".pushAndRemoveUntil() does not remove the route that satisfies predicate",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.push(MetricsRoutes.projectGroups);
        notifier.push(MetricsRoutes.dashboard);
        notifier.push(MetricsRoutes.login);
        notifier.push(MetricsRoutes.debugMenu);

        notifier.pushAndRemoveUntil(
          MetricsRoutes.dashboard,
          (page) => page.name.contains(RouteName.dashboard.value),
        );

        final pages = notifier.pages;

        final containsDashboardPage = pages.any(
          (page) => page.name == MetricsRoutes.dashboard.path,
        );

        expect(containsDashboardPage, isTrue);
      },
    );

    test(
      ".pushAndRemoveUntil() pushes the given page if the user is logged in and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.projectGroups);

        notifier.pushAndRemoveUntil(
          MetricsRoutes.dashboard,
          (page) => true,
        );

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isDashboardPageName);
      },
    );

    test(
      ".pushAndRemoveUntil() pushes the login page if the user is not logged in, the given page requires authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.loading);

        notifier.pushAndRemoveUntil(
          MetricsRoutes.dashboard,
          (page) => true,
        );

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".pushAndRemoveUntil() pushes the given page if the user is not logged in, the given page does not require authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);
        notifier.push(MetricsRoutes.loading);

        notifier.pushAndRemoveUntil(
          MetricsRoutes.login,
          (page) => true,
        );

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".pushAndRemoveUntil() updates the current configuration",
      () {
        final expectedConfiguration = MetricsRoutes.dashboard;
        notifier.handleAuthenticationUpdates(isLoggedIn: true);
        notifier.push(MetricsRoutes.projectGroups);

        notifier.pushAndRemoveUntil(
          expectedConfiguration,
          (page) => true,
        );

        expect(notifier.currentConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".handleInitialRoutePath() pushes the loading page if the app is not initialized",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.handleInitialRoutePath(MetricsRoutes.dashboard);

        final currentPage = notifier.pages.last;

        expect(currentPage.child, isA<LoadingPage>());
      },
    );

    test(
      ".handleInitialRoutePath() pushes the loading page with the given route path as a name if the app is not initialized",
      () {
        final configuration = MetricsRoutes.dashboard;
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.handleInitialRoutePath(configuration);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, equals(configuration.path));
      },
    );

    test(
      ".handleInitialRoutePath() pushes the given page if the user is logged in and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleInitialRoutePath(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isProjectGroupsPageName);
      },
    );

    test(
      ".handleInitialRoutePath() pushes the login page if the user is not logged in, the given page requires authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);

        notifier.handleInitialRoutePath(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".handleInitialRoutePath() pushes the given page if the user is not logged in, the given page does not require authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);

        notifier.handleInitialRoutePath(MetricsRoutes.login);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".handleInitialRoutePath() updates the current configuration",
      () {
        final expectedConfiguration = MetricsRoutes.projectGroups;

        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleInitialRoutePath(expectedConfiguration);

        expect(notifier.currentConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".handleNewRoutePath() pushes the loading page if the app is not initialized",
      () {
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.handleNewRoutePath(MetricsRoutes.dashboard);

        final currentPage = notifier.pages.last;

        expect(currentPage.child, isA<LoadingPage>());
      },
    );

    test(
      ".handleNewRoutePath() pushes the loading page with the given route path as a name if the app is not initialized",
      () {
        final configuration = MetricsRoutes.dashboard;
        notifier.handleAppInitialized(isAppInitialized: false);

        notifier.handleNewRoutePath(configuration);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, equals(configuration.path));
      },
    );

    test(
      ".handleNewRoutePath() pushes the given page if the user is logged in and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleNewRoutePath(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isProjectGroupsPageName);
      },
    );

    test(
      ".handleNewRoutePath() pushes the login page if the user is not logged in, the given page requires authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);

        notifier.handleNewRoutePath(MetricsRoutes.projectGroups);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".handleNewRoutePath() pushes the given page if the user is not logged in, the given page does not require authorization, and the app is initialized",
      () {
        notifier.handleAuthenticationUpdates(isLoggedIn: false);

        notifier.handleNewRoutePath(MetricsRoutes.login);

        final currentPage = notifier.pages.last;

        expect(currentPage.name, isLoginPageName);
      },
    );

    test(
      ".handleNewRoutePath() updates the current configuration",
      () {
        final expectedConfiguration = MetricsRoutes.projectGroups;

        notifier.handleAuthenticationUpdates(isLoggedIn: true);

        notifier.handleNewRoutePath(expectedConfiguration);

        expect(notifier.currentConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".replaceState() delegates to the navigation state",
      () {
        const data = 'data';
        const title = 'title';
        const path = '/test';

        notifier.replaceState(data: data, title: title, path: path);

        verify(
          navigationState.replaceState(data, title, path),
        ).called(matchers.once);
      },
    );
  });
}
