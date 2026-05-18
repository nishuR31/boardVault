import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import './footer.dart';

class Maintainers extends StatefulWidget {
  const Maintainers({super.key});

  @override
  State<Maintainers> createState() => _MaintainersState();
}

class _MaintainersState extends State<Maintainers> {
  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Icon(Icons.group_outlined, size: 56, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Maintainers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'People who keep Board Vault running and improve content.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _PersonRow(
              name: 'Nishan',
              role: 'Builder & Developer',
              github: 'nishur31',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _PersonRow(
              name: 'Aman',
              role: 'Data aggregator and verifier',
              github: 'aman-kumar2006',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 12),
            _PersonRow(
              name: 'Aditya',
              role: 'Api tester',
              github: 'technical-aditya',
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 24),
            Footer(scrollController: scrollController),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.name,
    required this.role,
    required this.github,
    required this.colorScheme,
  });

  final String name;
  final String role;
  final String github;
  final ColorScheme colorScheme;

  Future<void> _openGitHub() async {
    final uri = Uri.parse('https://github.com/$github');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(child: Text(name.substring(0, 1).toUpperCase())),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _openGitHub,
                child: Text(
                  'GitHub: $github',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.tertiary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
