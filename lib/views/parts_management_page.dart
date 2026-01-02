/// @author [Ong Jun Wei]
/// @email [ongjw-wm22@student.tarc.edu.my]
/// @create date 2025-09-13
/// @modify date 2025-09-13
/// @desc [PartsManagementPage: Demo page showing how to integrate barcode scanner with parts management]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/barcode_controller.dart';
import 'package:job_management_workshop/models/task.dart';
import 'package:job_management_workshop/models/vehicle_part.dart';
import 'package:job_management_workshop/views/barcode_scanner_page.dart';

class PartsManagementPage extends StatefulWidget {
  final Task? selectedTask;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const PartsManagementPage({
    super.key,
    this.selectedTask,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<PartsManagementPage> createState() => _PartsManagementPageState();
}

class _PartsManagementPageState extends State<PartsManagementPage> {
  final BarcodeController _barcodeController = BarcodeController();
  List<VehiclePart> _parts = [];
  List<Map<String, dynamic>> _partsUsage = [];
  bool _isLoading = false;
  String? _selectedCategory;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final categoriesResult = await _barcodeController.getPartCategories();
    if (categoriesResult.success) {
      _categories = categoriesResult.data ?? [];
    }
    await _loadParts();
    if (widget.selectedTask != null) {
      await _loadTaskPartsUsage();
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadParts() async {
    final result = await _barcodeController.getAllParts(
      category: _selectedCategory,
    );
    if (result.success) {
      setState(() {
        _parts = result.data ?? [];
      });
    } else {
      _showError(result.error ?? 'Failed to load parts');
    }
  }

  Future<void> _loadTaskPartsUsage() async {
    if (widget.selectedTask == null) return;
    final result = await _barcodeController.getTaskPartsUsage(
      widget.selectedTask!.taskId,
    );
    if (result.success) {
      setState(() {
        _partsUsage = result.data ?? [];
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _openBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          task: widget.selectedTask,
          onPartScanned: (part, quantity) {
            _loadTaskPartsUsage();
            _loadParts();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectedTask != null
              ? 'Parts for ${widget.selectedTask!.title}'
              : 'Parts Management',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openBarcodeScanner,
            tooltip: 'Scan Barcode',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: widget.selectedTask != null ? 2 : 1,
              child: Column(
                children: [
                  if (widget.selectedTask != null)
                    const TabBar(
                      tabs: [
                        Tab(text: 'Available Parts'),
                        Tab(text: 'Parts Used'),
                      ],
                    ),
                  Expanded(
                    child: widget.selectedTask != null
                        ? TabBarView(
                            children: [
                              _buildPartsListView(),
                              _buildPartsUsageView(),
                            ],
                          )
                        : _buildPartsListView(),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openBarcodeScanner,
        tooltip: 'Scan Part Barcode',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildPartsListView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              ..._categories.map(
                (category) =>
                    DropdownMenuItem(value: category, child: Text(category)),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              _loadParts();
            },
          ),
        ),
        Expanded(
          child: _parts.isEmpty
              ? const Center(child: Text('No parts found'))
              : ListView.builder(
                  itemCount: _parts.length,
                  itemBuilder: (context, index) {
                    final part = _parts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(part.partName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Barcode: ${part.barcode}'),
                            if (part.partNumber != null)
                              Text('Part #: ${part.partNumber}'),
                            Text('Stock: ${part.stockQuantity}'),
                            if (part.location != null)
                              Text('Location: ${part.location}'),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (part.category != null)
                              Chip(
                                label: Text(
                                  part.category!,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            if (part.unitPrice != null)
                              Text(
                                '\$${part.unitPrice!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        leading: CircleAvatar(
                          backgroundColor: part.stockQuantity > 0
                              ? Colors.green
                              : Colors.red,
                          child: Text(
                            part.stockQuantity.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPartsUsageView() {
    return _partsUsage.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No parts used yet'),
                SizedBox(height: 8),
                Text('Scan barcodes to record part usage'),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _partsUsage.length,
            itemBuilder: (context, index) {
              final usage = _partsUsage[index];
              final part = usage['vehicle_parts'];
              final staff = usage['staff'];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(part['part_name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity Used: ${usage['quantity_used']}'),
                      Text(
                        'Used by: ${staff['first_name']} ${staff['last_name']}',
                      ),
                      Text(
                        'Date: ${DateTime.parse(usage['usage_date']).toString().split('.')[0]}',
                      ),
                      if (usage['notes'] != null && usage['notes'].isNotEmpty)
                        Text('Notes: ${usage['notes']}'),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor: usage['manual_entry']
                        ? Colors.orange
                        : Colors.blue,
                    child: Icon(
                      usage['manual_entry']
                          ? Icons.keyboard
                          : Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                  ),
                  trailing: usage['scanned_barcode'] != null
                      ? Text(
                          usage['scanned_barcode'],
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                ),
              );
            },
          );
  }
}
