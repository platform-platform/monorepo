// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/logger/factory/logger_factory.dart';
import 'package:ci_integration/cli/logger/writer/io_logger_writer.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../test_util/mock/logger_writer_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("LoggerFactory", () {
    final writerMock = LoggerWriterMock();
    final loggerFactory = LoggerFactory(
      writer: writerMock,
      verbose: true,
    );

    tearDown(() {
      reset(writerMock);
    });

    test(
      "creates a new instance with verbose equal to false if the given one is null",
      () {
        final loggerFactory = LoggerFactory(
          writer: writerMock,
          verbose: null,
        );

        expect(loggerFactory.verbose, isFalse);
      },
    );

    test(
      "creates a new instance with io writer if the given one is null",
      () {
        final loggerFactory = LoggerFactory(
          writer: null,
          verbose: false,
        );

        expect(loggerFactory.writer, isNotNull);
        expect(loggerFactory.writer, isA<IOLoggerWriter>());
      },
    );

    test(
      "creates a new instance with the given parameters",
      () {
        const expectedVerbose = true;

        final loggerFactory = LoggerFactory(
          writer: writerMock,
          verbose: expectedVerbose,
        );

        expect(loggerFactory.writer, writerMock);
        expect(loggerFactory.verbose, expectedVerbose);
      },
    );

    test(".create() creates a new logger with the given source class", () {
      final logger = loggerFactory.create(LoggerFactory);

      expect(logger.sourceClass, equals(LoggerFactory));
    });

    test(".create() creates a new logger with the specified writer", () {
      const testMessage = 'test';

      final logger = loggerFactory.create(LoggerFactory);
      logger.message(testMessage);

      verify(
        writerMock.write(
          argThat(contains(testMessage)),
        ),
      ).called(once);
    });

    test(".create() creates a new logger with the specified verbose value", () {
      const testMessage = 'test';

      final logger = loggerFactory.create(LoggerFactory);
      logger.info(testMessage);

      verify(
        writerMock.write(
          argThat(contains(testMessage)),
        ),
      ).called(once);
    });
  });
}
