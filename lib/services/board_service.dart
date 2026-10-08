import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/app_env.dart';
import '../models/board_model.dart';
import '../data/fallback_boards.dart';

class BoardService {
  final String baseUrl;

  // Singleton in-memory cache
  static List<Board>? _cachedBoards;
  static bool _lastFetchWasOffline = false;

  BoardService({String? baseUrl}) : baseUrl = baseUrl ?? AppEnv.backendUrl;

  bool get isOfflineMode => _lastFetchWasOffline;

  Future<List<Board>> fetchBoards({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedBoards != null && _cachedBoards!.isNotEmpty) {
      return _cachedBoards!;
    }

    try {
      final url = Uri.parse('$baseUrl/api/v1/boards');
      debugPrint('[BoardService] Fetching boards from: $url');

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));

      debugPrint('[BoardService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        List<dynamic> boardsList = [];
        if (jsonData is Map && jsonData.containsKey('data')) {
          boardsList = jsonData['data'] is List ? jsonData['data'] : [];
        } else if (jsonData is List) {
          boardsList = jsonData;
        }

        if (boardsList.isNotEmpty) {
          final fetched = boardsList
              .map((board) => Board.fromJson(board as Map<String, dynamic>))
              .toList();

          _cachedBoards = fetched;
          _lastFetchWasOffline = false;
          debugPrint('[BoardService] Successfully fetched ${fetched.length} live boards');
          return fetched;
        }
      }
      debugPrint('[BoardService] Backend returned non-200 or empty, activating fallback');
    } catch (e) {
      debugPrint('[BoardService] Notice: Could not connect to remote backend ($e). Activating fallback boards.');
    }

    // Fallback to high quality offline curated dataset
    _lastFetchWasOffline = true;
    _cachedBoards = List<Board>.from(FallbackBoards.data);
    return _cachedBoards!;
  }

  Future<Board> fetchBoardById(String id) async {
    // Check in-memory cache first if already loaded
    if (_cachedBoards != null) {
      try {
        return _cachedBoards!.firstWhere(
          (b) => b.id == id || b.slug == id,
        );
      } catch (_) {
        // Not in cache, try network
      }
    }

    try {
      final url = Uri.parse('$baseUrl/api/v1/boards/$id');
      debugPrint('[BoardService] Fetching board from: $url');

      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        var boardData = jsonData is Map && jsonData.containsKey('data')
            ? jsonData['data']
            : jsonData;

        if (boardData is List && boardData.isNotEmpty) {
          boardData = boardData.first;
        }

        if (boardData is Map<String, dynamic>) {
          return Board.fromJson(boardData);
        }
      }
    } catch (e) {
      debugPrint('[BoardService] Error fetching board by id ($id): $e. Checking fallback data.');
    }

    // Try fallback dataset
    try {
      return FallbackBoards.data.firstWhere(
        (b) => b.id == id || b.slug == id,
      );
    } catch (_) {
      throw Exception('Board with identifier "$id" not found in live database or offline cache.');
    }
  }

  Future<Board> fetchBoardByName(String name) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/boards/name/$name');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        var boardData = jsonData is Map && jsonData.containsKey('data')
            ? jsonData['data']
            : jsonData;

        if (boardData is List && boardData.isNotEmpty) {
          boardData = boardData.first;
        }

        if (boardData is Map<String, dynamic>) {
          return Board.fromJson(boardData);
        }
      }
    } catch (e) {
      debugPrint('[BoardService] Error fetching board by name ($name): $e');
    }

    try {
      final lower = name.toLowerCase().trim();
      return FallbackBoards.data.firstWhere(
        (b) => b.name.toLowerCase() == lower || b.slug.toLowerCase() == lower,
      );
    } catch (_) {
      throw Exception('Board "$name" not found.');
    }
  }

  Future<List<Board>> searchBoards(String query) async {
    final allBoards = await fetchBoards();
    if (query.trim().isEmpty) return allBoards;

    final queryLower = query.toLowerCase().trim();
    return allBoards.where((board) {
      final matchName = board.name.toLowerCase().contains(queryLower);
      final matchDesc = board.description.toLowerCase().contains(queryLower);
      final matchCat = board.category.any((c) => c.toLowerCase().contains(queryLower));
      final matchBest = board.bestFor.any((b) => b.toLowerCase().contains(queryLower));
      final matchType = board.type.toLowerCase() == queryLower;
      return matchName || matchDesc || matchCat || matchBest || matchType;
    }).toList();
  }

  List<Board> filterByType(List<Board> boards, String type) {
    if (type.isEmpty) return boards;
    return boards.where((board) => board.type.toUpperCase() == type.toUpperCase()).toList();
  }

  List<Board> filterByCategory(List<Board> boards, String category) {
    if (category.isEmpty) return boards;
    final catLower = category.toLowerCase();
    return boards.where((board) => board.category.any((c) => c.toLowerCase() == catLower)).toList();
  }
}
