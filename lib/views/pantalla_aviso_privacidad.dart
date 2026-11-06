import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class AvisoPrivacidadScreen extends StatelessWidget {
  const AvisoPrivacidadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(l10n.privacyBody),
      ),
    );
  }
}
