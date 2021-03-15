// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/common/domain/entities/persistent_store_exception.dart';
import 'package:metrics/debug_menu/domain/entities/local_config.dart';
import 'package:metrics/debug_menu/domain/usecases/read_local_config_usecase.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils/local_config_repository_mock.dart';
import '../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ReadLocalConfigUseCase", () {
    final repository = LocalConfigRepositoryMock();
    final useCase = ReadLocalConfigUseCase(repository);

    const config = LocalConfig(isFpsMonitorEnabled: false);

    tearDown(() {
      reset(repository);
    });

    test(
      "throws an ArgumentError if the given repository is null",
      () {
        expect(
          () => ReadLocalConfigUseCase(null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given repository",
      () {
        expect(
          () => ReadLocalConfigUseCase(repository),
          returnsNormally,
        );
      },
    );

    test(
      ".call() uses the .readConfig() method of the local config repository",
      () {
        useCase();

        verify(repository.readConfig()).called(once);
      },
    );

    test(
      ".call() returns a local config with the default values if the read local config contains null values",
      () {
        when(repository.readConfig()).thenReturn(
          const LocalConfig(isFpsMonitorEnabled: null),
        );

        final actualConfig = useCase();

        expect(actualConfig, equals(config));
      },
    );

    test(
      ".call() returns a local config with the default values if the read local config is null",
      () {
        when(repository.readConfig()).thenReturn(null);

        final actualConfig = useCase();

        expect(actualConfig, equals(config));
      },
    );

    test(
      ".call() returns a local config with the default values if reading the local config fails",
      () {
        when(
          repository.readConfig(),
        ).thenThrow(const PersistentStoreException());

        final actualConfig = useCase();

        expect(actualConfig, equals(config));
      },
    );
  });
}
