/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-13
/// @modify date 2025-09-13
/// @desc [BarcodeScanner: QR Code/Barcode scanner page for vehicle parts tracking]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/models/vehicle_part.dart';
import 'package:job_management_workshop/providers/session_provider.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:job_management_workshop/services/task_parts_requirement_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

/// Barcode Scanner Page for scanning vehicle parts
class BarcodeScannerPage extends StatefulWidget {
  final Task? task;
  final Function(VehiclePart, int)? onPartScanned;

  const BarcodeScannerPage({super.key, this.task, this.onPartScanned});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;
  VehiclePart? scannedPart;
  String? lastScannedCode;
  bool isLoading = false;
  String? errorMessage;
  List<Task> activeTasks = [];
  Task? selectedTask;
  bool isTorchOn = false; // Add torch state tracking

  // Part requirement checking
  bool isPartRequired = false;
  bool isCheckingRequirement = false;
  bool isAlreadyVerified = false;

  // Services
  final TaskPartsRequirementService _partsRequirementService =
      TaskPartsRequirementService();

  // Manual input controllers
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedTask = widget.task; // Use pre-selected task if provided
    _loadActiveTasks();
  }

  Future<void> _loadActiveTasks() async {
    final sessionProvider = Provider.of<SessionProvider>(
      context,
      listen: false,
    );
    try {
      final staffId = sessionProvider.staffId;
      if (staffId == null) return;

      final queryBuilder = await SupabaseService.from('task');
      final response = await queryBuilder
          .select()
          .eq('staff_id', staffId)
          .inFilter('status', [
            TaskStatus.assigned.value,
            TaskStatus.accepted.value,
          ])
          .order('created_at', ascending: false);

      setState(() {
        activeTasks = (response as List)
            .map((json) => Task.fromJson(json))
            .toList();
      });
    } catch (e) {
      AppLogger.error('Error loading active tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parts Scanner'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: isTorchOn
                ? const Icon(Icons.flash_on)
                : const Icon(Icons.flash_off),
            onPressed: () {
              setState(() {
                isTorchOn = !isTorchOn;
              });
              cameraController.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            onPressed: _showManualInputDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final halfHeight = constraints.maxHeight / 2.5;

            return Column(
              children: [
                // Scanner view - Exactly 50% of available height
                SizedBox(
                  height: halfHeight,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _onBarcodeDetected,
                      ),
                      if (isLoading)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Part results panel - Exactly 50% of available height
                SizedBox(
                  height: halfHeight,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: Colors.grey[400]!, width: 2.0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red[700],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (scannedPart != null) ...[
                            _buildPartInfo(),
                          ] else ...[
                            // No part scanned state - flexible content
                            Container(
                              constraints: const BoxConstraints(minHeight: 200),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Scan Part Barcode',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Point camera at barcode or QR code',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(color: Colors.grey[500]),
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _showManualInputDialog,
                                      icon: const Icon(Icons.keyboard),
                                      label: const Text('Enter Manually'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),

                                    // Active tasks info
                                    if (activeTasks.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.blue.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.assignment,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Active Tasks: ${activeTasks.length}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    if (widget.task != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.work,
                                                  color: Colors.green[700],
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Current Task',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.green[700],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.task!.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green[700],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPartInfo() {
    final taskToCheck = selectedTask ?? widget.task;
    final hasTaskContext = taskToCheck != null;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Part name header
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    scannedPart!.partName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Part details
            _buildPartDetailRow('Barcode', scannedPart!.barcode),
            if (scannedPart!.partNumber != null)
              _buildPartDetailRow('Part #', scannedPart!.partNumber!),
            _buildPartDetailRow('Stock', '${scannedPart!.stockQuantity} units'),
            if (scannedPart!.location != null)
              _buildPartDetailRow('Location', scannedPart!.location!),

            const SizedBox(height: 16),

            // Requirement status
            if (hasTaskContext) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCheckingRequirement
                      ? Colors.grey.withValues(alpha: 0.1)
                      : isAlreadyVerified
                      ? Colors.blue.withValues(alpha: 0.1)
                      : isPartRequired
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCheckingRequirement
                        ? Colors.grey.withValues(alpha: 0.3)
                        : isAlreadyVerified
                        ? Colors.blue.withValues(alpha: 0.3)
                        : isPartRequired
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    if (isCheckingRequirement)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        isAlreadyVerified
                            ? Icons.verified
                            : isPartRequired
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: isAlreadyVerified
                            ? Colors.blue[700]
                            : isPartRequired
                            ? Colors.green[700]
                            : Colors.orange[700],
                        size: 16,
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isCheckingRequirement
                            ? 'Checking requirement...'
                            : isAlreadyVerified
                            ? 'Already verified for task: ${taskToCheck.title}'
                            : isPartRequired
                            ? 'Required for task: ${taskToCheck.title}'
                            : 'Not required for task: ${taskToCheck.title}',
                        style: TextStyle(
                          color: isCheckingRequirement
                              ? Colors.grey[700]
                              : isAlreadyVerified
                              ? Colors.blue[700]
                              : isPartRequired
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (!hasTaskContext ||
                                (isPartRequired && !isAlreadyVerified)) &&
                            !isCheckingRequirement
                        ? _directUsePart
                        : null,
                    icon: Icon(
                      isAlreadyVerified
                          ? Icons.verified
                          : isPartRequired || !hasTaskContext
                          ? Icons.check
                          : Icons.block,
                      size: 18,
                    ),
                    label: Text(
                      isAlreadyVerified
                          ? 'Already Used'
                          : hasTaskContext && !isPartRequired
                          ? 'Part Not Required'
                          : 'Use Part',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAlreadyVerified
                          ? Colors.blue
                          : hasTaskContext && isPartRequired
                          ? Colors.green
                          : !hasTaskContext
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _resetScanner,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    for (final barcode in barcodes) {
      if (isScanning &&
          barcode.rawValue != null &&
          barcode.rawValue != lastScannedCode) {
        setState(() {
          isScanning = false;
          lastScannedCode = barcode.rawValue;
        });
        _handleScannedCode(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _handleScannedCode(String code) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      isPartRequired = false;
      isCheckingRequirement = false;
      isAlreadyVerified = false;
    });

    try {
      final queryBuilder = await SupabaseService.from('vehicle_parts');
      final response = await queryBuilder
          .select()
          .eq('barcode', code)
          .maybeSingle();

      if (response != null) {
        setState(() {
          scannedPart = VehiclePart.fromJson(response);
          isLoading = false;
          isCheckingRequirement = true;
        });

        // Check if part is required for the current task
        await _checkPartRequirement(code);
      } else {
        setState(() {
          errorMessage = 'Part not found. Please try manual entry.';
          isLoading = false;
        });
        _showManualInputDialog(initialBarcode: code);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error scanning barcode: $e';
        isLoading = false;
      });
    }
  }

  /// Check if the scanned part is required for the selected task
  Future<void> _checkPartRequirement(String barcode) async {
    try {
      bool required = false;
      bool alreadyVerified = false;

      // Check if we have a selected task (either pre-selected or from active tasks)
      final taskToCheck = selectedTask ?? widget.task;

      if (taskToCheck != null) {
        required = await _partsRequirementService.isBarcodeRequiredForTask(
          taskId: taskToCheck.taskId,
          barcode: barcode,
        );

        // If part is required, check if it's already been fully verified
        if (required) {
          final requirements = await _partsRequirementService
              .getRequirementsByBarcode(
                taskId: taskToCheck.taskId,
                barcode: barcode,
              );

          // Check if any requirement is already fully verified
          alreadyVerified = requirements.any((req) => req.isVerified);
        }
      }

      setState(() {
        isPartRequired = required;
        isAlreadyVerified = alreadyVerified;
        isCheckingRequirement = false;
      });
    } catch (e) {
      AppLogger.error('Error checking part requirement: $e');
      setState(() {
        isPartRequired = false;
        isAlreadyVerified = false;
        isCheckingRequirement = false;
      });
    }
  }

  void _directUsePart() async {
    if (scannedPart == null) return;

    try {
      final taskToUse = selectedTask ?? widget.task;
      final quantity = 1; // Default quantity

      // Check if this barcode is required for the selected task
      bool isRequired = false;
      if (taskToUse != null) {
        isRequired = await _partsRequirementService.isBarcodeRequiredForTask(
          taskId: taskToUse.taskId,
          barcode: lastScannedCode ?? scannedPart!.barcode,
        );
      }

      // Update stock quantity
      final stockQueryBuilder = await SupabaseService.from('vehicle_parts');
      await stockQueryBuilder
          .update({'stock_quantity': scannedPart!.stockQuantity - quantity})
          .eq('part_id', scannedPart!.partId);

      // If this part is required for the task, update the requirement verification
      if (isRequired && taskToUse != null) {
        final requirements = await _partsRequirementService
            .getRequirementsByBarcode(
              taskId: taskToUse.taskId,
              barcode: lastScannedCode ?? scannedPart!.barcode,
            );

        for (final requirement in requirements) {
          final newVerifiedQuantity =
              (requirement.verifiedQuantity ?? 0) + quantity;
          final isFullyVerified =
              newVerifiedQuantity >= requirement.requiredQuantity;

          await _partsRequirementService.updatePartsRequirementVerification(
            requirementId: requirement.requirementId,
            verifiedQuantity: newVerifiedQuantity,
            isVerified: isFullyVerified,
            notes: null,
          );
        }
      }

      if (widget.onPartScanned != null) {
        widget.onPartScanned!(scannedPart!, quantity);
      }

      // Show success message
      final taskInfo = taskToUse != null
          ? ' for task "${taskToUse.title}"'
          : '';

      final verificationStatus = isRequired ? ' ✓ Verified' : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Part used: ${scannedPart!.partName} x$quantity$taskInfo$verificationStatus',
          ),
          backgroundColor: isRequired ? Colors.green : Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back to job details page
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error using part: $e')));
    }
  }

  void _showManualInputDialog({String? initialBarcode}) {
    _barcodeController.text = initialBarcode ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(
                labelText: 'Barcode/QR Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (_barcodeController.text.isNotEmpty) {
                  _handleScannedCode(_barcodeController.text);
                }
              },
              child: const Text('Search Part'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() {
      scannedPart = null;
      lastScannedCode = null;
      isScanning = true;
      errorMessage = null;
      isPartRequired = false;
      isCheckingRequirement = false;
      isAlreadyVerified = false;
      // Don't reset selectedTask if we have a pre-selected task
      if (widget.task == null) {
        selectedTask = null;
      }
    });
    _quantityController.text = '1';
    _notesController.clear();
  }

  @override
  void dispose() {
    cameraController.dispose();
    _barcodeController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
