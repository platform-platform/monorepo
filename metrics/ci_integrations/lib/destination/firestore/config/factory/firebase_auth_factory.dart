import 'package:firedart/firedart.dart';

/// A factory class that creates new instance of [FirebaseAuth].
class FirebaseAuthFactory {
  /// Creates an instance of the [FirebaseAuthFactory].
  const FirebaseAuthFactory();

  /// Creates a new instance of the [FirebaseAuth]
  /// with the given [firebaseApiKey].
  ///
  /// Throws an [ArgumentError] if the given [firebaseApiKey] is `null`.
  FirebaseAuth create(String firebaseApiKey) {
    ArgumentError.checkNotNull(firebaseApiKey, 'firebaseApiKey');

    return FirebaseAuth.initialize(
      firebaseApiKey,
      VolatileStore(),
    );
  }

  ///
  Future<FirebaseAuth> createAndAuthenticate(
      String firebaseApiKey, String email, String password) async {
    ArgumentError.checkNotNull(firebaseApiKey, 'firebaseApiKey');
    ArgumentError.checkNotNull(email, 'email');
    ArgumentError.checkNotNull(password, 'password');

    final auth = FirebaseAuth.initialize(
      firebaseApiKey,
      VolatileStore(),
    );

    await auth.signIn(email, password);

    return auth;
  }
}
