import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BrandIcons {
  static IconData getIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('google')) return FontAwesomeIcons.google;
    if (name.contains('github')) return FontAwesomeIcons.github;
    if (name.contains('facebook')) return FontAwesomeIcons.facebook;
    if (name.contains('apple')) return FontAwesomeIcons.apple;
    if (name.contains('microsoft')) return FontAwesomeIcons.microsoft;
    if (name.contains('amazon')) return FontAwesomeIcons.amazon;
    if (name.contains('twitter') || name.contains('x.com')) return FontAwesomeIcons.xTwitter;
    if (name.contains('instagram')) return FontAwesomeIcons.instagram;
    if (name.contains('discord')) return FontAwesomeIcons.discord;
    if (name.contains('spotify')) return FontAwesomeIcons.spotify;
    if (name.contains('netflix')) return FontAwesomeIcons.play;
    if (name.contains('steam')) return FontAwesomeIcons.steam;
    if (name.contains('twitch')) return FontAwesomeIcons.twitch;
    if (name.contains('reddit')) return FontAwesomeIcons.reddit;
    if (name.contains('linkedin')) return FontAwesomeIcons.linkedin;
    if (name.contains('dropbox')) return FontAwesomeIcons.dropbox;
    if (name.contains('slack')) return FontAwesomeIcons.slack;

    return Icons.public_rounded; // Default globe icon
  }

  static Color getBrandColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('google')) return Colors.red;
    if (name.contains('github')) return Colors.black;
    if (name.contains('facebook')) return const Color(0xFF1877F2);
    if (name.contains('twitter') || name.contains('x.com')) return Colors.black;
    if (name.contains('microsoft')) return const Color(0xFF00A4EF);
    if (name.contains('discord')) return const Color(0xFF5865F2);
    if (name.contains('spotify')) return const Color(0xFF1DB954);

    return Colors.blue;
  }
}
