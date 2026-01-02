/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 01:46:42
/// @modify date 2025-09-20 01:46:42
/// @desc [QuickTestButtons: Widget for quick testing of background sync functionality.]
library;

// Add this to any screen for quick testing
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

class QuickTestButtonsWidget extends StatelessWidget {
  const QuickTestButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await Workmanager().registerOneOffTask(
              'quickTest',
              'sync_to_supabase',
              initialDelay: const Duration(seconds: 2),
              inputData: {'quick_test': true},
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Background sync test started! Check logs.'),
              ),
            );
          },
          child: const Text('Test Background Sync'),
        ),
        ElevatedButton(
          onPressed: () async {
            await Workmanager().cancelAll();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All background tasks cancelled')),
            );
          },
          child: const Text('Cancel All Tasks'),
        ),
      ],
    );
  }
}
