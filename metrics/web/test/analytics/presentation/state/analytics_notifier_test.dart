// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/analytics/domain/entities/page_name.dart';
import 'package:metrics/analytics/domain/usecases/log_login_use_case.dart';
import 'package:metrics/analytics/domain/usecases/log_page_view_use_case.dart';
import 'package:metrics/analytics/domain/usecases/parameters/page_name_param.dart';
import 'package:metrics/analytics/domain/usecases/reset_user_use_case.dart';
import 'package:metrics/analytics/presentation/state/analytics_notifier.dart';
import 'package:metrics/common/domain/usecases/parameters/user_id_param.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("AnalyticsNotifier", () {
    const userId = 'id';
    final userParam = UserIdParam(id: userId);
    final logLoginUseCase = _LogLoginUseCaseMock();
    final logPageViewUseCase = _LogPageViewUseCaseMock();
    final resetUserUseCase = _ResetUserUseCaseMock();

    AnalyticsNotifier analyticsNotifier;

    setUp(() {
      reset(logLoginUseCase);
      reset(logPageViewUseCase);
      reset(resetUserUseCase);

      analyticsNotifier = AnalyticsNotifier(
        logLoginUseCase,
        logPageViewUseCase,
        resetUserUseCase,
      );
    });

    test(
      "throws an AssertionError if a log login use case parameter is null",
      () {
        expect(
          () => AnalyticsNotifier(null, logPageViewUseCase, resetUserUseCase),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if a log page view use case parameter is null",
      () {
        expect(
          () => AnalyticsNotifier(logLoginUseCase, null, resetUserUseCase),
          throwsAssertionError,
        );
      },
    );

    test(
      "throws an AssertionError if a reset user use case parameter is null",
      () {
        expect(
          () => AnalyticsNotifier(logLoginUseCase, logPageViewUseCase, null),
          throwsAssertionError,
        );
      },
    );

    test(
      ".logLogin() does not call the use case if the given user id is the same as the stored one",
      () async {
        await analyticsNotifier.logLogin(userId);
        await analyticsNotifier.logLogin(userId);

        verify(logLoginUseCase(userParam)).called(1);
      },
    );

    test(
      ".logLogin() calls the log login use case with the param containing the given user id",
      () async {
        await analyticsNotifier.logLogin(userId);

        verify(logLoginUseCase(userParam)).called(1);
      },
    );

    test(
      ".logPageView() does not call the use case if the given page name does not match the available page names",
      () async {
        const pageName = '/test';

        await analyticsNotifier.logPageView(pageName);

        verifyNever(logPageViewUseCase(any));
      },
    );

    test(
      ".logPageView() calls the log page view use case with the param containing the page name",
      () async {
        final pageName = PageName.values.first;
        final pageParam = PageNameParam(pageName: pageName);

        await analyticsNotifier.logPageView(pageName.value);

        verify(logPageViewUseCase(pageParam)).called(1);
      },
    );

    test(".resetUser() calls the reset user use case", () async {
      await analyticsNotifier.resetUser();

      verify(resetUserUseCase(any)).called(1);
    });

    test(".resetUser() resets the stored user id", () async {
      await analyticsNotifier.logLogin(userId);
      await analyticsNotifier.resetUser();
      await analyticsNotifier.logLogin(userId);

      verify(logLoginUseCase(userParam)).called(2);
    });
  });
}

class _LogLoginUseCaseMock extends Mock implements LogLoginUseCase {}

class _LogPageViewUseCaseMock extends Mock implements LogPageViewUseCase {}

class _ResetUserUseCaseMock extends Mock implements ResetUserUseCase {}
