import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/services/auto_save_service.dart';

final autoSaveManagerProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);

  if (user != null && ledgerId != null) {
    debugPrint(
      'AutoSaveManager: Initializing AutoSaveService for user ${user.id} and ledger $ledgerId',
    );
    AutoSaveService.instance
        .initialize(userId: user.id, ledgerId: ledgerId)
        .then((_) {
          AutoSaveService.instance.start();
        })
        .catchError((e) {
          debugPrint('AutoSaveManager: Initialization failed: $e');
        });
  } else {
    debugPrint(
      'AutoSaveManager: User or Ledger not selected. Stopping service.',
    );
    // Check if status is not 'notInitialized' instead of checking isInitialized
    if (AutoSaveService.instance.status != AutoSaveStatus.notInitialized) {
      AutoSaveService.instance.stop();
      AutoSaveService.instance.dispose();
    }
  }
});
