import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Footer extends StatelessWidget {
  const Footer({required this.scrollController, super.key});

  final ScrollController scrollController;

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 14),
          Column(
            children: [
              GestureDetector(
                onTap: () => context.push("/"),
                child: Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Image.asset('logo.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.push("/"),
                child: Text(
                  'Board Vault',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              _Link(link: '/health', text: 'Health', colorScheme: colorScheme),
              _Link(
                link: '/privacy',
                text: 'Privacy',
                colorScheme: colorScheme,
              ),
              _Link(link: '/terms', text: 'Terms', colorScheme: colorScheme),
              _Link(link: '/faqs', text: 'FAQs', colorScheme: colorScheme),
              GestureDetector(
                onTap: scrollToTop,
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: colorScheme.onTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '© 2026 Board Vault - All rights reserved',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({
    required this.link,
    required this.text,
    required this.colorScheme,
  });

  final String link;
  final String text;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(link);
      },
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: colorScheme.primary),
      ),
    );
  }
}
