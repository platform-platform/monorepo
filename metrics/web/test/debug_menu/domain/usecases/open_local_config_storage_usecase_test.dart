// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/debug_menu/domain/usecases/open_local_config_storage_usecase.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils/local_config_repository_mock.dart';
import '../../../test_utils/matchers.dart';

void main() {
  group("OpenLocalConfigStorageUseCase", () {
    final repository = LocalConfigRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    test(
      "throws an ArgumentError if the given repository is null",
      () {
        expect(
          () => OpenLocalConfigStorageUseCase(null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given repository",
      () {
        expect(
          () => OpenLocalConfigStorageUseCase(repository),
          returnsNormally,
        );
      },
    );

    test(
      ".call() uses the .open() method of the local config repository",
      () {
        final useCase = OpenLocalConfigStorageUseCase(repository);

        useCase();

        verify(repository.open()).called(once);
      },
    );
  });
}
