// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/config/factory/raw_integration_config_factory.dart';
import 'package:ci_integration/cli/config/model/raw_integration_config.dart';
import 'package:ci_integration/cli/config/parser/raw_integration_config_parser.dart';
import 'package:ci_integration/util/file/file_reader.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("RawIntegrationConfigFactory", () {
    const configPath = 'configPath';
    const content = 'content';

    final fileReader = _FileReaderMock();
    final rawConfigParser = _RawIntegrationConfigParserMock();

    final configFactory = RawIntegrationConfigFactory(
      fileReader: fileReader,
      rawConfigParser: rawConfigParser,
    );

    tearDown(() {
      reset(fileReader);
      reset(rawConfigParser);
    });

    test(
      "creates an instance with the given parameters",
      () {
        final rawConfigFactory = RawIntegrationConfigFactory(
          fileReader: fileReader,
          rawConfigParser: rawConfigParser,
        );

        expect(rawConfigFactory.fileReader, equals(fileReader));
        expect(rawConfigFactory.rawConfigParser, equals(rawConfigParser));
      },
    );

    test(
      "creates an instance with the default file reader, if the given one is null",
      () {
        final rawConfigFactory = RawIntegrationConfigFactory(
          fileReader: null,
          rawConfigParser: rawConfigParser,
        );

        expect(rawConfigFactory.fileReader, isNotNull);
      },
    );

    test(
      "creates an instance with the default raw config parser, if the given one is null",
      () {
        final rawConfigFactory = RawIntegrationConfigFactory(
          fileReader: fileReader,
          rawConfigParser: null,
        );

        expect(rawConfigFactory.rawConfigParser, isNotNull);
      },
    );

    test(
      ".create() throws an ArgumentError if the given path is null",
      () {
        expect(() => configFactory.create(null), throwsArgumentError);
      },
    );

    test(
      ".create() reads the config file contents of the configuration file using the given file reader",
      () {
        configFactory.create(configPath);

        verify(fileReader.read(configPath)).called(once);
      },
    );

    test(
      ".create() parses the config file content using the given raw integration config parser",
      () {
        when(fileReader.read(configPath)).thenReturn(content);

        configFactory.create(configPath);

        verify(rawConfigParser.parse(content)).called(once);
      },
    );

    test(
      ".create() returns the raw integration config parsed by the raw integration config parser",
      () {
        final expectedConfig = RawIntegrationConfig(
          sourceConfigMap: const {},
          destinationConfigMap: const {},
        );
        when(rawConfigParser.parse(any)).thenReturn(expectedConfig);

        final config = configFactory.create(configPath);

        expect(config, equals(expectedConfig));
      },
    );
  });
}

class _FileReaderMock extends Mock implements FileReader {}

class _RawIntegrationConfigParserMock extends Mock
    implements RawIntegrationConfigParser {}
