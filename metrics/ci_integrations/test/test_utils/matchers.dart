// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/cli/error/sync_error.dart';
import 'package:test/test.dart';

final throwsSyncError = throwsA(isA<SyncError>());

final once = equals(1);
