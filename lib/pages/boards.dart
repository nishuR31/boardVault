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
  String _selectedCategory = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    boardService = BoardService();
    _boardsFuture = boardService.fetchBoards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBoards() {
    List<Board> filtered = _allBoards;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((board) =>
              board.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              board.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by type
    if (_selectedType.isNotEmpty) {
      filtered = boardService.filterByType(filtered, _selectedType);
    }

    // Filter by category
    if (_selectedCategory.isNotEmpty) {
      filtered = boardService.filterByCategory(filtered, _selectedCategory);
    }

    setState(() {
      _filteredBoards = filtered;
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterBoards();
  }

  void _updateTypeFilter(String? type) {
    setState(() {
      _selectedType = type ?? '';
    });
    _filterBoards();
  }

  void _updateCategoryFilter(String? category) {
    setState(() {
      _selectedCategory = category ?? '';
    });
    _filterBoards();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Microcontroller Boards'),
        elevation: 2,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Board>>(
        future: _boardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading boards',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.memory,
                    size: 64,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(height: 16),
                  const Text('No boards found'),
                ],
              ),
            );
          }

          // Initialize filtered boards on first load
          if (_allBoards.isEmpty) {
            _allBoards = snapshot.data!;
            _filteredBoards = snapshot.data!;
          }

          return Column(
            children: [
              // Search and filters section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: _updateSearch,
                      decoration: InputDecoration(
                        hintText: 'Search boards...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _updateSearch('');
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

                    // Filter chips
                    Row(
                      children: [
                        // Type filter
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedType.isEmpty ? null : _selectedType,
                            hint: const Text('Type'),
                            isExpanded: true,
                            items: ['', 'SBC', 'MC']
                                .map((type) => DropdownMenuItem(
                                      value: type.isEmpty ? '' : type,
                                      child: Text(type.isEmpty ? 'All Types' : type),
                                    ))
                                .toList(),
                            onChanged: _updateTypeFilter,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Reset filters button
                        if (_selectedType.isNotEmpty ||
                            _selectedCategory.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Reset filters',
                            onPressed: () {
                              _searchController.clear();
                              _updateSearch('');
                              _updateTypeFilter(null);
                              _updateCategoryFilter(null);
                            },
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredBoards.length,
                        itemBuilder: (context, index) {
                          return BoardCard(
                            board: _filteredBoards[index],
                            onTap: () {
                              context.push('/board/${_filteredBoards[index].id}');
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

/// Board card widget for the list view
class BoardCard extends StatefulWidget {
  final Board board;
  final VoidCallback onTap;

  const BoardCard({
    required this.board,
    required this.onTap,
    super.key,
  });

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with image and type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: widget.board.photoFrontId != null &&
                              widget.board.photoFrontId!.isNotEmpty
                          ? Image.network(
                              widget.board.photoFrontId!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                              loadingBuilder: (context, child, progress) {
                                return Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: progress == null
                                      ? child
                                      : const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                );
                              },
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.image,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type badge
                        Chip(
                          label: Text(
                            widget.board.type,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: colorScheme.tertiary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(height: 8),

                        // Name
                        Text(
                          widget.board.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),

                        // Description preview
                        Text(
                          widget.board.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Type icon
                  Icon(
                    widget.board.type == 'SBC'
                        ? Icons.memory
                        : Icons.developer_board,
                    color: colorScheme.tertiary,
                    size: 32,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Categories
              if (widget.board.category.isNotEmpty)
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.board.category
                      .take(3)
                      .map(
                        (cat) => Chip(
                          label: Text(
                            cat,
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 8),

              // View details button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.onTap,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
