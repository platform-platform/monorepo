// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/metrics_logger/sentry/event_processors/sentry_event_processor.dart';
import 'package:metrics/metrics_logger/sentry/writers/sentry_writer.dart';
import 'package:mockito/mockito.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("SentryWriter", () {
    const testDsn = "testDsn";
    const testRelease = "testRelease";
    const testEnvironment = "testEnvironment";

    final sentryClientMock = _SentryClientMock();

    SentryWriter writer;

    setUp(() async {
      writer = await SentryWriter.init(testDsn, testRelease, testEnvironment);
      Sentry.bindClient(sentryClientMock);
    });

    tearDown(() {
      reset(sentryClientMock);
      Sentry.close();
    });

    test(
      ".init() initializes Sentry with the given DSN, release and environment values",
      () async {
        final writer = await SentryWriter.init(
          testDsn,
          testRelease,
          testEnvironment,
        );

        expect(writer, isNotNull);
        expect(Sentry.isEnabled, isTrue);
      },
    );

    test(
      ".init() initializes Sentry if the given event processor is null",
      () async {
        final future = SentryWriter.init(
          testDsn,
          testRelease,
          testEnvironment,
          eventProcessor: null,
        );

        expect(future, completes);
      },
    );

    test(
      ".setContext() sets the context by the given key to the given value",
      () async {
        const key = 'contextKey';
        const value = {'testContext': 'value'};

        writer.setContext(key, value);

        Map<String, dynamic> context;
        Sentry.configureScope((scope) => context = scope.contexts);

        expect(context, containsPair(key, value));
      },
    );

    test(
      ".setContext() sets the context by the given key to the given value in a map if the given value is not a map",
      () async {
        const key = 'contextKey';
        const value = 'contextValue';
        const expectedValue = {'value': value};

        writer.setContext(key, value);

        Map<String, dynamic> context;
        Sentry.configureScope((scope) => context = scope.contexts);

        expect(context, containsPair(key, expectedValue));
      },
    );

    test(
      ".writeError() writes the given error if the given stack trace is not passed",
      () async {
        final error = Error();

        await writer.writeError(error);

        verify(sentryClientMock.captureException(
          error,
          stackTrace: argThat(isNull, named: 'stackTrace'),
          hint: argThat(isNull, named: 'hint'),
          scope: anyNamed('scope'),
        )).called(once);
      },
    );

    test(
      ".writeError() writes the given error if the given stack trace is null",
      () async {
        final error = Error();

        await writer.writeError(error, null);

        verify(sentryClientMock.captureException(
          error,
          stackTrace: argThat(isNull, named: 'stackTrace'),
          hint: argThat(isNull, named: 'hint'),
          scope: anyNamed('scope'),
        )).called(once);
      },
    );

    test(
      ".writeError() writes the given error and its stack trace",
      () async {
        final error = Error();
        final stackTrace = StackTrace.fromString('test stack trace');

        await writer.writeError(error, stackTrace);

        verify(sentryClientMock.captureException(
          error,
          stackTrace: stackTrace,
          hint: argThat(isNull, named: 'hint'),
          scope: anyNamed('scope'),
        )).called(once);
      },
    );

    test(
      ".writeError() applies the contexts set to the error",
      () async {
        const key = 'contextKey';
        const value = {'testContext': 'value'};
        final error = Error();
        final stackTrace = StackTrace.fromString('test stack trace');

        writer.setContext(key, value);
        await writer.writeError(error, stackTrace);

        verify(sentryClientMock.captureException(
          error,
          stackTrace: stackTrace,
          hint: argThat(isNull, named: 'hint'),
          scope: argThat(
            predicate<Scope>((scope) => scope.contexts[key] == value),
            named: 'scope',
          ),
        )).called(once);
      },
    );

    test(
      ".writeError() calls the given event processor if it is not null",
      () async {
        final eventProcessor = _SentryEventProcessorMock();
        final error = Error();

        final writer = await SentryWriter.init(
          testDsn,
          testRelease,
          testEnvironment,
          eventProcessor: eventProcessor,
        );
        await writer.writeError(error);

        final sentryEventMatcher =
            predicate<SentryEvent>((event) => event.throwable == error);

        verify(
          eventProcessor.call(
            argThat(sentryEventMatcher),
            hint: anyNamed('hint'),
          ),
        ).called(once);
      },
    );
  });
}

class _SentryClientMock extends Mock implements SentryClient {}

class _SentryEventProcessorMock extends Mock implements SentryEventProcessor {}
