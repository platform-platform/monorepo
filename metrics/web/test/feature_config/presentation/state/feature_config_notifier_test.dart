// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/feature_config/domain/entities/feature_config.dart';
import 'package:metrics/feature_config/domain/usecases/fetch_feature_config_usecase.dart';
import 'package:metrics/feature_config/domain/usecases/parameters/feature_config_param.dart';
import 'package:metrics/feature_config/presentation/state/feature_config_notifier.dart';
import 'package:metrics/feature_config/presentation/view_models/debug_menu_feature_config_view_model.dart';
import 'package:metrics/feature_config/presentation/view_models/password_sign_in_option_feature_config_view_model.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("FeatureConfigNotifier", () {
    const isPasswordSignInOptionEnabled = true;
    const isDebugMenuEnabled = true;

    const featureConfig = FeatureConfig(
      isPasswordSignInOptionEnabled: isPasswordSignInOptionEnabled,
      isDebugMenuEnabled: isDebugMenuEnabled,
    );

    final _fetchFeatureConfigUseCase = _FetchFeatureConfigUseCaseMock();

    FeatureConfigNotifier notifier;

    setUp(() {
      notifier = FeatureConfigNotifier(_fetchFeatureConfigUseCase);

      notifier.setDefaults(
        isPasswordSignInOptionEnabled: isPasswordSignInOptionEnabled,
        isDebugMenuEnabled: isDebugMenuEnabled,
      );
    });

    tearDown(() {
      reset(_fetchFeatureConfigUseCase);
    });

    test(
      "throws an AssertionError if the given fetch feature config use case is null",
      () {
        expect(
          () => FeatureConfigNotifier(null),
          throwsAssertionError,
        );
      },
    );

    test(
      "creates an instance with the given fetch feature config use case",
      () {
        expect(
          () => FeatureConfigNotifier(_fetchFeatureConfigUseCase),
          returnsNormally,
        );
      },
    );

    test(
      ".setDefaults() throws an AssertionError if the given is password sign in option enabled is null",
      () {
        expect(
          () => notifier.setDefaults(
            isPasswordSignInOptionEnabled: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      ".setDefaults() throws an AssertionError if the given is debug menu enabled is null",
      () {
        expect(
          () => notifier.setDefaults(
            isDebugMenuEnabled: null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      ".initializeConfig() sets the .isLoading to true when called",
      () {
        when(_fetchFeatureConfigUseCase(any)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        notifier.setDefaults(isPasswordSignInOptionEnabled: true);
        final param = FeatureConfigParam(
          isPasswordSignInOptionEnabled: true,
          isDebugMenuEnabled: false,
        );

        notifier.initializeConfig();

        verify(_fetchFeatureConfigUseCase(param)).called(once);
        expect(notifier.isLoading, isTrue);
      },
    );

    test(
      ".initializeConfig() sets the .isLoading to false when finished",
      () async {
        when(_fetchFeatureConfigUseCase(any)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        notifier.setDefaults(isPasswordSignInOptionEnabled: true);
        final param = FeatureConfigParam(
          isPasswordSignInOptionEnabled: true,
          isDebugMenuEnabled: false,
        );

        await notifier.initializeConfig();

        verify(_fetchFeatureConfigUseCase(param)).called(once);
        expect(notifier.isLoading, isFalse);
      },
    );

    test(
      ".initializeConfig() calls the fetch feature config use case",
      () {
        when(_fetchFeatureConfigUseCase(any)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        notifier.setDefaults(isPasswordSignInOptionEnabled: true);
        final param = FeatureConfigParam(
          isPasswordSignInOptionEnabled: true,
          isDebugMenuEnabled: false,
        );

        notifier.initializeConfig();

        verify(_fetchFeatureConfigUseCase(param)).called(once);
      },
    );

    test(
      ".initializeConfig() uses the given default values when fetching the feature config",
      () {
        final featureConfigParam = FeatureConfigParam(
          isPasswordSignInOptionEnabled: isPasswordSignInOptionEnabled,
          isDebugMenuEnabled: isDebugMenuEnabled,
        );
        when(_fetchFeatureConfigUseCase(featureConfigParam)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        notifier.setDefaults(
          isPasswordSignInOptionEnabled: isPasswordSignInOptionEnabled,
          isDebugMenuEnabled: isDebugMenuEnabled,
        );
        notifier.initializeConfig();

        verify(_fetchFeatureConfigUseCase(featureConfigParam)).called(once);
      },
    );

    test(
      ".initializeConfig() sets the login form feature config view model",
      () async {
        const expectedViewModel = PasswordSignInOptionFeatureConfigViewModel(
          isEnabled: isPasswordSignInOptionEnabled,
        );
        when(_fetchFeatureConfigUseCase(any)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        await notifier.initializeConfig();

        expect(
          notifier.passwordSignInOptionFeatureConfigViewModel,
          equals(expectedViewModel),
        );
      },
    );

    test(
      ".initializeConfig() sets the debug menu feature config view model",
      () async {
        const expectedViewModel = DebugMenuFeatureConfigViewModel(
          isEnabled: isDebugMenuEnabled,
        );
        when(_fetchFeatureConfigUseCase(any)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        await notifier.initializeConfig();

        expect(
          notifier.debugMenuFeatureConfigViewModel,
          equals(expectedViewModel),
        );
      },
    );

    test(
      ".initializeConfig() sets the is loading value to false when initialization is completed",
      () async {
        when(_fetchFeatureConfigUseCase(any)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        await notifier.initializeConfig();

        expect(notifier.isLoading, isFalse);
      },
    );

    test(
      ".isInitialized returns true if the current config is initialized",
      () async {
        when(_fetchFeatureConfigUseCase(any)).thenAnswer(
          (_) => Future.value(featureConfig),
        );

        await notifier.initializeConfig();

        expect(notifier.isInitialized, isTrue);
      },
    );

    test(
      ".isInitialized returns false if the current config is not initialized",
      () async {
        expect(notifier.isInitialized, isFalse);
      },
    );
  });
}

class _FetchFeatureConfigUseCaseMock extends Mock
    implements FetchFeatureConfigUseCase {}
