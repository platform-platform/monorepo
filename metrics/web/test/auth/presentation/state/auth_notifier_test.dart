// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:metrics/auth/domain/entities/auth_error_code.dart';
import 'package:metrics/auth/domain/entities/authentication_exception.dart';
import 'package:metrics/auth/domain/entities/theme_type.dart';
import 'package:metrics/auth/domain/entities/user.dart';
import 'package:metrics/auth/domain/entities/user_profile.dart';
import 'package:metrics/auth/domain/usecases/create_user_profile_usecase.dart';
import 'package:metrics/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:metrics/auth/domain/usecases/parameters/user_credentials_param.dart';
import 'package:metrics/auth/domain/usecases/receive_authentication_updates.dart';
import 'package:metrics/auth/domain/usecases/receive_user_profile_updates.dart';
import 'package:metrics/auth/domain/usecases/sign_in_usecase.dart';
import 'package:metrics/auth/domain/usecases/sign_out_usecase.dart';
import 'package:metrics/auth/domain/usecases/update_user_profile_usecase.dart';
import 'package:metrics/auth/presentation/models/user_profile_model.dart';
import 'package:metrics/auth/presentation/state/auth_notifier.dart';
import 'package:metrics/common/domain/entities/persistent_store_error_code.dart';
import 'package:metrics/common/domain/entities/persistent_store_exception.dart';
import 'package:metrics/common/presentation/models/persistent_store_error_message.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("AuthNotifier", () {
    final signInUseCase = SignInUseCaseMock();
    final googleSignInUseCase = GoogleSignInUseCaseMock();
    final signOutUseCase = SignOutUseCaseMock();
    final receiveAuthUpdates = ReceiveAuthenticationUpdatesMock();
    final receiveUserProfileUpdates = ReceiveUserProfileUpdatesMock();
    final createUserProfileUseCase = CreateUserProfileUseCaseMock();
    final updateUserProfileUseCase = UpdateUserProfileUseCaseMock();

    const authException = AuthenticationException(
      code: AuthErrorCode.unknown,
    );
    const emailAuthException = AuthenticationException(
      code: AuthErrorCode.userNotFound,
    );
    const passwordAuthException = AuthenticationException(
      code: AuthErrorCode.wrongPassword,
    );

    const id = 'id';
    const selectedTheme = ThemeType.dark;

    const email = 'test@email.com';
    const password = 'password';

    const invalidEmail = 'email@mail.mail';
    const invalidPassword = 'password';
    final invalidCredentials = UserCredentialsParam(
      email: Email(invalidEmail),
      password: Password(invalidPassword),
    );

    final user = User(id: id, email: email);
    final userProfile = UserProfile(id: id, selectedTheme: selectedTheme);
    const userProfileModel = UserProfileModel(
      id: 'second id',
      selectedTheme: ThemeType.light,
    );

    final authNotifier = AuthNotifier(
      receiveAuthUpdates,
      signInUseCase,
      googleSignInUseCase,
      signOutUseCase,
      receiveUserProfileUpdates,
      createUserProfileUseCase,
      updateUserProfileUseCase,
    );

    setUpAll(() {
      when(receiveAuthUpdates(any)).thenAnswer((_) => Stream.value(user));

      when(receiveUserProfileUpdates(any)).thenAnswer(
        (_) => Stream.value(userProfile),
      );

      authNotifier.subscribeToAuthenticationUpdates();
    });

    setUp(() {
      reset(signInUseCase);
      reset(googleSignInUseCase);
      reset(signOutUseCase);
      reset(receiveAuthUpdates);
      reset(receiveUserProfileUpdates);
      reset(createUserProfileUseCase);
      reset(updateUserProfileUseCase);
    });

    test("throws AssertionError if a receive auth updates parameter is null",
        () {
      expect(
        () => AuthNotifier(
          null,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        ),
        throwsAssertionError,
      );
    });

    test("throws AssertionError if a sign in use case parameter is null", () {
      expect(
        () => AuthNotifier(
          receiveAuthUpdates,
          null,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        ),
        throwsAssertionError,
      );
    });

    test(
      "throws AssertionError if a google sign in use case parameter is null",
      () {
        expect(
          () => AuthNotifier(
            receiveAuthUpdates,
            signInUseCase,
            null,
            signOutUseCase,
            receiveUserProfileUpdates,
            createUserProfileUseCase,
            updateUserProfileUseCase,
          ),
          throwsAssertionError,
        );
      },
    );

    test("throws AssertionError if a sign out use case parameter is null", () {
      expect(
        () => AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          null,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        ),
        throwsAssertionError,
      );
    });

    test(
      "throws AssertionError if a receive user profile updates parameter is null",
      () {
        expect(
          () => AuthNotifier(
            receiveAuthUpdates,
            signInUseCase,
            googleSignInUseCase,
            signOutUseCase,
            null,
            createUserProfileUseCase,
            updateUserProfileUseCase,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws AssertionError if a create user profile use case parameter is null",
      () {
        expect(
          () => AuthNotifier(
            receiveAuthUpdates,
            signInUseCase,
            googleSignInUseCase,
            signOutUseCase,
            receiveUserProfileUpdates,
            null,
            updateUserProfileUseCase,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws AssertionError if a update user profile use case parameter is null",
      () {
        expect(
          () => AuthNotifier(
            receiveAuthUpdates,
            signInUseCase,
            googleSignInUseCase,
            signOutUseCase,
            receiveUserProfileUpdates,
            createUserProfileUseCase,
            null,
          ),
          throwsAssertionError,
        );
      },
    );

    test(
      ".subscribeToAuthenticationUpdates() delegates to receive auth updates use case",
      () {
        when(receiveAuthUpdates()).thenAnswer((_) => const Stream.empty());

        authNotifier.subscribeToAuthenticationUpdates();

        verify(receiveAuthUpdates.call()).called(equals(1));
      },
    );

    test(
      ".subscribeToAuthenticationUpdates() subscribes to user updates",
      () {
        final userController = StreamController<User>();

        when(receiveAuthUpdates()).thenAnswer((_) => userController.stream);

        authNotifier.subscribeToAuthenticationUpdates();

        expect(userController.hasListener, isTrue);
      },
    );

    test(
      ".subscribeToAuthenticationUpdates() subscribes to a user profile updates stream",
      () {
        final streamController = StreamController<UserProfile>();

        when(receiveAuthUpdates(any)).thenAnswer(
          (_) => Stream.value(user),
        );
        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => streamController.stream,
        );

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        final listener = expectAsyncUntil0(
          () {},
          () => streamController.hasListener,
        );
        authNotifier.subscribeToAuthenticationUpdates();

        authNotifier.addListener(listener);
        streamController.add(userProfile);
      },
    );

    test(
      ".subscribeToAuthenticationUpdates() creates a user profile model once receiving the user profile",
      () {
        final streamController = StreamController<UserProfile>();
        final userProfile = UserProfile(
          id: userProfileModel.id,
          selectedTheme: userProfileModel.selectedTheme,
        );

        when(receiveAuthUpdates(any)).thenAnswer(
          (_) => Stream.value(user),
        );
        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => streamController.stream,
        );

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        authNotifier.subscribeToAuthenticationUpdates();

        final listener = expectAsyncUntil0(
          () {},
          () {
            return authNotifier.userProfileModel == userProfileModel;
          },
        );

        authNotifier.addListener(listener);
        streamController.add(userProfile);
      },
    );

    test(
      ".subscribeToAuthenticationUpdates() delegates to the sign out use case once receiving an error creating user profile",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        const exception = PersistentStoreException(code: errorCode);

        when(receiveAuthUpdates(any)).thenAnswer(
          (_) => Stream.value(user),
        );

        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => Stream.value(null),
        );

        when(createUserProfileUseCase(any)).thenThrow(exception);

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.updateUserProfile(userProfileModel);

        authNotifier.subscribeToAuthenticationUpdates();

        await untilCalled(signOutUseCase());

        verify(signOutUseCase()).called(equals(1));
      },
    );

    test(
      ".subscribeToAuthenticationUpdates() sets the is logged in status to true once receiving a user profile",
      () {
        final userProfile = UserProfile(
          id: 'some id',
          selectedTheme: ThemeType.light,
        );

        when(receiveAuthUpdates(any)).thenAnswer(
          (_) => Stream.value(user),
        );

        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => Stream.value(userProfile),
        );

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        authNotifier.subscribeToAuthenticationUpdates();

        final listener = expectAsyncUntil0(() {}, () {
          if (authNotifier.isLoggedIn != null) {
            return authNotifier.isLoggedIn;
          }

          return false;
        });

        authNotifier.addListener(listener);
      },
    );

    test(
      ".userProfileErrorMessage provides an error description once receiving a persistent store exception",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        final userProfileController = StreamController<UserProfile>();
        const errorMessage = PersistentStoreErrorMessage(errorCode);

        when(receiveAuthUpdates(any)).thenAnswer(
          (_) => Stream.value(user),
        );

        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => userProfileController.stream,
        );

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        authNotifier.subscribeToAuthenticationUpdates();

        userProfileController.addError(const PersistentStoreException(
          code: errorCode,
        ));

        final listener = expectAsyncUntil0(
          () {},
          () => authNotifier.userProfileErrorMessage == errorMessage.message,
        );

        authNotifier.addListener(listener);
      },
    );

    test(".isLoggedIn status is false after a user signs out", () async {
      when(receiveAuthUpdates()).thenAnswer((_) => Stream.value(null));

      final authNotifier = AuthNotifier(
        receiveAuthUpdates,
        signInUseCase,
        googleSignInUseCase,
        signOutUseCase,
        receiveUserProfileUpdates,
        createUserProfileUseCase,
        updateUserProfileUseCase,
      );

      authNotifier.subscribeToAuthenticationUpdates();

      await authNotifier.signOut();

      expect(authNotifier.isLoggedIn, isFalse);
    });

    test(
      ".isLoading status is false until there is no user profile",
      () {
        final userProfileController = StreamController<UserProfile>();

        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => userProfileController.stream,
        );

        when(receiveAuthUpdates(any)).thenAnswer(
          (_) => Stream.value(user),
        );

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        authNotifier.subscribeToAuthenticationUpdates();

        final listener = expectAsyncUntil0(
          () {},
          () => authNotifier.isLoading == false,
        );

        authNotifier.addListener(listener);
        userProfileController.add(userProfile);
      },
    );

    test(
      ".isLoading status is false if .signInWithEmailAndPassword() is finished with an error",
      () async {
        final userCredentials = UserCredentialsParam(
          email: Email(email),
          password: Password(password),
        );

        when(signInUseCase(userCredentials))
            .thenAnswer((_) => Future.error(authException));

        await authNotifier.signInWithEmailAndPassword(email, password);

        expect(authNotifier.isLoading, isFalse);
      },
    );

    test(
      ".isLoading status is false if .signInWithGoogle() is finished with an error",
      () async {
        when(googleSignInUseCase())
            .thenAnswer((_) => Future.error(authException));

        await authNotifier.signInWithGoogle();

        expect(authNotifier.isLoading, isFalse);
      },
    );

    test(
      ".signInWithEmailAndPassword() delegates to sign in use case",
      () async {
        await authNotifier.signInWithEmailAndPassword(email, password);

        final userCredentials = UserCredentialsParam(
          email: Email(email),
          password: Password(password),
        );

        verify(signInUseCase(userCredentials)).called(equals(1));
      },
    );

    test(".signInWithEmailAndPassword() does nothing if isLoading is true", () {
      authNotifier.signInWithGoogle();
      authNotifier.signInWithEmailAndPassword(email, password);

      final userCredentials = UserCredentialsParam(
        email: Email(email),
        password: Password(password),
      );

      verifyNever(signInUseCase(userCredentials));
    });

    test(".signInWithGoogle() delegates to google sign in use case", () async {
      final authNotifier = AuthNotifier(
        receiveAuthUpdates,
        signInUseCase,
        googleSignInUseCase,
        signOutUseCase,
        receiveUserProfileUpdates,
        createUserProfileUseCase,
        updateUserProfileUseCase,
      );

      await authNotifier.signInWithGoogle();

      verify(googleSignInUseCase()).called(equals(1));
    });

    test(".signInWithGoogle() does nothing if isLoading is true", () {
      final authNotifier = AuthNotifier(
        receiveAuthUpdates,
        signInUseCase,
        googleSignInUseCase,
        signOutUseCase,
        receiveUserProfileUpdates,
        createUserProfileUseCase,
        updateUserProfileUseCase,
      );

      authNotifier.signInWithEmailAndPassword(email, password);
      authNotifier.signInWithGoogle();

      verifyNever(googleSignInUseCase());
    });

    test(
      ".authErrorMessage is populated when the auth error occurred during the sign-in process",
      () async {
        when(signInUseCase.call(any))
            .thenAnswer((_) => Future.error(authException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithEmailAndPassword(email, password);

        expect(authNotifier.authErrorMessage, isNotNull);
      },
    );

    test(
      ".emailErrorMessage is populated when the email-related error occurred during the sign-in process",
      () async {
        when(signInUseCase.call(any))
            .thenAnswer((_) => Future.error(emailAuthException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithEmailAndPassword(email, password);

        expect(authNotifier.emailErrorMessage, isNotNull);
      },
    );

    test(
      ".passwordErrorMessage is populated when the password-related error occurred during the sign-in process",
      () async {
        when(signInUseCase.call(any))
            .thenAnswer((_) => Future.error(passwordAuthException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithEmailAndPassword(email, password);

        expect(authNotifier.passwordErrorMessage, isNotNull);
      },
    );

    test(
      ".authErrorMessage is populated when the auth error occurred during the google sign-in process",
      () async {
        when(googleSignInUseCase.call())
            .thenAnswer((_) => Future.error(authException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithGoogle();

        expect(authNotifier.authErrorMessage, isNotNull);
      },
    );

    test(
      ".signInWithEmailAndPassword() clears the authentication error message on a successful sign in",
      () async {
        when(signInUseCase.call(invalidCredentials))
            .thenAnswer((_) => Future.error(authException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithEmailAndPassword(
          invalidEmail,
          invalidPassword,
        );

        expect(authNotifier.authErrorMessage, isNotNull);

        await authNotifier.signInWithEmailAndPassword(email, password);

        expect(authNotifier.authErrorMessage, isNull);
      },
    );

    test(
      ".signInWithEmailAndPassword() clears the authentication email error message on a successful sign in",
      () async {
        when(signInUseCase.call(invalidCredentials))
            .thenAnswer((_) => Future.error(emailAuthException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithEmailAndPassword(
          invalidEmail,
          invalidPassword,
        );

        expect(authNotifier.emailErrorMessage, isNotNull);

        await authNotifier.signInWithEmailAndPassword(email, password);

        expect(authNotifier.emailErrorMessage, isNull);
      },
    );

    test(
      ".signInWithEmailAndPassword() clears the authentication password error message on a successful sign in",
      () async {
        when(signInUseCase.call(invalidCredentials))
            .thenAnswer((_) => Future.error(passwordAuthException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithEmailAndPassword(
          invalidEmail,
          invalidPassword,
        );

        expect(authNotifier.passwordErrorMessage, isNotNull);

        await authNotifier.signInWithEmailAndPassword(email, password);

        expect(authNotifier.passwordErrorMessage, isNull);
      },
    );

    test(
      ".signInWithGoogle() clears the authentication error message on a successful sign in",
      () async {
        when(googleSignInUseCase.call())
            .thenAnswer((_) => Future.error(authException));

        final authNotifier = AuthNotifier(
          receiveAuthUpdates,
          signInUseCase,
          googleSignInUseCase,
          signOutUseCase,
          receiveUserProfileUpdates,
          createUserProfileUseCase,
          updateUserProfileUseCase,
        );

        await authNotifier.signInWithGoogle();

        expect(authNotifier.authErrorMessage, isNotNull);

        when(googleSignInUseCase.call()).thenAnswer((_) => null);

        await authNotifier.signInWithGoogle();

        expect(authNotifier.authErrorMessage, isNull);
      },
    );

    test(
      ".updateUserProfile() delegates to the update user profile use case",
      () async {
        await authNotifier.updateUserProfile(userProfileModel);

        verify(updateUserProfileUseCase(any)).called(1);
      },
    );

    test(
      ".updateUserProfile() does not call the use case if the given user profile is null",
      () async {
        await authNotifier.updateUserProfile(null);

        verifyNever(updateUserProfileUseCase(any));
      },
    );

    test(
      ".updateUserProfile() populates the user profile error message if an error occurred during updating the user profile",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;
        const errorMessage = PersistentStoreErrorMessage(errorCode);

        when(updateUserProfileUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await authNotifier.updateUserProfile(userProfileModel);

        expect(
          authNotifier.userProfileSavingErrorMessage,
          errorMessage.message,
        );
      },
    );

    test(
      ".updateUserProfile() resets the user profile saving error message",
      () async {
        const errorCode = PersistentStoreErrorCode.unknown;

        when(updateUserProfileUseCase(any)).thenThrow(
          const PersistentStoreException(code: errorCode),
        );

        await authNotifier.updateUserProfile(userProfileModel);

        expect(
          authNotifier.userProfileSavingErrorMessage,
          isNotNull,
        );

        reset(updateUserProfileUseCase);

        await authNotifier.updateUserProfile(userProfileModel);

        expect(
          authNotifier.userProfileSavingErrorMessage,
          isNull,
        );
      },
    );

    test(
      ".updateUserProfile() does not call the use case if the given user profile is the same as in the notifier",
      () async {
        final updatedUserProfile = UserProfileModel(
          id: userProfile.id,
          selectedTheme: userProfile.selectedTheme,
        );

        final streamController = StreamController<UserProfile>();

        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => streamController.stream,
        );

        authNotifier.addListener(() async {
          await authNotifier.updateUserProfile(updatedUserProfile);

          verifyNever(updateUserProfileUseCase(any));
        });
        streamController.add(userProfile);
      },
    );

    test(".signOut() delegates to the sign out use case", () async {
      await authNotifier.signOut();

      verify(signOutUseCase()).called(equals(1));
    });

    test(".signOut() cancels the user profile subscription", () async {
      final userProfileController = StreamController<UserProfile>();

      when(receiveAuthUpdates()).thenAnswer((_) => Stream.value(user));
      when(receiveUserProfileUpdates(any)).thenAnswer(
        (_) => userProfileController.stream,
      );

      final authNotifier = AuthNotifier(
        receiveAuthUpdates,
        signInUseCase,
        googleSignInUseCase,
        signOutUseCase,
        receiveUserProfileUpdates,
        createUserProfileUseCase,
        updateUserProfileUseCase,
      );

      authNotifier.subscribeToAuthenticationUpdates();

      authNotifier.addListener(() async {
        expect(userProfileController.hasListener, isTrue);

        await authNotifier.signOut();

        expect(userProfileController.hasListener, isFalse);
      });

      userProfileController.add(userProfile);
    });

    test(
      ".dispose() cancels all created subscriptions",
      () {
        final userController = StreamController<User>();
        final userProfileController = StreamController<UserProfile>();

        when(receiveAuthUpdates()).thenAnswer((_) => userController.stream);
        when(receiveUserProfileUpdates(any)).thenAnswer(
          (_) => userProfileController.stream,
        );

        authNotifier.subscribeToAuthenticationUpdates();

        authNotifier.addListener(() {
          expect(userController.hasListener, isTrue);
          expect(userProfileController.hasListener, isTrue);

          authNotifier.dispose();

          expect(userController.hasListener, isFalse);
          expect(userProfileController.hasListener, isFalse);
        });

        userProfileController.add(userProfile);
      },
    );
  });
}

class SignInUseCaseMock extends Mock implements SignInUseCase {}

class GoogleSignInUseCaseMock extends Mock implements GoogleSignInUseCase {}

class SignOutUseCaseMock extends Mock implements SignOutUseCase {}

class ReceiveAuthenticationUpdatesMock extends Mock
    implements ReceiveAuthenticationUpdates {}

class ReceiveUserProfileUpdatesMock extends Mock
    implements ReceiveUserProfileUpdates {}

class CreateUserProfileUseCaseMock extends Mock
    implements CreateUserProfileUseCase {}

class UpdateUserProfileUseCaseMock extends Mock
    implements UpdateUserProfileUseCase {}
