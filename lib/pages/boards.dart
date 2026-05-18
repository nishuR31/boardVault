import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:go_router/go_router.dart';

class Boards extends StatefulWidget {
  const Boards({super.key});

  @override
  State<Boards> createState() => _BoardsState();
}

class _BoardsState extends State<Boards> {
  late String boardsUrl;
  late Future<List<dynamic>> boardsFuture;

  @override
  void initState() {
    super.initState();
    boardsUrl = Uri.parse(
      String.fromEnvironment("BACKEND_URL", defaultValue: "") +
          "/api/v1/boards",
    ).toString();
    boardsFuture = _fetchBoards();
  }

  Future<List<dynamic>> _fetchBoards() async {
    try {
      print('Fetching from: $boardsUrl');
      final response = await http.get(Uri.parse(boardsUrl));
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Handle API response structure { status, data: [] }
        if (jsonData['data'] is List) {
          return jsonData['data'];
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error fetching boards: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boards'), elevation: 2),
      body: FutureBuilder<List<dynamic>>(
        future: boardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No boards found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return BoardCard(board: snapshot.data![index]);
            },
          );
        },
      ),
    );
  }
}

class BoardCard extends StatefulWidget {
  const BoardCard({required this.board, super.key});

  final dynamic board;

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard> {
  late Timer imageTimer;
  late String currentImage;

  @override
  void initState() {
    super.initState();
    currentImage = widget.board.photoFront ?? '';
    imageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          currentImage = currentImage == widget.board.photoFront
              ? (widget.board.pinDiagram ?? widget.board.photoFront)
              : widget.board.photoFront;
        });
      }
    });
  }

  @override
  void dispose() {
    imageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and type row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: currentImage.isNotEmpty
                      ? Image.network(
                          currentImage,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image),
                        ),
                ),
                const Spacer(),
                Icon(
                  widget.board.type == "SBC"
                      ? Icons.memory
                      : Icons.developer_board,
                  color: colorScheme.tertiary,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Board name
            Text(
              widget.board.name ?? 'Unknown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Board description
            Text(
              widget.board.description ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            // Board type chip
            Chip(
              label: Text(widget.board.type ?? 'Unknown'),
              backgroundColor: colorScheme.tertiary.withOpacity(0.2),
              labelStyle: TextStyle(color: colorScheme.tertiary),
            ),
            const SizedBox(height: 12),
            // Visit button
            SizedBox(
              width: double.infinity,
              child: ToBoardButton(boardId: widget.board.id ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}

class ToBoardButton extends StatelessWidget {
  const ToBoardButton({required this.boardId, super.key});

  final String boardId;

  @override
  Widget build(BuildContext context) {
    final url = "/board/${boardId}";

    return ElevatedButton.icon(
      onPressed: () {
        context.push(url);
        // TODO: Implement navigation using go_router or similar
        // If using go_router, use: context.push(url);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Navigate to: $url')));
      },
      icon: const Icon(Icons.open_in_browser),
      label: const Text('Visit Board'),
    );
  }
}
