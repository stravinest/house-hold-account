import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/markdown_document_page.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MarkdownDocumentPage(
      title: l10n.settingsTerms,
      assetPath: 'docs/terms_of_service.md',
    );
  }
}
