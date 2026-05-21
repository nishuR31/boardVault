import 'package:http/http.dart' as http;
import 'dart:convert';
import '/models/board_model.dart';

class BoardService {
  final String baseUrl;

  BoardService({String? baseUrl})
      : baseUrl =
            baseUrl ?? String.fromEnvironment("BACKEND_URL", defaultValue: "");

  /// Fetch all boards
  Future<List<Board>> fetchBoards() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/boards');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['data'] is List) {
          return (jsonData['data'] as List)
              .map((board) => Board.fromJson(board as Map<String, dynamic>))
              .toList();
        }
        return [];
      }
      throw Exception('Failed to fetch boards: ${response.statusCode}');
    } catch (e) {
      print('Error fetching boards: $e');
      rethrow;
    }
  }

  /// Fetch a single board by ID
  Future<Board> fetchBoardById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/boards/$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Board.fromJson(jsonData['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch board: ${response.statusCode}');
    } catch (e) {
      print('Error fetching board by ID: $e');
      rethrow;
    }
  }

  /// Fetch a board by name/slug
  Future<Board> fetchBoardByName(String name) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/boards/name/$name');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Board.fromJson(jsonData['data'] as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch board: ${response.statusCode}');
    } catch (e) {
      print('Error fetching board by name: $e');
      rethrow;
    }
  }

  /// Search boards by query (filters locally)
  Future<List<Board>> searchBoards(String query) async {
    try {
      final allBoards = await fetchBoards();
      if (query.isEmpty) return allBoards;

      final queryLower = query.toLowerCase();
      return allBoards
          .where((board) =>
              board.name.toLowerCase().contains(queryLower) ||
              board.description.toLowerCase().contains(queryLower) ||
              board.category.any((cat) => cat.toLowerCase().contains(queryLower)))
          .toList();
    } catch (e) {
      print('Error searching boards: $e');
      rethrow;
    }
  }

  /// Filter boards by type
  List<Board> filterByType(List<Board> boards, String type) {
    if (type.isEmpty) return boards;
    return boards.where((board) => board.type == type).toList();
  }

  /// Filter boards by category
  List<Board> filterByCategory(List<Board> boards, String category) {
    if (category.isEmpty) return boards;
    return boards
        .where((board) => board.category.contains(category))
        .toList();
  }
}
