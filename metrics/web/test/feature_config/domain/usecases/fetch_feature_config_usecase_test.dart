// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/feature_config/domain/entities/feature_config.dart';
import 'package:metrics/feature_config/domain/repositories/feature_config_repository.dart';
import 'package:metrics/feature_config/domain/usecases/fetch_feature_config_usecase.dart';
import 'package:metrics/feature_config/domain/usecases/parameters/feature_config_param.dart';

import 'package:mockito/mockito.dart';

import '../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("FetchFeatureConfigUseCase", () {
    const isPasswordSignInOptionEnabled = true;
    const isDebugMenuEnabled = true;

    const featureConfig = FeatureConfig(
      isPasswordSignInOptionEnabled: isPasswordSignInOptionEnabled,
      isDebugMenuEnabled: isDebugMenuEnabled,
    );
    final param = FeatureConfigParam(
      isPasswordSignInOptionEnabled: isPasswordSignInOptionEnabled,
      isDebugMenuEnabled: isDebugMenuEnabled,
    );

    final repository = _FeatureConfigRepositoryMock();
    final useCase = FetchFeatureConfigUseCase(repository);

    tearDown(() {
      reset(repository);
    });

    test(
      "throws an ArgumentError if the given repository is null",
      () {
        expect(
          () => FetchFeatureConfigUseCase(null),
          throwsArgumentError,
        );
      },
    );

    test("creates an instance with the given repository", () {
      expect(
        () => FetchFeatureConfigUseCase(repository),
        returnsNormally,
      );
    });

    test(
      ".call() uses the .fetch() method of the feature config repository",
      () {
        useCase(param);

        verify(repository.fetch()).called(once);
      },
    );

    test(
      ".call() returns a feature config with the given param values if the fetched feature config contains null values",
      () async {
        const nullConfig = FeatureConfig(
          isPasswordSignInOptionEnabled: null,
          isDebugMenuEnabled: null,
        );

        when(repository.fetch()).thenAnswer((_) => Future.value(nullConfig));

        final config = await useCase(param);

        expect(config, equals(featureConfig));
      },
    );

    test(
      ".call() returns a feature config with the given param values if the fetched feature config is null",
      () async {
        when(repository.fetch()).thenAnswer((_) => Future.value(null));

        final config = await useCase(param);

        expect(config, equals(featureConfig));
      },
    );

    test(
      ".call() returns a feature config with the given param values if fetching feature config fails",
      () async {
        when(repository.fetch()).thenAnswer(
          (_) => Future.error(Exception()),
        );

        final config = await useCase(param);

        expect(config, equals(featureConfig));
      },
    );
  });
}

class _FeatureConfigRepositoryMock extends Mock
    implements FeatureConfigRepository {}
