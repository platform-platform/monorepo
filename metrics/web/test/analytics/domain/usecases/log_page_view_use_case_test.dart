// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/analytics/domain/entities/page_name.dart';
import 'package:metrics/analytics/domain/usecases/log_page_view_use_case.dart';
import 'package:metrics/analytics/domain/usecases/parameters/page_name_param.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/analytics_repository_mock.dart';
import '../../../test_utils/matchers.dart';

void main() {
  group("LogPageViewUseCase", () {
    final repository = AnalyticsRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    final pageNameParam = PageNameParam(pageName: PageName.dashboardPage);

    test("throws an ArgumentError if the given repository is null", () {
      expect(
        () => LogPageViewUseCase(null),
        throwsArgumentError,
      );
    });

    test("delegates call to the given AnalyticsRepository", () async {
      final logPageViewUseCase = LogPageViewUseCase(repository);

      await logPageViewUseCase(pageNameParam);

      verify(repository.logPageView(pageNameParam.pageName.value)).called(once);
    });
  });
}
