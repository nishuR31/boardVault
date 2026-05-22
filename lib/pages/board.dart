import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/board_model.dart';
import '../services/board_service.dart';

class BoardDetail extends StatefulWidget {
  final String boardId;

  const BoardDetail({required this.boardId, super.key});

  @override
  State<BoardDetail> createState() => _BoardDetailState();
}

class _BoardDetailState extends State<BoardDetail> {
  late BoardService boardService;
  late Future<Board> _boardFuture;

  @override
  void initState() {
    super.initState();
    boardService = BoardService();
    _boardFuture = boardService.fetchBoardById(widget.boardId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Board Details'), elevation: 2),
      body: FutureBuilder<Board>(
        future: _boardFuture,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading board details...'),
                ],
              ),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading board',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // No data
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.memory, size: 64, color: colorScheme.tertiary),
                  const SizedBox(height: 16),
                  const Text('Board not found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Data loaded
          final board = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header image
                _buildHeaderImage(board, colorScheme),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + type
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  board.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  board.slug,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(board.type),
                            backgroundColor: colorScheme.tertiary.withOpacity(
                              0.2,
                            ),
                            labelStyle: TextStyle(
                              color: colorScheme.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          board.description,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Categories
                      if (board.category.isNotEmpty) ...[
                        Text(
                          'Categories',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: board.category
                              .map((cat) => Chip(label: Text(cat)))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Best for
                      if (board.bestFor.isNotEmpty) ...[
                        Text(
                          'Best For',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: board.bestFor
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: colorScheme.tertiary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Alternatives
                      if (board.alternatives.isNotEmpty) ...[
                        Text(
                          'Alternative Boards',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: board.alternatives
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.arrow_right,
                                        size: 16,
                                        color: colorScheme.secondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(item)),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Metadata
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Info',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow('ID', board.id),
                            const SizedBox(height: 8),
                            _InfoRow('Type', board.type),
                            const SizedBox(height: 8),
                            _InfoRow('Created', _formatDate(board.createdAt)),
                            const SizedBox(height: 8),
                            _InfoRow('Updated', _formatDate(board.updatedAt)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Images
                      if (board.photoFrontId != null ||
                          board.pinDiagramId != null) ...[
                        Text(
                          'Images',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        if (board.photoFrontId != null) ...[
                          _ImageCard(
                            title: 'Front View',
                            imageUrl: board.photoFrontId!,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (board.pinDiagramId != null) ...[
                          _ImageCard(
                            title: 'Pin Diagram',
                            imageUrl: board.pinDiagramId!,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderImage(Board board, ColorScheme colorScheme) {
    if (board.photoFrontId == null || board.photoFrontId!.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        color: colorScheme.surfaceContainerHighest,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.memory, size: 64, color: colorScheme.tertiary),
            const SizedBox(height: 16),
            const Text('No image available'),
          ],
        ),
      );
    }

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Image.network(
        board.photoFrontId!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          return Container(
            color: colorScheme.surfaceContainerHighest,
            child: progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                const Text('Failed to load image'),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String title;
  final String imageUrl;

  const _ImageCard({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        const Text('Image not available'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
