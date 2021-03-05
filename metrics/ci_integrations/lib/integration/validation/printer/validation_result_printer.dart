// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:io';

import 'package:ci_integration/integration/interface/base/config/model/config_field.dart';
import 'package:ci_integration/integration/validation/model/field_validation_conclusion.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/mappers/field_validation_conclusion_mapper.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';

/// A class that is responsible for printing the [ValidationResult].
class ValidationResultPrinter {
  /// An instance of the [IOSink] this printer uses to print the result.
  final IOSink ioSink;

  /// Create a new instance of the [ValidationResultPrinter] with the given
  /// [ioSink].
  ///
  /// If the [ioSink] is `null`, an instance of the standard output stream is
  /// used.
  ValidationResultPrinter({
    IOSink ioSink,
  }) : ioSink = ioSink ?? stdout;

  /// Prints the given [result] to the [ioSink].
  void print(ValidationResult result) {
    final validationResults = result.results;

    final validationResultEntries = validationResults.entries;

    for (final entry in validationResultEntries) {
      final field = entry.key;
      final result = entry.value;

      final message = _buildFieldValidationOutput(
        field,
        result,
      );

      ioSink.writeln(message);
    }
  }

  /// Builds the output that provides the information
  /// about the [fieldValidationResult] for the given [field].
  String _buildFieldValidationOutput(
    ConfigField field,
    FieldValidationResult fieldValidationResult,
  ) {
    final conclusionMarker = _getConclusionMarker(
      fieldValidationResult.conclusion,
    );
    final fieldName = field.value;
    final result = _getFieldValidationResultMessage(fieldValidationResult);

    return '[$conclusionMarker] $fieldName: $result';
  }

  /// Converts the given [validationResult] to its [String] representation.
  ///
  /// Converts the [validationResult.conclusion] to the [String] representation
  /// using the [FieldValidationConclusionMapper].
  ///
  /// Specifies the [validationResult.additionalContext] if it is not `null`.
  String _getFieldValidationResultMessage(
    FieldValidationResult validationResult,
  ) {
    const conclusionMapper = FieldValidationConclusionMapper();

    final conclusionValue = conclusionMapper.unmap(validationResult.conclusion);

    final resultMessage = '$conclusionValue.';

    final additionalContext = validationResult.additionalContext;
    if (additionalContext != null) {
      return '$resultMessage Additional context: $additionalContext';
    }

    return resultMessage;
  }

  /// Returns a marker that illustrates the given [conclusion].
  ///
  /// Returns `+` if the given [conclusion] is [FieldValidationConclusion.valid].
  /// Returns `-` if the given [conclusion] is [FieldValidationConclusion.invalid].
  /// Returns `?` if the given [conclusion] is [FieldValidationConclusion.unknown].
  /// Otherwise, returns `null`.
  String _getConclusionMarker(FieldValidationConclusion conclusion) {
    switch (conclusion) {
      case FieldValidationConclusion.valid:
        return '+';
      case FieldValidationConclusion.invalid:
        return '-';
      case FieldValidationConclusion.unknown:
        return '?';
    }
    return null;
  }
}
