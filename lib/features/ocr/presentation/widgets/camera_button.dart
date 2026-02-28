import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CameraButton extends StatelessWidget {
  const CameraButton({super.key, required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.camera_alt),
      color: enabled ? AppColors.secondary : AppColors.onSurfaceVariant,
      tooltip: 'Scan text from image',
    );
  }
}
