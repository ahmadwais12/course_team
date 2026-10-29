import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';

Future<bool> showSignOutDialog(BuildContext context, WidgetRef ref) async {
  final shouldSignOut = await showAdaptiveAlert<bool>(
    context: context,
    title: t(LNav.logout, ref),
    message: t(LCrud.signOutConfirm, ref),
    confirmLabel: t(L.confirm, ref),
    cancelLabel: t(L.cancel, ref),
    isDestructive: true,
  );

  return shouldSignOut ?? false;
}
