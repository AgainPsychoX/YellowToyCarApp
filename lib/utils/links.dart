import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void launchOrCopyUrl(String link, [BuildContext? context]) async {
  try {
    bool success =
        await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    if (success) return;
  } catch (e) {/* Ignore */}

  await Clipboard.setData(ClipboardData(text: link));
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Link copied to the clipboard'),
    ));
  }
}

void launchOrCopyMail(String email, [BuildContext? context]) async {
  try {
    bool success = await launchUrl(Uri.parse('mailto:$email'),
        mode: LaunchMode.externalApplication);
    if (success) return;
  } catch (e) {/* Ignore */}

  await Clipboard.setData(ClipboardData(text: email));
  if (context != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('E-mail copied to the clipboard'),
    ));
  }
}
