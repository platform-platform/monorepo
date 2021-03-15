// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/error/sync_error.dart';
import 'package:test/test.dart';

final Matcher throwsSyncError = throwsA(isA<SyncError>());

final Matcher once = equals(1);
