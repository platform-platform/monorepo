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
}
