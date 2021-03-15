// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/command/validate_command.dart';
import 'package:ci_integration/cli/config/factory/raw_integration_config_factory.dart';
import 'package:ci_integration/cli/config/model/raw_integration_config.dart';
import 'package:ci_integration/cli/configured_parties/configured_destination_party.dart';
import 'package:ci_integration/cli/configured_parties/configured_parties.dart';
import 'package:ci_integration/cli/configured_parties/configured_source_party.dart';
import 'package:ci_integration/cli/configured_parties/factory/configured_parties_factory.dart';
import 'package:ci_integration/cli/logger/factory/logger_factory.dart';
import 'package:ci_integration/cli/logger/manager/logger_manager.dart';
import 'package:ci_integration/integration/error/config_validation_error.dart';
import 'package:ci_integration/integration/interface/base/config/model/config.dart';
import 'package:ci_integration/integration/interface/base/config/validator/config_validator.dart';
import 'package:ci_integration/integration/interface/base/config/validator_factory/config_validator_factory.dart';
import 'package:ci_integration/integration/interface/base/party/integration_party.dart';
import 'package:ci_integration/integration/interface/destination/client/destination_client.dart';
import 'package:ci_integration/integration/interface/source/client/source_client.dart';
import 'package:ci_integration/integration/interface/source/config/model/source_config.dart';
import 'package:ci_integration/integration/interface/destination/config/model/destination_config.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:ci_integration/integration/validation/model/validation_result.dart';
import 'package:ci_integration/integration/validation/printer/validation_result_printer.dart';
import 'package:ci_integration/source/buildkite/config/model/buildkite_source_config_field.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../test_utils/matchers.dart';
import '../test_util/destination_config_stub.dart';
import '../test_util/mock/destination_party_mock.dart';
import '../test_util/mock/logger_writer_mock.dart';
import '../test_util/mock/source_party_mock.dart';
import '../test_util/source_config_stub.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("ValidateCommand", () {
    final validateCommand = ValidateCommand();

    const configFilePath = 'path';
    final rawIntegrationConfig = RawIntegrationConfig(
      sourceConfigMap: const {},
      destinationConfigMap: const {},
    );
    const successfulResult = FieldValidationResult.success();
    final sourceValidationResult = ValidationResult({
      BuildkiteSourceConfigField.accessToken: successfulResult,
    });
    final destinationValidationResult = ValidationResult({
      BuildkiteSourceConfigField.pipelineSlug: successfulResult,
    });

    final rawIntegrationConfigFactory = _RawIntegrationConfigFactoryMock();
    final configuredPartiesFactory = _ConfiguredPartiesFactoryMock();
    final validationResultPrinter = _ValidationResultPrinterMock();
    final sourceParty = SourcePartyMock<SourceConfig, SourceClient>();
    final destinationParty =
        DestinationPartyMock<DestinationConfig, DestinationClient>();
    final sourceConfigValidatorFactory =
        _ConfigValidatorFactoryMock<SourceConfig>();
    final destinationConfigValidatorFactory =
        _ConfigValidatorFactoryMock<DestinationConfig>();
    final sourceConfigValidator = _ConfigValidatorMock<SourceConfig>();
    final destinationConfigValidator =
        _ConfigValidatorMock<DestinationConfig>();

    final sourceConfig = SourceConfigStub();
    final configuredSourceParty = ConfiguredSourceParty(
      config: sourceConfig,
      party: sourceParty,
    );

    final destinationConfig = DestinationConfigStub();
    final configuredDestinationParty = ConfiguredDestinationParty(
      config: destinationConfig,
      party: destinationParty,
    );

    final configuredParties = ConfiguredParties(
      configuredSourceParty: configuredSourceParty,
      configuredDestinationParty: configuredDestinationParty,
    );

    final commandStub = _ValidateCommandStub(
      rawIntegrationConfigFactory: rawIntegrationConfigFactory,
      configuredPartiesFactory: configuredPartiesFactory,
      validationResultPrinter: validationResultPrinter,
      configFilePath: configFilePath,
    );

    PostExpectation<ConfiguredParties> whenCreateConfiguredParties() {
      when(
        rawIntegrationConfigFactory.create(configFilePath),
      ).thenReturn(rawIntegrationConfig);

      return when(configuredPartiesFactory.create(rawIntegrationConfig));
    }

    PostExpectation<Future<ValidationResult>> whenValidateConfig(
      IntegrationParty party,
      ConfigValidatorFactory validatorFactory,
      Config config,
      ConfigValidator validator,
    ) {
      when(
        party.configValidatorFactory,
      ).thenReturn(validatorFactory);

      when(
        validatorFactory.create(config),
      ).thenReturn(validator);

      return when(validator.validate(config));
    }

    PostExpectation<Future<ValidationResult>> whenValidateSourceConfig() {
      return whenValidateConfig(
        sourceParty,
        sourceConfigValidatorFactory,
        sourceConfig,
        sourceConfigValidator,
      );
    }

    PostExpectation<Future<ValidationResult>> whenValidateDestinationConfig() {
      return whenValidateConfig(
        destinationParty,
        destinationConfigValidatorFactory,
        destinationConfig,
        destinationConfigValidator,
      );
    }

    Matcher isConfigValidationMessage(Config config) {
      return equals('Validating ${config.runtimeType}...');
    }

    final throwsConfigValidationError = throwsA(isA<ConfigValidationError>());

    final writerMock = LoggerWriterMock();
    final loggerFactory = LoggerFactory(writer: writerMock);

    setUpAll(() {
      LoggerManager.setLoggerFactory(loggerFactory);
      LoggerManager.instance.reset();
    });

    tearDown(() {
      reset(rawIntegrationConfigFactory);
      reset(configuredPartiesFactory);
      reset(validationResultPrinter);
      reset(sourceParty);
      reset(destinationParty);
      reset(sourceConfigValidatorFactory);
      reset(destinationConfigValidatorFactory);
      reset(sourceConfigValidator);
      reset(destinationConfigValidator);
      reset(writerMock);
    });

    test(
      "has the 'validate' name",
      () {
        expect(validateCommand.name, equals('validate'));
      },
    );

    test(
      "has a non-empty description",
      () {
        final description = validateCommand.description;

        expect(description, isNotEmpty);
      },
    );

    test(
      "has the 'config-file' option",
      () {
        final argParser = validateCommand.argParser;

        expect(argParser.options, contains('config-file'));
      },
    );

    test(
      "'config-file' option has a non-empty help",
      () {
        final argParser = validateCommand.argParser;

        final option = argParser.options['config-file'];

        expect(option.help, isNotEmpty);
      },
    );

    test(
      "'config-file' option has a non-empty value help",
      () {
        final argParser = validateCommand.argParser;

        final option = argParser.options['config-file'];

        expect(option.valueHelp, isNotEmpty);
      },
    );

    test(
      "creates an instance with the default raw integration config factory if the given one is null",
      () {
        final validateCommand = ValidateCommand(
          rawIntegrationConfigFactory: null,
        );

        expect(validateCommand.rawIntegrationConfigFactory, isNotNull);
      },
    );

    test(
      "creates an instance with the default configured parties factory if the given one is null",
      () {
        final validateCommand = ValidateCommand(configuredPartiesFactory: null);

        expect(validateCommand.rawIntegrationConfigFactory, isNotNull);
      },
    );

    test(
      "creates an instance with the default validation result printer if the given one is null",
      () {
        final validateCommand = ValidateCommand(validationResultPrinter: null);

        expect(validateCommand.rawIntegrationConfigFactory, isNotNull);
      },
    );

    test(
      "creates an instance with the given parameters",
      () {
        final validateCommand = ValidateCommand(
          rawIntegrationConfigFactory: rawIntegrationConfigFactory,
          configuredPartiesFactory: configuredPartiesFactory,
          validationResultPrinter: validationResultPrinter,
        );

        expect(
          validateCommand.rawIntegrationConfigFactory,
          equals(rawIntegrationConfigFactory),
        );
        expect(
          validateCommand.configuredPartiesFactory,
          equals(configuredPartiesFactory),
        );
        expect(
          validateCommand.validationResultPrinter,
          equals(validationResultPrinter),
        );
      },
    );

    test(
      ".run() creates the raw integration config using the raw integration config factory and the config file path",
      () {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        commandStub.run();

        verify(rawIntegrationConfigFactory.create(configFilePath)).called(once);
      },
    );

    test(
      ".run() throws a ConfigValidationError if there is an error occurred during the raw integration config creation",
      () {
        when(
          rawIntegrationConfigFactory.create(configFilePath),
        ).thenThrow(Exception());

        expect(() => commandStub.run(), throwsConfigValidationError);
      },
    );

    test(
      ".run() creates the configured parties using the configured parties factory and the raw integration config",
      () {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        commandStub.run();

        verify(
          configuredPartiesFactory.create(rawIntegrationConfig),
        ).called(once);
      },
    );

    test(
      ".run() throws a ConfigValidationError if there is an error occurred during the configured parties creation",
      () {
        when(
          configuredPartiesFactory.create(any),
        ).thenThrow(Exception());

        expect(() => commandStub.run(), throwsConfigValidationError);
      },
    );

    test(
      ".run() creates the source config validator using the config validator factory and the config from the configured source party",
      () {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        final sourceConfig = configuredParties.configuredSourceParty.config;

        commandStub.run();

        verify(sourceConfigValidatorFactory.create(sourceConfig)).called(once);
      },
    );

    test(
      ".run() throws a ConfigValidationError if there is an error occurred during the source config validator creation",
      () {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        when(sourceConfigValidatorFactory.create(any)).thenThrow(Exception());

        expect(() => commandStub.run(), throwsConfigValidationError);
      },
    );

    test(
      ".run() validates the source config using the source config validator",
      () {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        final sourceConfig = configuredParties.configuredSourceParty.config;

        commandStub.run();

        verify(sourceConfigValidator.validate(sourceConfig)).called(once);
      },
    );

    test(
      ".run() logs a message when validating the source config",
      () async {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        final sourceConfig = configuredParties.configuredSourceParty.config;

        await commandStub.run();

        verify(writerMock.write(argThat(
          isConfigValidationMessage(sourceConfig),
        ))).called(once);
      },
    );

    test(
      ".run() throws a ConfigValidationError if there is an error occurred during the source config validation",
      () {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer(
          (_) => Future.error(Exception()),
        );

        expect(() => commandStub.run(), throwsConfigValidationError);
      },
    );

    test(
      ".run() prints the source config's validation result",
      () async {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer(
          (_) => Future.value(sourceValidationResult),
        );
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        await commandStub.run();

        verify(
          validationResultPrinter.print(sourceValidationResult),
        ).called(once);
      },
    );

    test(
      ".run() creates the destination config validator using the config validator factory and the config from the configured destination party",
      () async {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        final destinationConfig =
            configuredParties.configuredDestinationParty.config;

        await commandStub.run();

        verify(
          destinationConfigValidatorFactory.create(destinationConfig),
        ).called(once);
      },
    );

    test(
      ".run() throws a ConfigValidationError if there is an error occurred during the destination config validator creation",
      () {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        when(
          destinationConfigValidatorFactory.create(any),
        ).thenThrow(Exception());

        expect(() => commandStub.run(), throwsConfigValidationError);
      },
    );

    test(
      ".run() validates the destination config using the destination config validator",
      () async {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        final destinationConfig =
            configuredParties.configuredDestinationParty.config;

        await commandStub.run();

        verify(
          destinationConfigValidator.validate(destinationConfig),
        ).called(once);
      },
    );

    test(
      ".run() logs a message when validating the destination config",
      () async {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer((_) => Future.value());

        final destinationConfig =
            configuredParties.configuredDestinationParty.config;

        await commandStub.run();

        verify(writerMock.write(argThat(
          isConfigValidationMessage(destinationConfig),
        ))).called(once);
      },
    );

    test(
      ".run() throws a ConfigValidationError if there is an error occurred during the destination config validation",
      () async {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer(
          (_) => Future.error(Exception()),
        );

        expect(() => commandStub.run(), throwsConfigValidationError);
      },
    );

    test(
      ".run() prints the destination config's validation result",
      () async {
        whenCreateConfiguredParties().thenReturn(configuredParties);
        whenValidateSourceConfig().thenAnswer((_) => Future.value());
        whenValidateDestinationConfig().thenAnswer(
          (_) => Future.value(destinationValidationResult),
        );

        await commandStub.run();

        verify(
          validationResultPrinter.print(destinationValidationResult),
        ).called(once);
      },
    );
  });
}

