// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/auth/presentation/strings/auth_strings.dart';
import 'package:metrics/auth/presentation/widgets/password_sign_in_option.dart';
import 'package:metrics/base/presentation/widgets/svg_image.dart';
import 'package:metrics/base/presentation/widgets/tappable_area.dart';
import 'package:metrics/common/presentation/button/widgets/metrics_positive_button.dart';
import 'package:metrics/common/presentation/metrics_theme/model/login_theme_data.dart';
import 'package:metrics/common/presentation/metrics_theme/model/metrics_theme_data.dart';
import 'package:metrics/common/presentation/widgets/metrics_text_form_field.dart';
import 'package:mockito/mockito.dart';
import 'package:network_image_mock/network_image_mock.dart';

import '../../../test_utils/auth_notifier_mock.dart';
import '../../../test_utils/matchers.dart';
import '../../../test_utils/metrics_themed_testbed.dart';
import '../../../test_utils/test_injection_container.dart';

void main() {
  group("PasswordSignInOption", () {
    const passwordVisibilityIconColor = Colors.red;
    const metricsThemeData = MetricsThemeData(
      loginTheme: LoginThemeData(
        passwordVisibilityIconColor: passwordVisibilityIconColor,
      ),
    );

    final emailInputFinder =
        find.widgetWithText(MetricsTextFormField, AuthStrings.email);
    final passwordInputFinder =
        find.widgetWithText(MetricsTextFormField, AuthStrings.password);
    final submitButtonFinder =
        find.widgetWithText(MetricsPositiveButton, AuthStrings.signIn);

    const testEmail = 'test@email.com';
    const testPassword = 'testPassword';
    const errorMessage = 'Error Message';

    AuthNotifier authNotifier;

    Widget _getPasswordFieldSuffixIcon(WidgetTester tester) {
      final passwordField = tester.widget<MetricsTextFormField>(
        passwordInputFinder,
      );

      return passwordField.suffixIcon;
    }

    setUp(() {
      authNotifier = AuthNotifierMock();
      when(authNotifier.isLoading).thenReturn(false);
    });

    testWidgets(
      "email input shows an error message if a value is empty on submit",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _PasswordSignInOptionTestbed(authNotifier: authNotifier),
          );
        });

        await tester.tap(submitButtonFinder);
        await tester.pumpAndSettle();

        expect(
          find.text(AuthStrings.emailRequiredErrorMessage),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "email input shows an error message if a value is not a valid email on submit",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _PasswordSignInOptionTestbed(authNotifier: authNotifier),
          );
        });

        await tester.enterText(emailInputFinder, 'notAnEmail');

        await tester.tap(submitButtonFinder);
        await tester.pump();

        expect(find.text(AuthStrings.invalidEmailErrorMessage), findsOneWidget);
      },
    );

    testWidgets(
      "password input shows an error message if a value is empty on submit",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _PasswordSignInOptionTestbed(authNotifier: authNotifier),
          );
        });

        await tester.tap(submitButtonFinder);
        await tester.pump();

        expect(
          find.text(AuthStrings.passwordRequiredErrorMessage),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      "uses the AuthNotifier to sign in a user with login and password",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _PasswordSignInOptionTestbed(authNotifier: authNotifier),
          );
        });

        await tester.enterText(emailInputFinder, testEmail);
        await tester.enterText(passwordInputFinder, testPassword);
        await tester.tap(submitButtonFinder);

        verify(
          authNotifier.signInWithEmailAndPassword(testEmail, testPassword),
        ).called(once);
      },
    );

    testWidgets(
      "shows a progress indicator if the sign in process is in progress",
      (WidgetTester tester) async {
        when(authNotifier.authErrorMessage).thenReturn(null);
        when(authNotifier.isLoading).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_PasswordSignInOptionTestbed(
            authNotifier: authNotifier,
          ));
        });

        final finder = find.byType(LinearProgressIndicator);

        expect(finder, findsOneWidget);
      },
    );

    testWidgets(
      "disables the submit button if the sign in process is in progress",
      (WidgetTester tester) async {
        when(authNotifier.authErrorMessage).thenReturn(null);
        when(authNotifier.isLoading).thenReturn(true);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(_PasswordSignInOptionTestbed(
            authNotifier: authNotifier,
          ));
        });

        final button = tester.widget<RaisedButton>(
          find.descendant(
            of: submitButtonFinder,
            matching: find.byType(RaisedButton),
          ),
        );

        expect(button.enabled, isFalse);
      },
    );

    testWidgets(
      "applies the enabled eye icon to the password input field if the password is obscured",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(
          () => tester.pumpWidget(
            const _PasswordSignInOptionTestbed(),
          ),
        );

        final suffixIcon = _getPasswordFieldSuffixIcon(tester);
        final image = tester.widget<SvgImage>(find.descendant(
          of: find.byWidget(suffixIcon),
          matching: find.byType(SvgImage),
        ));

        expect(image.src, equals('icons/eye_on.svg'));
      },
    );

    testWidgets(
      "applies the disabled eye icon to the password input field if the password is not obscured",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(
          () => tester.pumpWidget(
            const _PasswordSignInOptionTestbed(),
          ),
        );

        final suffixIcon = _getPasswordFieldSuffixIcon(tester);

        await tester.tap(find.byWidget(suffixIcon));
        await mockNetworkImagesFor(() {
          return tester.pump();
        });

        final suffixIconAfterTap = _getPasswordFieldSuffixIcon(tester);
        final image = tester.widget<SvgImage>(find.descendant(
          of: find.byWidget(suffixIconAfterTap),
          matching: find.byType(SvgImage),
        ));

        expect(image.src, equals('icons/eye_off.svg'));
      },
    );

    testWidgets(
      "applies the color from the metrics theme to the password visibility icon",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(
          () => tester.pumpWidget(
            const _PasswordSignInOptionTestbed(
              metricsThemeData: metricsThemeData,
            ),
          ),
        );

        final suffixIcon = _getPasswordFieldSuffixIcon(tester);
        final image = tester.widget<SvgImage>(find.descendant(
          of: find.byWidget(suffixIcon),
          matching: find.byType(SvgImage),
        ));

        expect(image.color, equals(passwordVisibilityIconColor));
      },
    );

    testWidgets(
      "applies a tappable area to the suffix icon of the password field",
      (WidgetTester tester) async {
        await mockNetworkImagesFor(
          () => tester.pumpWidget(
            const _PasswordSignInOptionTestbed(),
          ),
        );

        final suffixIcon = _getPasswordFieldSuffixIcon(tester);
        final imageWidget = tester.widget<SvgImage>(find.descendant(
          of: find.byWidget(suffixIcon),
          matching: find.byType(SvgImage),
        ));
        final tappableAreaFinder = find.ancestor(
          of: find.byWidget(imageWidget),
          matching: find.byType(TappableArea),
        );

        expect(tappableAreaFinder, findsOneWidget);
      },
    );

    testWidgets(
      "applies the email error message to the email field",
      (tester) async {
        when(authNotifier.emailErrorMessage).thenReturn(errorMessage);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _PasswordSignInOptionTestbed(authNotifier: authNotifier),
          );
        });

        final emailField = tester.widget<MetricsTextFormField>(
          emailInputFinder,
        );

        expect(emailField.errorText, equals(errorMessage));
      },
    );

    testWidgets(
      "applies the password error message to the password field",
      (tester) async {
        when(authNotifier.passwordErrorMessage).thenReturn(errorMessage);

        await mockNetworkImagesFor(() {
          return tester.pumpWidget(
            _PasswordSignInOptionTestbed(authNotifier: authNotifier),
          );
        });

        final passwordField = tester.widget<MetricsTextFormField>(
          passwordInputFinder,
        );

        expect(passwordField.errorText, equals(errorMessage));
      },
    );
  });
}

/// A testbed widget used to test the [PasswordSignInOption] widget.
class _PasswordSignInOptionTestbed extends StatelessWidget {
  /// An [AuthNotifier] to use in tests.
  final AuthNotifier authNotifier;

  /// A [MetricsThemeData] to use in tests.
  final MetricsThemeData metricsThemeData;

  /// Creates the [_PasswordSignInOptionTestbed] with the given [authNotifier].
  const _PasswordSignInOptionTestbed({
    this.metricsThemeData = const MetricsThemeData(),
    this.authNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return TestInjectionContainer(
      authNotifier: authNotifier,
      child: MetricsThemedTestbed(
        metricsThemeData: metricsThemeData,
        body: const PasswordSignInOption(),
      ),
    );
  }
}
