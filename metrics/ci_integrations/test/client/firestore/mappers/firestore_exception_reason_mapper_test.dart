// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/firestore/mappers/firestore_exception_reason_mapper.dart';
import 'package:ci_integration/client/firestore/models/firestore_exception_reason.dart';
import 'package:test/test.dart';

void main() {
  group("FirestoreExceptionReasonMapper", () {
    const mapper = FirestoreExceptionReasonMapper();

    test(
      ".map() maps the consumer invalid Firestore exception reason to FirestoreExceptionReason.consumerInvalid",
      () {
        const expectedReason = FirestoreExceptionReason.consumerInvalid;

        final reason = mapper.map(
          FirestoreExceptionReasonMapper.consumerInvalid,
        );

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".map() maps the not found Firestore exception reason to FirestoreExceptionReason.notFound",
      () {
        const expectedReason = FirestoreExceptionReason.notFound;

        final reason = mapper.map(FirestoreExceptionReasonMapper.notFound);

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".map() maps the project deleted Firestore exception reason to FirestoreExceptionReason.projectDeleted",
      () {
        const expectedReason = FirestoreExceptionReason.projectDeleted;

        final reason = mapper.map(
          FirestoreExceptionReasonMapper.projectDeleted,
        );

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".map() maps the project invalid Firestore exception reason to FirestoreExceptionReason.projectInvalid",
      () {
        const expectedReason = FirestoreExceptionReason.projectInvalid;

        final reason = mapper.map(
          FirestoreExceptionReasonMapper.projectInvalid,
        );

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".map() returns null if the given value does not match any FirestoreExceptionReason value",
      () {
        final reason = mapper.map('test');

        expect(reason, isNull);
      },
    );

    test(
      ".map() maps the null Firestore exception reason to null",
      () {
        final reason = mapper.map(null);

        expect(reason, isNull);
      },
    );

    test(
      ".unmap() unmaps the FirestoreExceptionReason.consumerInvalid to the consumer invalid Firestore exception reason",
      () {
        const expectedReason = FirestoreExceptionReasonMapper.consumerInvalid;

        final reason = mapper.unmap(FirestoreExceptionReason.consumerInvalid);

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".unmap() unmaps the FirestoreExceptionReason.notFound to the not found Firestore exception reason",
      () {
        const expectedReason = FirestoreExceptionReasonMapper.notFound;

        final reason = mapper.unmap(FirestoreExceptionReason.notFound);

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".unmap() unmaps the FirestoreExceptionReason.projectDeleted to the project deleted Firestore exception reason",
      () {
        const expectedReason = FirestoreExceptionReasonMapper.projectDeleted;

        final reason = mapper.unmap(FirestoreExceptionReason.projectDeleted);

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".unmap() unmaps the FirestoreExceptionReason.projectInvalid to the project invalid Firestore exception reason",
      () {
        const expectedReason = FirestoreExceptionReasonMapper.projectInvalid;

        final reason = mapper.unmap(FirestoreExceptionReason.projectInvalid);

        expect(reason, equals(expectedReason));
      },
    );

    test(
      ".unmap() unmaps null Firestore exception reason to null",
      () {
        final reason = mapper.unmap(null);

        expect(reason, isNull);
      },
    );
  });
}