class _RawIntegrationConfigFactoryMock extends Mock
    implements RawIntegrationConfigFactory {}

class _ConfiguredPartiesFactoryMock extends Mock
    implements ConfiguredPartiesFactory {}

class _ValidationResultPrinterMock extends Mock
    implements ValidationResultPrinter {}

class _ConfigValidatorFactoryMock<T extends Config> extends Mock
    implements ConfigValidatorFactory<T> {}

class _ConfigValidatorMock<T extends Config> extends Mock
    implements ConfigValidator<T> {}

/// A stub class for a [ValidateCommand] class providing test implementation
/// for methods.
class _ValidateCommandStub extends ValidateCommand {
  /// A path to the configuration file to use in tests.
  final String configFilePath;

  /// Creates an instance of the [_ValidateCommandStub]
  /// with the given parameters.
  _ValidateCommandStub({
    RawIntegrationConfigFactory rawIntegrationConfigFactory,
    ConfiguredPartiesFactory configuredPartiesFactory,
    ValidationResultPrinter validationResultPrinter,
    this.configFilePath = 'config-file',
  }) : super(
          rawIntegrationConfigFactory: rawIntegrationConfigFactory,
          configuredPartiesFactory: configuredPartiesFactory,
          validationResultPrinter: validationResultPrinter,
        );

  @override
  dynamic getArgumentValue(String argumentName) {
    if (argumentName == 'config-file') return configFilePath;
  }
}
