// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/debug_menu/domain/usecases/close_local_config_storage_usecase.dart';
import 'package:mockito/mockito.dart';

import '../../../test_utils/local_config_repository_mock.dart';
import '../../../test_utils/matchers.dart';

void main() {
  group("CloseLocalConfigStorageUseCase", () {
    final repository = LocalConfigRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    test(
      "throws an ArgumentError if the given repository is null",
      () {
        expect(
          () => CloseLocalConfigStorageUseCase(null),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given repository",
      () {
        expect(
          () => CloseLocalConfigStorageUseCase(repository),
          returnsNormally,
        );
      },
    );

    test(
      ".call() uses the .close() method of the local config repository",
      () {
        final useCase = CloseLocalConfigStorageUseCase(repository);

        useCase();

        verify(repository.close()).called(once);
      },
    );
  });
}
