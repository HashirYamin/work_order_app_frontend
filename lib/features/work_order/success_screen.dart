import 'package:flutter/material.dart';

import '../../shared/widgets/app_button.dart';
import 'work_order_screen.dart';

class SuccessScreen extends StatelessWidget {
  final String workOrderNumber;
  final int photoCount;

  const SuccessScreen({
    super.key,
    required this.workOrderNumber,
    required this.photoCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 96,
                  width: 96,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 58,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Saved Successfully!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Work Order: $workOrderNumber'),
                const SizedBox(height: 8),
                Text('$photoCount files ready for upload'),
                const SizedBox(height: 24),
                const Text(
                  'This work order is saved locally as Pending Upload. After backend connection, it will upload automatically and PowerPoint will be generated.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                AppButton(
                  title: 'Create New Work Order',
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkOrderScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
