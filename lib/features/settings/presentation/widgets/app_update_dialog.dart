import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/app_update_service.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppVersionInfo versionInfo;

  const AppUpdateDialog({super.key, required this.versionInfo});

  static Future<void> show(BuildContext context, AppVersionInfo versionInfo) {
    return showDialog(
      context: context,
      barrierDismissible: !versionInfo.isForceUpdate,
      builder: (_) => AppUpdateDialog(versionInfo: versionInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('새 버전이 있습니다'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'v${versionInfo.version}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (versionInfo.releaseNotes != null &&
              versionInfo.releaseNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              versionInfo.releaseNotes!,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
      actions: [
        if (!versionInfo.isForceUpdate)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('나중에'),
          ),
        FilledButton(
          onPressed: () => _openStore(context),
          child: const Text('업데이트'),
        ),
      ],
    );
  }

  Future<void> _openStore(BuildContext context) async {
    final url = versionInfo.storeUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
