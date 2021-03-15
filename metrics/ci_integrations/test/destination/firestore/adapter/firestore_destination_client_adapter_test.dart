// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/data/deserializer/build_data_deserializer.dart';
import 'package:ci_integration/destination/error/destination_error.dart';
import 'package:ci_integration/destination/firestore/adapter/firestore_destination_client_adapter.dart';
import 'package:firedart/firedart.dart';
import 'package:grpc/grpc.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../test_utils/test_data/collection_reference_mock.dart';
import '../test_utils/test_data/document_mock.dart';
import '../test_utils/test_data/document_reference_mock.dart';
import '../test_utils/test_data/firestore_mock.dart';

// ignore_for_file: avoid_implementing_value_types

void main() {
  group("FirestoreDestinationClientAdapter", () {
    const testProjectId = 'projectId';
    const testDocumentId = 'documentId';
    final buildDataTestJson = {
      'buildNumber': 1,
      'startedAt': DateTime.now(),
      'buildStatus': BuildStatus.failed.toString(),
      'duration': 100,
      'workflowName': 'testWorkflowName',
      'url': 'testUrl',
      'coverage': 0.1,
    };
    const testProjectIds = [
      '${testProjectId}_1',
      '${testProjectId}_2',
    ];
    const builds = [
      BuildData(buildNumber: 1),
      BuildData(buildNumber: 2),
    ];
    final _firestoreMock = FirestoreMock();
    final _collectionReferenceMock = CollectionReferenceMock();
    final _documentReferenceMock = DocumentReferenceMock();
    final _documentMock = DocumentMock();
    final adapter = FirestoreDestinationClientAdapter(_firestoreMock);
    final grpcError = GrpcError.cancelled();

    final Matcher throwsDestinationError = throwsA(isA<DestinationError>());

    PostExpectation<Future<Document>> whenFetchProject({
      String collectionId = 'projects',
      String projectId = testProjectId,
    }) {
      when(_firestoreMock.collection(collectionId))
          .thenReturn(_collectionReferenceMock);
      when(_collectionReferenceMock.document(projectId))
          .thenReturn(_documentReferenceMock);
      return when(_documentReferenceMock.get());
    }

    PostExpectation<Future<List<Document>>> whenFetchLastBuild({
      String collectionId = 'build',
      String whereFieldPath = 'projectId',
      dynamic isEqualTo = testProjectId,
      String orderByFieldPath = 'startedAt',
      int limit = 1,
    }) {
      when(_firestoreMock.collection(collectionId))
          .thenReturn(_collectionReferenceMock);
      when(_collectionReferenceMock.where(whereFieldPath, isEqualTo: isEqualTo))
          .thenReturn(_collectionReferenceMock);
      when(_collectionReferenceMock.orderBy(orderByFieldPath, descending: true))
          .thenReturn(_collectionReferenceMock);
      when(_collectionReferenceMock.limit(limit))
          .thenReturn(_collectionReferenceMock);
      return when(_collectionReferenceMock.getDocuments());
    }

    setUp(() {
      reset(_firestoreMock);
      reset(_collectionReferenceMock);
      reset(_documentReferenceMock);
      reset(_documentMock);
    });

    test(
      "throws an ArgumentError if the given Firestore is null",
      () {
        expect(
          () => FirestoreDestinationClientAdapter(null),
          throwsArgumentError,
        );
      },
    );

    test(
      ".addBuilds() throws an ArgumentError if a project with the given id does not exist",
      () {
        whenFetchProject().thenAnswer((_) => Future.value(_documentMock));
        when(_documentMock.exists).thenReturn(false);

        final result = adapter.addBuilds(testProjectId, []);

        expect(result, throwsArgumentError);
      },
    );

    test(
      ".addBuilds() throws a DestinationError if fetching a project throws",
      () {
        whenFetchProject().thenThrow(grpcError);

        final result = adapter.addBuilds(testProjectId, []);

        expect(result, throwsDestinationError);
      },
    );

    test(
      ".addBuilds() does not add builds if fetching the project throws",
      () {
        whenFetchProject().thenThrow(grpcError);

        final result = adapter.addBuilds(testProjectId, []);

        expect(result, throwsDestinationError);
        verifyNever(_firestoreMock.collection('build'));
      },
    );

    test(
      ".addBuilds() does not add builds if a project with the given id does not exist",
      () {
        whenFetchProject().thenAnswer((_) => Future.value(_documentMock));
        when(_documentMock.exists).thenReturn(false);

        final result = adapter.addBuilds(testProjectId, []);

        expect(result, throwsArgumentError);
        verifyNever(_firestoreMock.collection('build'));
      },
    );

    test(
      ".addBuilds() throws a DestinationError if creating a build throws",
      () {
        whenFetchProject().thenAnswer((_) => Future.value(_documentMock));
        when(_documentMock.exists).thenReturn(true);
        when(_documentMock.id).thenReturn(testProjectId);
        when(_firestoreMock.collection('build'))
            .thenReturn(_collectionReferenceMock);
        when(_collectionReferenceMock.document(
          argThat(anyOf(testProjectIds)),
        )).thenReturn(_documentReferenceMock);
        when(_documentReferenceMock.create(argThat(anything)))
            .thenAnswer((_) => Future.error(grpcError));

        final result = adapter.addBuilds(testProjectId, builds);
        expect(result, throwsDestinationError);
      },
    );

    test(
      ".addBuilds() adds given builds for the given project",
      () async {
        whenFetchProject().thenAnswer((_) => Future.value(_documentMock));
        when(_documentMock.exists).thenReturn(true);
        when(_documentMock.id).thenReturn(testProjectId);
        when(_firestoreMock.collection('build'))
            .thenReturn(_collectionReferenceMock);
        when(_collectionReferenceMock.document(
          argThat(anyOf(testProjectIds)),
        )).thenReturn(_documentReferenceMock);
        when(_documentReferenceMock.create(argThat(anything)))
            .thenAnswer((_) => Future.value(_documentMock));

        await adapter.addBuilds(testProjectId, builds);

        verify(_documentReferenceMock.create(any)).called(builds.length);
      },
    );

    test(
      ".addBuilds() stops adding builds if adding one of them is failed",
      () async {
        const builds = [
          BuildData(buildNumber: 1),
          BuildData(buildNumber: 2),
          BuildData(buildNumber: 3),
        ];
        final buildsData = builds
            .map((build) => build.copyWith(projectId: testProjectId).toJson())
            .toList();

        whenFetchProject().thenAnswer((_) => Future.value(_documentMock));
        when(_documentMock.exists).thenReturn(true);
        when(_documentMock.id).thenReturn(testProjectId);
        when(_firestoreMock.collection('build'))
            .thenReturn(_collectionReferenceMock);

        when(_collectionReferenceMock.document(any))
            .thenReturn(_documentReferenceMock);

        when(_documentReferenceMock.create(argThat(anyOf(
          buildsData[0],
          buildsData[2],
        )))).thenAnswer((_) => Future.value(_documentMock));
        when(_documentReferenceMock.create(buildsData[1]))
            .thenAnswer((_) => Future.error(grpcError));

        final result = adapter.addBuilds(testProjectId, builds);
        await expectLater(result, throwsDestinationError);

        verify(_documentReferenceMock.create(any)).called(2);
        verifyNever(_documentReferenceMock.create(buildsData[2]));
      },
    );

    test(".addBuilds() adds builds in the given order", () async {
      const builds = [
        BuildData(buildNumber: 1),
        BuildData(buildNumber: 2),
      ];
      final buildsData = builds
          .map((build) => build.copyWith(projectId: testProjectId).toJson())
          .toList();

      whenFetchProject().thenAnswer((_) => Future.value(_documentMock));
      when(_documentMock.exists).thenReturn(true);
      when(_documentMock.id).thenReturn(testProjectId);
      when(_firestoreMock.collection('build'))
          .thenReturn(_collectionReferenceMock);

      when(_collectionReferenceMock.document(any))
          .thenReturn(_documentReferenceMock);
      when(_documentReferenceMock.create(any))
          .thenAnswer((_) => Future.value(_documentMock));

      await adapter.addBuilds(testProjectId, builds);

      verifyInOrder([
        _documentReferenceMock.create(buildsData[0]),
        _documentReferenceMock.create(buildsData[1]),
      ]);
    });

    test(
      ".fetchLastBuild() returns null if there are no builds for a project with the given id",
      () {
        whenFetchLastBuild().thenAnswer((_) => Future.value([]));

        final result = adapter.fetchLastBuild(testProjectId);

        expect(result, completion(isNull));
      },
    );

    test(
      ".fetchLastBuild() returns the last build for a project with the given id",
      () {
        whenFetchLastBuild().thenAnswer((_) => Future.value([_documentMock]));
        when(_documentMock.id).thenReturn(testDocumentId);
        when(_documentMock.map).thenReturn(buildDataTestJson);

        final buildData = adapter.fetchLastBuild(testProjectId);
        final expectedBuildData = BuildDataDeserializer.fromJson(
          buildDataTestJson,
          testDocumentId,
        );

        expect(buildData, completion(equals(expectedBuildData)));
      },
    );
  });
}
