// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/logger/logger.dart';
import 'package:ci_integration/cli/logger/manager/logger_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../test_util/mock/logger_factory_mock.dart';
import '../../test_util/mock/logger_writer_mock.dart';

void main() {
  group("LoggerManager", () {
    const sourceClass = Object;
    final loggerFactoryMock = LoggerFactoryMock();
    final loggerManager = LoggerManager.instance;
    final testLogger = Logger(
      sourceClass: sourceClass,
      writer: LoggerWriterMock(),
      verbose: true,
    );

    tearDown(() {
      reset(loggerFactoryMock);
      loggerManager.reset();
    });

    test(".instance returns an instance of the logger manager", () {
      final instance = LoggerManager.instance;

      expect(instance, isNotNull);
    });

    test(".setLoggerFactory() sets the given logger factory", () {
      when(loggerFactoryMock.create(sourceClass)).thenReturn(testLogger);
      LoggerManager.setLoggerFactory(loggerFactoryMock);

      final actualLogger = loggerManager.getLogger(sourceClass);

      expect(actualLogger, equals(testLogger));
      verify(loggerFactoryMock.create(sourceClass)).called(once);
    });

    test(
      ".setLoggerFactory() sets the logger factory to default if the given one is null",
      () {
        LoggerManager.setLoggerFactory(null);

        expect(() => loggerManager.getLogger(String), returnsNormally);
      },
    );

    test(
      ".getLogger() returns a new logger for the given class if the appropriate does not exist",
      () {
        when(loggerFactoryMock.create(sourceClass)).thenReturn(testLogger);
        LoggerManager.setLoggerFactory(loggerFactoryMock);

        final actualLogger = loggerManager.getLogger(sourceClass);

        expect(actualLogger, equals(testLogger));
        verify(loggerFactoryMock.create(sourceClass)).called(once);
      },
    );

    test(
      ".getLogger() returns an existing logger for the given class",
      () {
        LoggerManager.setLoggerFactory(loggerFactoryMock);
        when(loggerFactoryMock.create(sourceClass)).thenReturn(testLogger);

        final logger = loggerManager.getLogger(sourceClass);
        final secondLogger = loggerManager.getLogger(sourceClass);

        expect(logger, isNotNull);
        expect(logger.sourceClass, equals(sourceClass));
        expect(secondLogger, same(logger));
        verify(loggerFactoryMock.create(sourceClass)).called(once);
      },
    );
  });
}
