import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../config/app_env.dart';
import '../models/board_model.dart';

class BoardService {
  final String baseUrl;

  BoardService({String? baseUrl}) : baseUrl = baseUrl ?? AppEnv.backendUrl;

  Future<List<Board>> fetchBoards() async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/boards');
      print('[BoardService] Fetching boards from: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print('[BoardService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('[BoardService] Response data type: ${jsonData.runtimeType}');

        List<dynamic> boardsList = [];
        if (jsonData is Map && jsonData.containsKey('data')) {
          boardsList = jsonData['data'] is List ? jsonData['data'] : [];
        } else if (jsonData is List) {
          boardsList = jsonData;
        }

        print('[BoardService] Found ${boardsList.length} boards');
        return boardsList
            .map((board) => Board.fromJson(board as Map<String, dynamic>))
            .toList();
      }
      throw Exception(
        'Failed to fetch boards: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Cannot connect to backend at $baseUrl: $e');
      }
      print('[BoardService] Error fetching boards: $e');
      rethrow;
    }
  }

  Future<Board> fetchBoardById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/boards/$id');
      print('[BoardService] Fetching board from: $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print('[BoardService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final boardData = jsonData is Map && jsonData.containsKey('data')
            ? jsonData['data']
            : jsonData;
        return Board.fromJson(boardData as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch board: ${response.statusCode}');
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Cannot connect to backend: $e');
      }
      print('[BoardService] Error fetching board: $e');
      rethrow;
    }
  }

  Future<Board> fetchBoardByName(String name) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/boards/name/$name');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final boardData = jsonData is Map && jsonData.containsKey('data')
            ? jsonData['data']
            : jsonData;
        return Board.fromJson(boardData as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch board: ${response.statusCode}');
    } catch (e) {
      print('[BoardService] Error fetching board by name: $e');
      rethrow;
    }
  }

  Future<List<Board>> searchBoards(String query) async {
    try {
      final allBoards = await fetchBoards();
      if (query.isEmpty) return allBoards;

      final queryLower = query.toLowerCase();
      return allBoards
          .where(
            (board) =>
                board.name.toLowerCase().contains(queryLower) ||
                board.description.toLowerCase().contains(queryLower) ||
                board.category.any(
                  (cat) => cat.toLowerCase().contains(queryLower),
                ),
          )
          .toList();
    } catch (e) {
      print('[BoardService] Error searching boards: $e');
      rethrow;
    }
  }

  List<Board> filterByType(List<Board> boards, String type) {
    if (type.isEmpty) return boards;
    return boards.where((board) => board.type == type).toList();
  }

  List<Board> filterByCategory(List<Board> boards, String category) {
    if (category.isEmpty) return boards;
    return boards.where((board) => board.category.contains(category)).toList();
  }
}
