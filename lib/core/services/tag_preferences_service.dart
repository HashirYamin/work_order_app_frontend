import 'package:shared_preferences/shared_preferences.dart';

class TagPreferencesService {
  static const String _tagPositionKey = 'tag_position';
  static const String _tagSizeKey = 'tag_size';

  static const String defaultPosition = 'Bottom Right';
  static const String defaultSize = 'Medium';

  Future<String> getTagPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tagPositionKey) ?? defaultPosition;
  }

  Future<String> getTagSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tagSizeKey) ?? defaultSize;
  }

  Future<void> saveTagPosition(String position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tagPositionKey, position);
  }

  Future<void> saveTagSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tagSizeKey, size);
  }
}
