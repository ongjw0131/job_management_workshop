/// @author [Woo Keng Keong, Chong Jun Xiang]
/// @email [wookk-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 16:33:57
/// @modify date 2025-09-20 16:33:57
/// @desc [TermsCardWidget: A widget that displays a card with terms and conditions, a button to view the full terms, and a checkbox for agreement.]
library;

import 'package:flutter/material.dart';

class TermsCardWidget extends StatelessWidget {
  final String terms;
  final VoidCallback onViewTerms;
  final Widget agreementCheckbox;

  const TermsCardWidget({
    super.key,
    required this.terms,
    required this.onViewTerms,
    required this.agreementCheckbox,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please read and accept the Terms & Conditions before signing',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    terms,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onViewTerms,
                  child: const Text('View Terms'),
                ),
              ],
            ),
            agreementCheckbox,
          ],
        ),
      ),
    );
  }
}

// ...existing code...
