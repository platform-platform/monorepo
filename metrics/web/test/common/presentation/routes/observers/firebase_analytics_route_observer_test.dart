// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/routes/observers/firebase_analytics_route_observer.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../../test_utils/analytics_notifier_mock.dart';
import '../../../../test_utils/matchers.dart';

void main() {
  group("FirebaseAnalyticsObserver", () {
    const routeSettings = RouteSettings(name: '/test');
    const testWidget = Text('test');

    final analyticsNotifier = AnalyticsNotifierMock();

    final observer = FirebaseAnalyticsRouteObserver(
      analyticsNotifier: analyticsNotifier,
    );

    setUp(() {
      reset(analyticsNotifier);
    });

    test("throws an AssertionError if the given notifier is null", () {
      expect(
        () => FirebaseAnalyticsRouteObserver(analyticsNotifier: null),
        throwsAssertionError,
      );
    });

    test(
      ".didPush() does not log the page change if the route is not a PageRoute",
      () {
        final route = StubPopupRoute();

        observer.didPush(route, null);

        verifyNever(analyticsNotifier.logPageView(any));
      },
    );

    test(
      ".didPop() does not log the page change if the route is not a PageRoute",
      () {
        final route = StubPopupRoute();

        observer.didPop(null, route);

        verifyNever(analyticsNotifier.logPageView(any));
      },
    );

    test(
      ".didReplace() does not log the page change if the route is not a PageRoute",
      () {
        final route = StubPopupRoute();

        observer.didReplace(newRoute: route);

        verifyNever(analyticsNotifier.logPageView(any));
      },
    );

    test(".didPush() logs a new route name", () {
      final route = MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => testWidget,
      );

      observer.didPush(route, null);

      verify(analyticsNotifier.logPageView(routeSettings.name)).called(once);
    });

    test(".didReplace() logs a new route name", () {
      final route = MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => testWidget,
      );

      observer.didReplace(newRoute: route);

      verify(analyticsNotifier.logPageView(routeSettings.name)).called(once);
    });

    test(".didPop() logs the previous route name as a new one", () {
      final route = MaterialPageRoute(
        settings: routeSettings,
        builder: (_) => testWidget,
      );

      observer.didPop(null, route);

      verify(analyticsNotifier.logPageView(routeSettings.name)).called(once);
    });
  });
}

/// A stub implementation of the [PopupRoute] used for testing.
class StubPopupRoute extends PopupRoute {
  @override
  Color get barrierColor => Colors.white;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'test';

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return const Text('test');
  }

  @override
  Duration get transitionDuration => Duration.zero;
}
