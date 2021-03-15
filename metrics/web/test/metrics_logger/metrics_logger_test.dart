// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/metrics_logger/metrics_logger.dart';
import 'package:metrics/metrics_logger/writers/logger_writer.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("MetricsLogger", () {
    const contextKey = 'context_key';
    const contextValue = 'context_value';
    final error = Error();

    final writerMock = _MockLoggerWriter();

    tearDown(() {
      reset(writerMock);
    });

    test(
      ".initialize() throws an AssertionError if the given writer is null",
      () {
        expect(
          () => MetricsLogger.initialize(null),
          throwsAssertionError,
        );
      },
    );

    test(
      ".logError() throws an AssertionError if logger is not initialized",
      () {
        expect(
          () => MetricsLogger.logError(error),
          throwsAssertionError,
        );
      },
    );

    test(
      ".setContext() throws an AssertionError if logger is not initialized",
      () {
        expect(
          () => MetricsLogger.setContext(contextKey, contextValue),
          throwsAssertionError,
        );
      },
    );

    test(
      ".initialize() initializes the logger with the given writer",
      () async {
        await MetricsLogger.initialize(writerMock);

        final future = MetricsLogger.logError(error);

        expect(future, completes);
        verify(writerMock.writeError(error)).called(1);
      },
    );

    test(
      ".initialize() sets contexts from the given map entries for the logger",
      () async {
        final contexts = {
          contextKey: contextValue,
          'testKey': 'testValue',
        };

        await MetricsLogger.initialize(writerMock, contexts: contexts);

        verifyInOrder([
          writerMock.setContext(contextKey, contextValue),
          writerMock.setContext('testKey', 'testValue'),
        ]);
      },
    );

    test(
      ".initialize() does not set contexts for the logger if the given map is null",
      () async {
        await MetricsLogger.initialize(writerMock, contexts: null);

        verifyNever(writerMock.setContext(any, any));
      },
    );

    test(
      ".logError() logs the given error",
      () async {
        await MetricsLogger.logError(error);

        verify(writerMock.writeError(error)).called(1);
      },
    );
    test(
      ".setContext() sets context to the given one for the logger",
      () async {
        await MetricsLogger.setContext(contextKey, contextValue);

        verify(writerMock.setContext(contextKey, contextValue)).called(1);
      },
    );
  });
}

class _MockLoggerWriter extends Mock implements LoggerWriter {}
