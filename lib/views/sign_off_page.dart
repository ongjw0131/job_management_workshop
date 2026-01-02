/// @author [Woo Keng Keong, Chong Jun Xiang]
/// @email [wookk-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 16:34:12
/// @modify date 2025-09-20 16:34:12
/// @desc [SignOffPage: A page that allows users to view terms and conditions, agree to them, and provide a signature for task completion.]
library;

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/signature_controller.dart';
import 'package:job_management_workshop/widgets/inputs/confirm_checkbox_widget.dart';
import 'package:job_management_workshop/widgets/utils/terms_card_widget.dart';
import 'package:signature/signature.dart';

class SignOffPage extends StatefulWidget {
  final int taskId;

  const SignOffPage({super.key, required this.taskId});

  @override
  State<SignOffPage> createState() => _SignOffPageState();
}

class _SignOffPageState extends State<SignOffPage> {
  late final SignaturePageController _controller;
  final String _terms =
      '''By signing, you confirm that the work has been completed to your satisfaction and you consent to the electronic signature being recorded and stored. You authorize the service provider to update the task as signed and acknowledge that this signature is legally binding for acknowledgement of task completion. If you have any concerns, do not sign and contact the service provider.''';

  @override
  void initState() {
    super.initState();
    _controller = SignaturePageController();
    _controller.addListener(_onControllerChanged);
  }

  void _showTermsDialog() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms & Conditions'),
        content: SingleChildScrollView(child: Text(_terms)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    // mark viewed and accept state in controller
    _controller.markViewedAndMaybeAccept(accepted == true);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Off')),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TermsCardWidget(
                terms: _terms,
                onViewTerms: _showTermsDialog,
                agreementCheckbox: ConfirmCheckboxWidget(
                  value: _controller.agreed,
                  onChanged: (v) => _controller.setAgreed(v),
                  showError: false,
                  label: 'I agree to the Terms & Conditions',
                ),
              ),
            ),
            Expanded(
              child: ClipRect(
                child: Container(
                  color: Colors.grey[200],
                  child: Stack(
                    children: [
                      AbsorbPointer(
                        absorbing: !_controller.agreed,
                        child: Signature(
                          controller: _controller.signatureController,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      if (!_controller.agreed)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withOpacity(0.75),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                ),
                                child: Text(
                                  'Please agree to the Terms & Conditions before signing.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _controller.isUploading
                        ? null
                        : _controller.clearSignature,
                    child: const Text('Clear'),
                  ),
                  ElevatedButton(
                    onPressed: _controller.canSubmit
                        ? () => _controller.submitSignature(
                            context,
                            widget.taskId,
                          )
                        : null,
                    child: _controller.isUploading
                        ? const Text('Submitting...')
                        : const Text('Submit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
