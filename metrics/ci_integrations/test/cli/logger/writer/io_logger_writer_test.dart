// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:io';

import 'package:ci_integration/cli/logger/writer/io_logger_writer.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/mock/io_sink_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("IOLoggerWriter", () {
    final messageSinkMock = IOSinkMock();
    final writer = IOLoggerWriter(
      messageSink: messageSinkMock,
    );

    tearDown(() {
      reset(messageSinkMock);
    });

    test(
      "creates an instance with stdout message sink if the given one is null",
      () {
        final writer = IOLoggerWriter(
          messageSink: null,
        );

        expect(writer.messageSink, equals(stdout));
      },
    );

    test("creates an instance with the given parameters", () {
      final writer = IOLoggerWriter(
        messageSink: messageSinkMock,
      );

      expect(writer.messageSink, equals(messageSinkMock));
    });

    test(".writeMessage() writes the given message to the message sink", () {
      const testMessage = 'test';

      writer.write(testMessage);

      verify(messageSinkMock.writeln(testMessage)).called(1);
    });
  });
}
