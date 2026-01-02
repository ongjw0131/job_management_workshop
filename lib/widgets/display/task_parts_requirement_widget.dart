/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-21
/// @modify date 2025-09-21
/// @desc [TaskPartsRequirementWidget: Widget to display required parts for a task with verification status and barcode scanning]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/models/task_parts_requirement.dart';
import 'package:job_management_workshop/views/barcode_scanner_page.dart';

class TaskPartsRequirementWidget extends StatelessWidget {
  final List<TaskPartsRequirement> requirements;
  final Task task;
  final VoidCallback? onRefresh;

  const TaskPartsRequirementWidget({
    super.key,
    required this.requirements,
    required this.task,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (requirements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'No parts requirements defined for this task',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: task.status == TaskStatus.accepted
                    ? () => _navigateToScanner(context)
                    : null,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Parts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: task.status == TaskStatus.accepted
                      ? null
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate overall progress
    int totalRequired = requirements.fold(
      0,
      (sum, r) => sum + r.requiredQuantity,
    );
    int totalVerified = requirements.fold(
      0,
      (sum, r) => sum + (r.verifiedQuantity ?? 0),
    );
    double overallProgress = totalRequired > 0
        ? totalVerified / totalRequired
        : 0.0;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Required Parts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: task.status == TaskStatus.accepted
                      ? () => _navigateToScanner(context)
                      : null,
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: task.status == TaskStatus.accepted
                        ? Colors.green
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Overall progress indicator
          if (requirements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Overall Progress: $totalVerified / $totalRequired',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${(overallProgress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: overallProgress == 1.0
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: overallProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overallProgress == 1.0 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // List of requirements
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requirements.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final requirement = requirements[index];
              return _buildRequirementItem(context, requirement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context,
    TaskPartsRequirement requirement,
  ) {
    final progress = requirement.verificationProgress;
    final isFullyVerified = requirement.isFullyVerified;
    final remaining = requirement.remainingQuantity;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isFullyVerified ? Colors.green : Colors.orange,
        child: Icon(
          isFullyVerified ? Icons.check : Icons.pending,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        requirement.partName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Barcode: ${requirement.barcode}'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(
                'Required: ${requirement.requiredQuantity}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Verified: ${requirement.verifiedQuantity ?? 0}',
                style: const TextStyle(fontSize: 12),
              ),
              if (!isFullyVerified)
                Text(
                  'Remaining: $remaining',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              isFullyVerified ? Colors.green : Colors.orange,
            ),
          ),
          if (requirement.notes != null && requirement.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Notes: ${requirement.notes}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
      trailing: isFullyVerified
          ? const Icon(Icons.verified, color: Colors.green)
          : IconButton(
              onPressed: task.status == TaskStatus.accepted
                  ? () => _navigateToScanner(context, requirement.barcode)
                  : null,
              icon: Icon(
                Icons.qr_code_scanner,
                color: task.status == TaskStatus.accepted ? null : Colors.grey,
              ),
              tooltip: task.status == TaskStatus.accepted
                  ? 'Scan barcode for ${requirement.partName}'
                  : 'Accept task first to scan parts',
            ),
    );
  }

  void _navigateToScanner(BuildContext context, [String? specificBarcode]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          task: task,
          onPartScanned: (part, quantity) {
            // Refresh the requirements after scanning
            onRefresh?.call();
          },
        ),
      ),
    ).then((_) {
      // Refresh when coming back from scanner
      onRefresh?.call();
    });
  }
}
