// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/logger/logger.dart';
import 'package:ci_integration/cli/logger/manager/logger_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../test_utils/matchers.dart';
import '../test_util/mock/logger_factory_mock.dart';
import '../test_util/mock/logger_writer_mock.dart';

void main() {
  group("Logger", () {
    const testSourceClass = Object;
    const testVerbose = true;
    final writerMock = LoggerWriterMock();

    final logger = Logger(
      writer: writerMock,
      verbose: false,
      sourceClass: testSourceClass,
    );

    final verboseLogger = Logger(
      writer: writerMock,
      verbose: testVerbose,
      sourceClass: testSourceClass,
    );

    final loggerFactoryMock = LoggerFactoryMock();

    setUpAll(() {
      LoggerManager.setLoggerFactory(loggerFactoryMock);
    });

    tearDown(() {
      reset(writerMock);
      reset(loggerFactoryMock);
      LoggerManager.instance.reset();
    });

    tearDownAll(() {
      LoggerManager.setLoggerFactory(null);
    });

    bool matchesPrefixes(String log, String sourceClass, String message) {
      final regexp = RegExp(r'(\d+\/?)+\ (\d{2}:?)');
      final timestampEnd = regexp.firstMatch(log).end;
      return log.contains(sourceClass, timestampEnd) && log.endsWith(message);
    }

    test("throws an ArgumentError if the given source class is null", () {
      expect(
        () => Logger(
          sourceClass: null,
          writer: writerMock,
          verbose: testVerbose,
        ),
        throwsArgumentError,
      );
    });

    test("throws an ArgumentError if the given writer is null", () {
      expect(
        () => Logger(
          sourceClass: testSourceClass,
          writer: null,
          verbose: testVerbose,
        ),
        throwsArgumentError,
      );
    });

    test("throws an ArgumentError if the given source class is null", () {
      expect(
        () => Logger(
          sourceClass: testSourceClass,
          writer: writerMock,
          verbose: null,
        ),
        throwsArgumentError,
      );
    });

    test("creates a new instance with the given parameters", () {
      expect(
        () => Logger(
          sourceClass: testSourceClass,
          writer: writerMock,
          verbose: testVerbose,
        ),
        returnsNormally,
      );
    });

    test(
      ".forClass() returns a new logger if LoggerManager does not contain any for the given class type",
      () {
        const sourceClass = _ClassStub;
        final expectedLogger = Logger(
          sourceClass: sourceClass,
          writer: writerMock,
          verbose: testVerbose,
        );
        when(loggerFactoryMock.create(sourceClass)).thenReturn(expectedLogger);

        final actualLogger = Logger.forClass(sourceClass);

        expect(actualLogger, equals(expectedLogger));
        verify(loggerFactoryMock.create(sourceClass)).called(once);
      },
    );

    test(
      ".forClass() returns an existing logger from the LoggerManager the given class type",
      () {
        const sourceClass = _ClassStub;
        final expectedLogger = Logger(
          sourceClass: sourceClass,
          writer: writerMock,
          verbose: testVerbose,
        );

        when(loggerFactoryMock.create(sourceClass)).thenReturn(expectedLogger);
        final logger = Logger.forClass(sourceClass);
        final secondLogger = Logger.forClass(sourceClass);

        expect(logger, isNotNull);
        expect(logger.sourceClass, equals(sourceClass));
        expect(secondLogger, same(logger));
        verify(loggerFactoryMock.create(sourceClass)).called(once);
      },
    );

    test(
      ".message() logs the given message using the specified logger writer",
      () {
        const message = 'test';

        logger.message(message);

        verify(writerMock.write(message)).called(once);
      },
    );

    test(
      ".message() logs the given message with timestamp and source class prefixes if in the verbose mode",
      () {
        const message = 'test';

        verboseLogger.message(message);
        final logMatcher = predicate<String>(
          (log) => matchesPrefixes(log, '$testSourceClass', message),
        );

        verify(writerMock.write(argThat(logMatcher))).called(once);
      },
    );

    test(
      ".info() does not write log if logger is not in the verbose mode",
      () {
        const message = 'test';

        logger.info(message);

        verifyNever(writerMock.write(any));
      },
    );

    test(
      ".info() logs the given message using the specified logger writer",
      () {
        const message = 'test';

        verboseLogger.info(message);

        verify(writerMock.write(
          argThat(contains(message)),
        )).called(once);
      },
    );

    test(
      ".info() logs the given message with timestamp and source class prefixes",
      () {
        const message = 'test';

        verboseLogger.info(message);
        final logMatcher = predicate<String>(
          (log) => matchesPrefixes(log, '$testSourceClass', message),
        );

        verify(writerMock.write(argThat(logMatcher))).called(once);
      },
    );
  });
}

/// A class stub to use in tests as [Logger.sourceClass] and ensure
/// this source is unique within tests.
class _ClassStub {}
