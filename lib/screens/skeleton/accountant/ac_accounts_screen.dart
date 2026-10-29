import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/screens/accountant/finance_live_screens.dart';

class AcAccountsScreen extends ConsumerWidget {
  const AcAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const AccountsLedgerScreen();
}
