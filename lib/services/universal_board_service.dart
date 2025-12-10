import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:spdrivercalendar/models/universal_board.dart';

class UniversalBoardService {
  static List<UniversalBoard>? _cachedBoards;

  static Future<List<UniversalBoard>> loadBoards() async {
    if (_cachedBoards != null) {
      return _cachedBoards!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/universal_boards.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      final List<dynamic> boardsJson = jsonData['boards'] as List<dynamic>;
      _cachedBoards = boardsJson
          .map((boardJson) => UniversalBoard.fromJson(boardJson as Map<String, dynamic>))
          .toList();
      
      return _cachedBoards!;
    } catch (e) {
      return [];
    }
  }

  static Future<UniversalBoard?> getBoardByShift(String shift) async {
    final boards = await loadBoards();
    try {
      return boards.firstWhere((board) => board.shift == shift);
    } catch (e) {
      return null;
    }
  }
}

