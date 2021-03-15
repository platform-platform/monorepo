// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/auth/presentation/widgets/sign_in_option_button.dart';
import 'package:metrics/auth/presentation/widgets/strategy/sign_in_option_appearance_strategy.dart';
import 'package:metrics/common/presentation/button/theme/style/metrics_button_style.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/auth_notifier_mock.dart';
import '../../../test_utils/finder_util.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/test_injection_container.dart';

// ignore_for_file: avoid_redundant_argument_values

void main() {
  group("SignInOptionButton", () {
    const label = 'Label';
    const asset = 'icons/icon.svg';
    const buttonStyle = MetricsButtonStyle(
      color: Colors.green,
      hoverColor: Colors.lightGreen,
      labelStyle: TextStyle(
        color: Colors.white,
        fontSize: 12.0,
      ),
      elevation: 4.0,
    );

    const strategyStub = _SignInOptionAppearanceStrategyStub(
      asset: asset,
      label: label,
      style: buttonStyle,
    );

    final buttonFinder = find.ancestor(
      of: find.text(label),
      matching: find.byType(RaisedButton),
    );

    testWidgets(
      "throws an AssertionError if the given strategy is null",
      (tester) async {
        await tester.pumpWidget(const _LoginOptionButtonTestbed(
          strategy: null,
        ));

        expect(tester.takeException(), isAssertionError);
      },
    );

    testWidgets(
      "displays an asset from the given strategy",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginOptionButtonTestbed(
            strategy: strategyStub,
          ));
        });

        final image = FinderUtil.findSvgImage(tester);
        final source = image.src;

        expect(source, equals(asset));
      },
    );

    testWidgets(
      "displays a label from the given strategy",
      (tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginOptionButtonTestbed(
            strategy: strategyStub,
          ));
        });

        final finder = find.text(label);

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "applies a label text style from the style given by the strategy",
      (tester) async {
        final expectedStyle = strategyStub.getWidgetAppearance().labelStyle;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginOptionButtonTestbed(
            strategy: strategyStub,
          ));
        });

        final text = tester.widget<Text>(find.text(label));
        final style = text.style;

        expect(style, equals(expectedStyle));
      },
    );

    testWidgets(
      "applies a color from the style given by the strategy",
      (tester) async {
        final expectedColor = strategyStub.getWidgetAppearance().color;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginOptionButtonTestbed(
            strategy: strategyStub,
          ));
        });

        final button = tester.widget<RaisedButton>(buttonFinder);
        final color = button.color;

        expect(color, equals(expectedColor));
      },
    );

    testWidgets(
      "applies a disabled color from the style given by the strategy",
      (tester) async {
        final expectedColor = strategyStub.getWidgetAppearance().color;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginOptionButtonTestbed(
            strategy: strategyStub,
          ));
        });

        final button = tester.widget<RaisedButton>(buttonFinder);
        final disabledColor = button.disabledColor;

        expect(disabledColor, equals(expectedColor));
      },
    );

    testWidgets(
      "applies a hover color from the style given by the strategy",
      (tester) async {
        final expectedColor = strategyStub.getWidgetAppearance().hoverColor;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginOptionButtonTestbed(
            strategy: strategyStub,
          ));
        });

        final button = tester.widget<RaisedButton>(buttonFinder);
        final hoverColor = button.hoverColor;

        expect(hoverColor, equals(expectedColor));
      },
    );

    testWidgets(
      "applies an elevation from the style given by the strategy",
      (tester) async {
        final expectedElevation = strategyStub.getWidgetAppearance().elevation;

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(const _LoginOptionButtonTestbed(
            strategy: strategyStub,
          ));
        });

        final button = tester.widget<RaisedButton>(buttonFinder);

        expect(button.elevation, equals(expectedElevation));
        expect(button.hoverElevation, equals(expectedElevation));
        expect(button.focusElevation, equals(expectedElevation));
        expect(button.highlightElevation, equals(expectedElevation));
      },
    );

    testWidgets(
      "calls the sign in method from the given strategy when the option button is pressed",
      (tester) async {
        final authNotifierMock = AuthNotifierMock();
        final strategyMock = _SignInOptionAppearanceStrategyMock();

        when(authNotifierMock.isLoading).thenReturn(false);
        when(strategyMock.asset).thenReturn(asset);
        when(strategyMock.label).thenReturn(label);
        when(strategyMock.getWidgetAppearance(any, any)).thenReturn(
          const MetricsButtonStyle(),
        );

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_LoginOptionButtonTestbed(
            authNotifier: authNotifierMock,
            strategy: strategyMock,
          ));
        });

        await tester.tap(buttonFinder);

        verify(strategyMock.signIn(authNotifierMock)).called(once);
      },
    );

    testWidgets(
      "disabled when the login process is in progress",
      (tester) async {
        final authNotifierMock = AuthNotifierMock();

        when(authNotifierMock.isLoading).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_LoginOptionButtonTestbed(
            authNotifier: authNotifierMock,
            strategy: strategyStub,
          ));
        });

        final buttonWidget = tester.widget<RaisedButton>(buttonFinder);

        expect(buttonWidget.enabled, isFalse);
      },
    );
  });
}

/// A testbed widget, used to test the [SignInOptionButton] widget.
class _LoginOptionButtonTestbed extends StatelessWidget {
  /// An [AuthNotifier] to use in tests.
  final AuthNotifier authNotifier;

  /// A [SignInOptionAppearanceStrategy] to apply for the button under tests.
  final SignInOptionAppearanceStrategy strategy;

  /// Creates a new instance of the [_LoginOptionButtonTestbed].
  ///
  /// The [metricsThemeData] defaults to an empty [MetricsThemeData] instance.
  const _LoginOptionButtonTestbed({
    Key key,
    this.authNotifier,
    this.strategy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      authNotifier: authNotifier,
      child: MetricsThemedTestbed(
        body: SignInOptionButton(
          strategy: strategy,
        ),
      ),
    );
  }
}

class _SignInOptionAppearanceStrategyMock extends Mock
    implements SignInOptionAppearanceStrategy {}

/// A stub implementation of the [SignInOptionAppearanceStrategy] to use in tests.
class _SignInOptionAppearanceStrategyStub
    implements SignInOptionAppearanceStrategy {
  @override
  final String asset;

  @override
  final String label;

  /// A [MetricsButtonStyle] used in tests.
  final MetricsButtonStyle _style;

  /// Creates a new instance of the sign in option stub.
  ///
  /// The [asset] defaults to the `asset`.
  /// The [label] defaults to the `label`.
  /// The [style] defaults to an empty [MetricsButtonStyle].
  const _SignInOptionAppearanceStrategyStub({
    this.asset = 'asset',
    this.label = 'label',
    MetricsButtonStyle style = const MetricsButtonStyle(),
  }) : _style = style;

  @override
  void signIn(AuthNotifier notifier) {}

  @override
  MetricsButtonStyle getWidgetAppearance([
    MetricsThemeData themeData,
    bool value,
  ]) {
    return _style;
  }
}
