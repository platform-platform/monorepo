// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/util/file/file_helper.dart';
import 'package:ci_integration/util/file/file_reader.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../cli/test_util/mock/file_mock.dart';
import '../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("FileReader", () {
    const path = 'path';
    const content = 'content';

    final fileHelper = _FileHelperMock();
    final file = FileMock();

    final reader = FileReader(fileHelper: fileHelper);

    PostExpectation<bool> whenFileExists() {
      when(fileHelper.getFile(path)).thenReturn(file);
      return when(file.existsSync());
    }

    tearDown(() {
      reset(fileHelper);
      reset(file);
    });

    test(
      "creates an instance with the given file helper",
      () {
        final reader = FileReader(fileHelper: fileHelper);

        expect(reader.fileHelper, equals(fileHelper));
      },
    );

    test(
      "creates an instance with the default file helper, if the given one is null",
      () {
        const reader = FileReader(fileHelper: null);

        expect(reader.fileHelper, isNotNull);
      },
    );

    test(
      ".read() gets the file with the given path using the given file helper",
      () {
        whenFileExists().thenReturn(true);

        reader.read(path);

        verify(fileHelper.getFile(path)).called(once);
      },
    );

    test(
      ".read() throws a StateError if the file with the given path does not exist",
      () {
        whenFileExists().thenReturn(false);

        expect(() => reader.read(path), throwsStateError);
      },
    );

    test(
      ".read() returns the contents of the file",
      () {
        whenFileExists().thenReturn(true);
        when(file.readAsStringSync()).thenReturn(content);

        final fileContent = reader.read(path);

        expect(fileContent, equals(content));
      },
    );
  });
}

class _FileHelperMock extends Mock implements FileHelper {}
