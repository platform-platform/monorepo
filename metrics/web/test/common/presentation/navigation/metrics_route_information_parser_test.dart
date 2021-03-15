// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:metrics/common/presentation/navigation/constants/metrics_routes.dart';
import 'package:metrics/common/presentation/navigation/metrics_route_information_parser.dart';
import 'package:metrics/common/presentation/navigation/route_configuration/route_configuration_factory.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("MetricsRouteInformationParser", () {
    final routeConfigurationFactory = _RouteConfigurationFactoryMock();
    final routeInformationParser = MetricsRouteInformationParser(
      RouteConfigurationFactory(),
    );

    tearDown(() {
      reset(routeConfigurationFactory);
    });

    test(
      "throws an AssertionError if the given route configuration factory is null",
      () {
        expect(
          () => MetricsRouteInformationParser(null),
          throwsAssertionError,
        );
      },
    );

    test(
      ".parseRouteInformation() delegates to the route configuration factory if the given route information is null",
      () async {
        final routeInformationParser = MetricsRouteInformationParser(
          routeConfigurationFactory,
        );

        await routeInformationParser.parseRouteInformation(null);

        verify(routeConfigurationFactory.create(null)).called(once);
      },
    );

    test(
      ".parseRouteInformation() delegates to the route configuration factory if the location of the given route information is null",
      () async {
        final routeInformationParser = MetricsRouteInformationParser(
          routeConfigurationFactory,
        );

        await routeInformationParser.parseRouteInformation(
          const RouteInformation(location: null),
        );

        verify(routeConfigurationFactory.create(null)).called(once);
      },
    );

    test(
      ".parseRouteInformation() returns the route configuration created by the given route configuration factory",
      () async {
        final expectedConfiguration = MetricsRoutes.dashboard;

        when(routeConfigurationFactory.create(any))
            .thenReturn(expectedConfiguration);

        final actualConfiguration = await routeInformationParser
            .parseRouteInformation(const RouteInformation(location: 'test'));

        expect(actualConfiguration, equals(expectedConfiguration));
      },
    );

    test(
      ".restoreRouteInformation() returns null if the the given route configuration is null",
      () {
        expect(
          routeInformationParser.restoreRouteInformation(null),
          isNull,
        );
      },
    );

    test(
      ".restoreRouteInformation() returns the route information with the location equals to the given route configuration path",
      () {
        final routeConfiguration = MetricsRoutes.login;
        final expectedLocation = routeConfiguration.path;

        final actualLocation = routeInformationParser
            .restoreRouteInformation(routeConfiguration)
            .location;

        expect(actualLocation, equals(expectedLocation));
      },
    );
  });
}

class _RouteConfigurationFactoryMock extends Mock
    implements RouteConfigurationFactory {}
