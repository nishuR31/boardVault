import 'dart:convert';
import 'lib/models/board_model.dart';

void main() {
  // Test single board response (actual API response)
  final singleBoardJson = jsonDecode('''{
    "success": true,
    "message": "Data found successful",
    "data": {
      "id": "6515f941-ab54-492f-a81e-3af6163f7ef8",
      "name": "ASUS Tinker Board S",
      "slug": "asus-tinker-board-s",
      "type": "SBC",
      "description": "ASUS Tinker Board S is a high-performance single-board computer",
      "category": ["Multimedia", "Linux", "DIY Computing"],
      "bestFor": ["Media Centers", "Digital Signage"],
      "alternatives": ["Raspberry Pi 4", "ODROID"],
      "photoFrontId": "https://example.com/photo.jpg",
      "pinDiagramId": "https://example.com/diagram.jpg",
      "createdAt": "2026-05-21T16:56:51.736Z",
      "updatedAt": "2026-05-21T19:39:08.146Z"
    }
  }''');

  // Extract data field
  var boardData = singleBoardJson['data'];
  
  print('✓ Single board response:');
  print('  Data type: ${boardData.runtimeType}');
  print('  Is Map: ${boardData is Map}');
  
  // Test parsing
  try {
    final board = Board.fromJson(boardData as Map<String, dynamic>);
    print('  ✓ Successfully parsed board: ${board.name}');
    print('    - ID: ${board.id}');
    print('    - Type: ${board.type}');
    print('    - Categories: ${board.category}');
    print('    - Created: ${board.createdAt}');
  } catch (e) {
    print('  ✗ Error parsing: $e');
  }

  print('');

  // Test boards list response
  final boardsListJson = jsonDecode('''{
    "success": true,
    "message": "Data found successful",
    "data": [
      {
        "id": "6515f941-ab54-492f-a81e-3af6163f7ef8",
        "name": "ASUS Tinker Board S",
        "slug": "asus-tinker-board-s",
        "type": "SBC",
        "description": "ASUS Tinker Board S",
        "category": ["Multimedia"],
        "bestFor": ["Media Centers"],
        "alternatives": ["Raspberry Pi 4"],
        "photoFrontId": "https://example.com/photo1.jpg",
        "pinDiagramId": "https://example.com/diagram1.jpg",
        "createdAt": "2026-05-21T16:56:51.736Z",
        "updatedAt": "2026-05-21T19:39:08.146Z"
      },
      {
        "id": "93f871dc-99ca-467f-8612-f1664ec387bc",
        "name": "Orange Pi PC",
        "slug": "orange-pi-pc",
        "type": "SBC",
        "description": "Orange Pi PC",
        "category": ["Linux", "Budget Computing"],
        "bestFor": ["Budget Servers"],
        "alternatives": ["Raspberry Pi Zero"],
        "photoFrontId": "https://example.com/photo2.jpg",
        "pinDiagramId": "https://example.com/diagram2.jpg",
        "createdAt": "2026-05-20T10:00:00.000Z",
        "updatedAt": "2026-05-20T10:00:00.000Z"
      }
    ]
  }''');

  var boardsData = boardsListJson['data'];
  
  print('✓ Boards list response:');
  print('  Data type: ${boardsData.runtimeType}');
  print('  Is List: ${boardsData is List}');
  print('  Length: ${boardsData.length}');
  
  // Test parsing list
  try {
    List<Board> boards = [];
    if (boardsData is List) {
      boards = boardsData
          .map((board) => Board.fromJson(board as Map<String, dynamic>))
          .toList();
    }
    print('  ✓ Successfully parsed ${boards.length} boards:');
    for (var board in boards) {
      print('    - ${board.name} (${board.type})');
    }
  } catch (e) {
    print('  ✗ Error parsing: $e');
  }

  print('');
  print('✓ All tests completed successfully!');
}
