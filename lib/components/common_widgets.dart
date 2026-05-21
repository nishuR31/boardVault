import 'package:flutter/material.dart';

/// Loading indicator with optional message
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingIndicator({
    this.message,
    this.fullScreen = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!),
        ],
      ],
    );

    if (fullScreen) {
      return Scaffold(
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}

/// Error display widget
class ErrorDisplay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool fullScreen;

  const ErrorDisplay({
    required this.title,
    required this.message,
    this.onRetry,
    this.fullScreen = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return Scaffold(
        body: Center(child: content),
      );
    }

    return Center(child: content);
  }
}

/// Empty state display
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox,
    this.onAction,
    this.actionLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
