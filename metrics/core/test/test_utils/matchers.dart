// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:test/test.dart';

/// A matcher that can be used to detect that test case throws
/// an [AssertionError].
final Matcher throwsAssertionError = throwsA(isA<AssertionError>());
