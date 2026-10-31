import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import 'primary_button.dart';

class AsyncContent<T> extends StatelessWidget {
  final bool isLoading;
  final String? errorMessage;
  final bool isEmpty;
  final String emptyMessage;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final VoidCallback? onRetry;
  final Widget Function() contentBuilder;

  const AsyncContent({
    super.key,
    required this.isLoading,
    this.errorMessage,
    this.isEmpty = false,
    this.emptyMessage = 'Belum ada data yang tersedia.',
    this.emptyActionLabel,
    this.onEmptyAction,
    this.onRetry,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Terjadi Kendala',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: 140,
                  child: PrimaryButton(
                    label: 'Coba Lagi',
                    onPressed: onRetry,
                    isSecondary: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (emptyActionLabel != null && onEmptyAction != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: 180,
                  child: PrimaryButton(
                    label: emptyActionLabel!,
                    onPressed: onEmptyAction,
                    isSecondary: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return contentBuilder();
  }
}
