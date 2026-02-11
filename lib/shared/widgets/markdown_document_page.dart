import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../l10n/generated/app_localizations.dart';
import '../utils/responsive_utils.dart';

class MarkdownDocumentPage extends StatefulWidget {
  final String title;
  final String assetPath;

  const MarkdownDocumentPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<MarkdownDocumentPage> createState() => _MarkdownDocumentPageState();
}

class _MarkdownDocumentPageState extends State<MarkdownDocumentPage> {
  late final Future<String> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = rootBundle.loadString(widget.assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title), scrolledUnderElevation: 0),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: FutureBuilder<String>(
          future: _contentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${l10n.commonError}: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                ),
              );
            }
            final data = snapshot.data ?? '';
            if (data.isEmpty) {
              return Center(
                child: Text(
                  l10n.commonError,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              );
            }
            return Scrollbar(
              child: Markdown(
                data: data,
                selectable: true,
                styleSheet: _buildStyleSheet(context, colorScheme),
                padding: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ),
    );
  }

  MarkdownStyleSheet _buildStyleSheet(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(height: 1.6, fontSize: 14, color: colorScheme.onSurface),
      h1: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      h2: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
      h3: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      listBullet: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: colorScheme.onSurface,
      ),
      tableBody: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      tableBorder: TableBorder.all(color: colorScheme.outlineVariant),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
    );
  }
}
