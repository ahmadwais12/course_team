import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/screens/accountant/finance_live_screens.dart';

class AcJournalEntriesScreen extends ConsumerWidget {
  const AcJournalEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const JournalEntriesScreen();
}
