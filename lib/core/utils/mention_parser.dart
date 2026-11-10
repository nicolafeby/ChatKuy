import 'package:chatkuy/data/models/user_model.dart';

abstract final class MentionParser {
  static String? activeQuery(String text, int cursor) {
    if (cursor <= 0 || cursor > text.length) return null;

    final start = text.lastIndexOf('@', cursor - 1);
    if (start == -1) return null;
    if (start > 0 && !RegExp(r'\s').hasMatch(text[start - 1])) return null;

    final query = text.substring(start + 1, cursor);
    return query.contains(RegExp(r'\s')) ? null : query;
  }

  static List<UserModel> mentionedUsers({
    required String? text,
    required Iterable<UserModel> users,
    String? excludedUserId,
  }) {
    final cleanText = text?.trim();
    if (cleanText == null || cleanText.isEmpty) return const [];

    final lowerText = cleanText.toLowerCase();
    final mentioned = <String, UserModel>{};
    for (final user in users) {
      if (user.id == excludedUserId) continue;
      final name = user.name.trim();
      if (name.isEmpty) continue;

      final username = user.username?.trim();
      final patterns = <String>[
        '@${name.toLowerCase()}',
        if (username?.isNotEmpty == true) '@${username!.toLowerCase()}',
      ];
      if (patterns.any(lowerText.contains)) mentioned[user.id] = user;
    }
    return mentioned.values.toList(growable: false);
  }
}
