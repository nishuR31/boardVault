import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/models/board_model.dart';
import '/services/board_service.dart';

class Boards extends StatefulWidget {
  const Boards({super.key});

  @override
  State<Boards> createState() => _BoardsState();
}

class _BoardsState extends State<Boards> {
  late BoardService boardService;
  late Future<List<Board>> _boardsFuture;
  List<Board> _allBoards = [];
  List<Board> _filteredBoards = [];
  String _searchQuery = '';
  String _selectedType = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    boardService = BoardService();
    _boardsFuture = boardService.fetchBoards().then((boards) {
      setState(() {
        _allBoards = boards;
        _filteredBoards = boards;
      });
      return boards;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Board> filtered = _allBoards;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (board) =>
                board.name.toLowerCase().contains(query) ||
                board.description.toLowerCase().contains(query),
          )
          .toList();
    }

    // Filter by type
    if (_selectedType.isNotEmpty) {
      filtered = filtered
          .where((board) => board.type == _selectedType)
          .toList();
    }

    setState(() {
      _filteredBoards = filtered;
    });
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedType = '';
      _filteredBoards = _allBoards;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Boards'), elevation: 2),
      body: FutureBuilder<List<Board>>(
        future: _boardsFuture,
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading boards...'),
                ],
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading boards',
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
                    onPressed: () {
                      setState(() {
                        _boardsFuture = boardService.fetchBoards().then((
                          boards,
                        ) {
                          _allBoards = boards;
                          _filteredBoards = boards;
                          return boards;
                        });
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // No data
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.memory, size: 64, color: colorScheme.tertiary),
                  const SizedBox(height: 16),
                  const Text('No boards found'),
                ],
              ),
            );
          }

          // Data loaded successfully
          return Column(
            children: [
              // Search and filter bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search boards...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Type filter and reset
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedType.isEmpty ? null : _selectedType,
                            hint: const Text('Filter by Type'),
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                value: '',
                                child: Text('All Types'),
                              ),
                              DropdownMenuItem(
                                value: 'SBC',
                                child: Text('SBC'),
                              ),
                              DropdownMenuItem(
                                value: 'MC',
                                child: Text('Microcontroller'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedType = value ?? '');
                              _applyFilters();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_searchQuery.isNotEmpty || _selectedType.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Reset filters',
                            onPressed: _resetFilters,
                          ),
                      ],
                    ),

                    // Results count
                    const SizedBox(height: 8),
                    Text(
                      'Found ${_filteredBoards.length} board${_filteredBoards.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Boards list
              Expanded(
                child: _filteredBoards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            const Text('No boards match your search'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: _filteredBoards.length,
                        itemBuilder: (context, index) {
                          return _BoardCard(
                            board: _filteredBoards[index],
                            onTap: () {
                              context.push(
                                '/board/${_filteredBoards[index].id}',
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final Board board;
  final VoidCallback onTap;

  const _BoardCard({required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: _buildImage(board.photoFrontId, colorScheme),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type chip
                    Chip(
                      label: Text(
                        board.type,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: colorScheme.tertiary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: colorScheme.tertiary,
                        fontSize: 11,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: 8),

                    // Name
                    Text(
                      board.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    Text(
                      board.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Categories
                    if (board.category.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: board.category.take(2).map((cat) {
                          return Chip(
                            label: Text(
                              cat,
                              style: const TextStyle(fontSize: 10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              // Icon
              Icon(
                board.type == 'SBC' ? Icons.memory : Icons.developer_board,
                color: colorScheme.tertiary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl, ColorScheme colorScheme) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image, color: colorScheme.onSurfaceVariant),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: progress == null
              ? child
              : const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }
}
