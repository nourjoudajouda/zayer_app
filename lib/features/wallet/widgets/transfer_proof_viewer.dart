import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';

bool transferProofUrlLooksLikeImage(String url) {
  final lower = url.toLowerCase();
  if (lower.endsWith('.pdf')) return false;
  return lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
}

bool transferProofUrlLooksLikePdf(String url) {
  return url.toLowerCase().endsWith('.pdf');
}

Future<void> openTransferProofExternally(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return;
  final mode = uri.scheme == 'http' || uri.scheme == 'https'
      ? LaunchMode.externalApplication
      : LaunchMode.platformDefault;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: mode);
  }
}

Future<void> copyTransferProofLink(BuildContext context, String url) async {
  await Clipboard.setData(ClipboardData(text: url));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Link copied')),
  );
}

/// Full-screen pinch/zoom for network images.
Future<void> showTransferProofImageViewer(
  BuildContext context,
  String imageUrl,
) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (ctx) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            title: const Text('Transfer proof'),
            actions: [
              IconButton(
                tooltip: 'Open externally',
                icon: const Icon(Icons.open_in_new),
                onPressed: () => openTransferProofExternally(imageUrl),
              ),
            ],
          ),
          body: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Colors.white54),
                ),
                errorWidget: (_, __, ___) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load preview',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => openTransferProofExternally(imageUrl),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open externally'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// PDF or unknown file type: explain + open in external app / browser.
Future<void> showTransferProofDocumentSheet(
  BuildContext context,
  String url,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppConfig.cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Transfer proof',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This file opens in your browser or PDF app. You can also copy the link to save or share it.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: AppConfig.subtitleColor,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await openTransferProofExternally(url);
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open or download'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await copyTransferProofLink(context, url);
              },
              icon: const Icon(Icons.link),
              label: const Text('Copy link'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Routes to image viewer or document sheet.
Future<void> viewTransferProof(BuildContext context, String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  if (transferProofUrlLooksLikePdf(trimmed)) {
    await showTransferProofDocumentSheet(context, trimmed);
  } else if (transferProofUrlLooksLikeImage(trimmed)) {
    await showTransferProofImageViewer(context, trimmed);
  } else {
    // Unknown extension: try fullscreen image first; user can open externally from error state.
    await showTransferProofImageViewer(context, trimmed);
  }
}
