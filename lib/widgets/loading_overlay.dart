import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    return Stack(
      children: [
        child,
        Container(
          color: Colors.black.withAlpha((255 * 0.3).round()),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
