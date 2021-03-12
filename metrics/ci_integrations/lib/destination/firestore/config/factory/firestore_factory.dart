import 'package:ci_integration/client/firestore/firestore.dart' as fs;
import 'package:firedart/firedart.dart';

/// A factory class that creates a new instance of the [Firestore].
class FirestoreFactory {
  /// Creates a new instance of the [FirestoreFactory].
  const FirestoreFactory();

  /// Creates a new intance of the [Firestore] with the given [firebaseProjectId]
  /// and [firebaseAuth].
  ///
  /// Throws an [ArgumentError] if the given [firebaseProjectId]
  /// or [firebaseAuth] is `null`.
  fs.Firestore create(
    String firebaseProjectId,
    FirebaseAuth firebaseAuth,
  ) {
    ArgumentError.checkNotNull(firebaseProjectId, 'firebaseProjectId');
    ArgumentError.checkNotNull(firebaseAuth, 'firebaseAuth');

    return fs.Firestore(
      firebaseProjectId,
      firebaseAuth: firebaseAuth,
    );
  }
}
