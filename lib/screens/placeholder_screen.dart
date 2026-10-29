import 'package:flutter/material.dart';

import 'package:course_emis/widgets/insight_ui.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;

  const PlaceholderScreen({
    super.key,
    this.title = 'Coming Soon',
    this.message = 'This feature is under development',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InsightBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              InsightHeroCard(
                eyebrow: 'Product roadmap',
                title: title,
                subtitle: message,
                accent: Colors.orange,
                chips: const [
                  InsightStatChip(label: 'Status', value: 'In progress'),
                  InsightStatChip(label: 'Design', value: 'Prepared'),
                ],
              ),
              const SizedBox(height: 20),
              const InsightProcessDiagram(
                title: 'What happens next',
                subtitle:
                    'This screen already has a polished shell and is ready for feature logic.',
                accent: Colors.orange,
                steps: [
                  InsightFlowStep(
                    title: 'Define',
                    subtitle: 'Finalize the exact workflow and data model.',
                    icon: Icons.rule_folder_outlined,
                  ),
                  InsightFlowStep(
                    title: 'Build',
                    subtitle: 'Add forms, charts, tables, and actions.',
                    icon: Icons.design_services_outlined,
                  ),
                  InsightFlowStep(
                    title: 'Launch',
                    subtitle: 'Connect to providers and production data.',
                    icon: Icons.rocket_launch_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
