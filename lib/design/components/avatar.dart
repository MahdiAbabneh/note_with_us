import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';

/// Soft backgrounds for the built-in emoji avatars; the same in light and
/// dark mode so a person's avatar always looks the same.
const List<Color> avatarColors = [
  Color(0xFFFFE2D6),
  Color(0xFFDDF4EA),
  Color(0xFFE2EDFF),
  Color(0xFFEDE7FF),
  Color(0xFFFFF2C9),
  Color(0xFFFFE2E6),
];

/// Builds the stored value for a built-in emoji avatar, e.g.
/// `emoji:🦊:2`. It lives in the profile's `image` field, so no picture
/// is ever uploaded.
String emojiAvatar(String emoji, int color) => 'emoji:$emoji:$color';

/// The emoji and background of an emoji avatar, or `null` for a URL.
(String, Color)? parseEmojiAvatar(String value) {
  if (!value.startsWith('emoji:')) return null;
  final parts = value.split(':');
  if (parts.length != 3) return null;
  final index = int.tryParse(parts[2]) ?? 0;
  return (parts[1], avatarColors[index % avatarColors.length]);
}

/// Circular profile picture with an initials fallback and optional ring.
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.url,
    required this.name,
    this.size = 44,
    this.ring = false,
  });

  final String url;
  final String name;
  final double size;

  /// Draws an accent ring, used for people in your circle.
  final bool ring;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fallback = Container(
      color: c.accentSoft,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: context.text.label.copyWith(
          color: c.accent,
          fontSize: size * 0.36,
        ),
      ),
    );
    final emoji = parseEmojiAvatar(url);
    final image = ClipOval(
      child: SizedBox.square(
        dimension: size,
        child: emoji != null
            ? Container(
                color: emoji.$2,
                alignment: Alignment.center,
                child: Text(
                  emoji.$1,
                  style: TextStyle(fontSize: size * 0.52, height: 1),
                ),
              )
            : url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                fadeInDuration: Motion.fast,
                placeholder: (_, _) => Container(color: c.surface),
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
    if (!ring) return image;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.accent, width: 2),
      ),
      child: image,
    );
  }
}
