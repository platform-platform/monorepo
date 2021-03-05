// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:io';

import 'package:ci_integration/integration/interface/base/config/model/config_field.dart';
import 'package:ci_integration/integration/validation/model/field_validation_conclusion.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/mappers/field_validation_conclusion_mapper.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';
import 'package:ci_integration/integration/validation/printer/validation_result_printer.dart';
import 'package:ci_integration/source/buildkite/config/model/buildkite_source_config_field.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/mock/io_sink_mock.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ValidationResultPrinter", () {
    final ioSink = IOSinkMock();

    const additionalContext = 'context';

    final firstField = BuildkiteSourceConfigField.accessToken;
    final secondField = BuildkiteSourceConfigField.organizationSlug;
    final thirdField = BuildkiteSourceConfigField.pipelineSlug;

    const successResult = FieldValidationResult.success(additionalContext);
    const failureResult = FieldValidationResult.failure();
    const unknownResult = FieldValidationResult.unknown();

    final resultPrinter = ValidationResultPrinter(
      ioSink: ioSink,
    );

    Matcher startsWithConclusionMarker(FieldValidationConclusion conclusion) {
      String conclusionMarker;
      switch (conclusion) {
        case FieldValidationConclusion.valid:
          conclusionMarker = '+';
          break;
        case FieldValidationConclusion.invalid:
          conclusionMarker = '-';
          break;
        case FieldValidationConclusion.unknown:
          conclusionMarker = '?';
          break;
      }

      return startsWith('[$conclusionMarker]');
    }

    Matcher containsFieldName(ConfigField field) {
      return contains(field.value);
    }

    Matcher containsFieldValidationConclusion(
      FieldValidationConclusion conclusion,
    ) {
      const conclusionMapper = FieldValidationConclusionMapper();

      final expectedConclusion = conclusionMapper.unmap(conclusion);

      return contains(expectedConclusion);
    }

    Matcher endsWithAdditionalContext(String additionalContext) {
      return endsWith('Additional context: $additionalContext');
    }

    Matcher validationResultMessageMatcher(
      ConfigField field,
      FieldValidationResult result,
    ) {
      final conclusion = result.conclusion;
      final additionalContext = result.additionalContext;

      final additionalContextMatcher = additionalContext != null
          ? endsWithAdditionalContext(additionalContext)
          : isNot(endsWithAdditionalContext(additionalContext));

      return allOf(
        startsWithConclusionMarker(conclusion),
        containsFieldName(field),
        containsFieldValidationConclusion(conclusion),
        additionalContextMatcher,
      );
    }

    tearDown(() {
      reset(ioSink);
    });

    test(
      "creates an instance with the default stdout iosink, if the given one is null",
      () {
        final printer = ValidationResultPrinter(ioSink: null);

        expect(printer.ioSink, equals(stdout));
      },
    );

    test(
      "creates an instance with the given iosink",
      () {
        final printer = ValidationResultPrinter(ioSink: ioSink);

        expect(printer.ioSink, equals(ioSink));
      },
    );

    test(
      ".print() prints the validation result message to the iosink with the '+' conclusion marker for the successful field validation result",
      () {
        final validationResult = ValidationResult({
          firstField: successResult,
        });

        resultPrinter.print(validationResult);

        verify(ioSink.writeln(argThat(
          startsWithConclusionMarker(successResult.conclusion),
        ))).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink with the '-' conclusion marker for the failure field validation result",
      () {
        final validationResult = ValidationResult({
          firstField: failureResult,
        });

        resultPrinter.print(validationResult);

        verify(ioSink.writeln(argThat(
          startsWithConclusionMarker(failureResult.conclusion),
        ))).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink with the '?' conclusion marker for the unknown field validation result",
      () {
        final validationResult = ValidationResult({
          firstField: unknownResult,
        });

        resultPrinter.print(validationResult);

        verify(ioSink.writeln(argThat(
          startsWithConclusionMarker(unknownResult.conclusion),
        ))).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink containing the validated field name",
      () {
        final validationResult = ValidationResult({
          firstField: successResult,
        });

        resultPrinter.print(validationResult);

        verify(
          ioSink.writeln(argThat(containsFieldName(firstField))),
        ).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink with the string representation of the successful field validation conclusion",
      () {
        final validationResult = ValidationResult({
          firstField: successResult,
        });

        resultPrinter.print(validationResult);

        verify(ioSink.writeln(argThat(
          containsFieldValidationConclusion(successResult.conclusion),
        ))).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink with the string representation of the failure field validation conclusion",
      () {
        final validationResult = ValidationResult({
          firstField: failureResult,
        });

        resultPrinter.print(validationResult);

        verify(ioSink.writeln(argThat(
          containsFieldValidationConclusion(failureResult.conclusion),
        ))).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink with the string representation of the unknown field validation conclusion",
      () {
        final validationResult = ValidationResult({
          firstField: unknownResult,
        });

        resultPrinter.print(validationResult);

        verify(ioSink.writeln(argThat(
          containsFieldValidationConclusion(unknownResult.conclusion),
        ))).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink with the additional context if it is not null",
      () {
        final validationResult = ValidationResult({
          firstField: successResult,
        });

        resultPrinter.print(validationResult);

        verify(ioSink.writeln(argThat(
          endsWithAdditionalContext(successResult.additionalContext),
        ))).called(1);
      },
    );

    test(
      ".print() prints the validation result message to the iosink without the additional context if it is null",
      () {
        final validationResult = ValidationResult({
          firstField: successResult,
        });

        resultPrinter.print(validationResult);

        final containsAdditionalContext = contains('Additional Context');

        verify(
          ioSink.writeln(argThat(isNot(containsAdditionalContext))),
        ).called(1);
      },
    );

    test(
      ".print() prints validation result messages for all fields",
      () {
        final results = {
          firstField: successResult,
          secondField: failureResult,
          thirdField: unknownResult,
        };
        final validationResult = ValidationResult(results);

        resultPrinter.print(validationResult);

        results.forEach((field, result) {
          verify(
            ioSink.writeln(argThat(
              validationResultMessageMatcher(field, result),
            )),
          ).called(1);
        });
      },
    );

    test(
      ".print() prints the validation result in the given order",
      () {
        final results = {
          firstField: successResult,
          secondField: failureResult,
          thirdField: unknownResult,
        };
        final validationResult = ValidationResult(results);

        resultPrinter.print(validationResult);

        final expectedMessages = results.entries.map((entry) {
          final field = entry.key;
          final result = entry.value;

          return argThat(
            validationResultMessageMatcher(field, result),
          );
        });

        verifyInOrder(
          expectedMessages.map(ioSink.writeln).toList(),
        );
      },
    );
  });
}
