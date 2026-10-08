import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/board_model.dart';
import '../services/board_service.dart';
import './footer.dart';

class Boards extends StatefulWidget {
  const Boards({super.key});

  @override
  State<Boards> createState() => _BoardsState();
}

class _BoardsState extends State<Boards> {
  late BoardService boardService;
  late Future<List<Board>> _boardsFuture;
  late ScrollController _scrollController;

  List<Board> _allBoards = [];
  List<Board> _filteredBoards = [];
  String _searchQuery = '';
  String _selectedType = ''; // '' (All), 'SBC', 'MC'
  String _selectedCategory = ''; // '' for all
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _quickCategories = [
    'All',
    'Linux',
    'IoT',
    'Microcontroller',
    'Robotics',
    'AI',
    'Beginner',
    'Low Power',
    'High Speed',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    boardService = BoardService();
    _loadBoards();
  }

  void _loadBoards({bool forceRefresh = false}) {
    setState(() => _isLoading = true);
    _boardsFuture = boardService.fetchBoards(forceRefresh: forceRefresh).then((boards) {
      if (mounted) {
        setState(() {
          _allBoards = boards;
          _isLoading = false;
        });
        _applyFilters();
      }
      return boards;
    }).catchError((error) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      throw error;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Board> filtered = List.from(_allBoards);

    // Filter by type
    if (_selectedType.isNotEmpty) {
      filtered = filtered.where((b) => b.type.toUpperCase() == _selectedType.toUpperCase()).toList();
    }

    // Filter by category
    if (_selectedCategory.isNotEmpty && _selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase();
      filtered = filtered.where((b) => b.category.any((c) => c.toLowerCase().contains(cat))).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      filtered = filtered.where((b) {
        final inName = b.name.toLowerCase().contains(query);
        final inDesc = b.description.toLowerCase().contains(query);
        final inCat = b.category.any((c) => c.toLowerCase().contains(query));
        final inBest = b.bestFor.any((bf) => bf.toLowerCase().contains(query));
        final inAlt = b.alternatives.any((alt) => alt.toLowerCase().contains(query));
        return inName || inDesc || inCat || inBest || inAlt;
      }).toList();
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
      _selectedCategory = '';
      _filteredBoards = _allBoards;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final sbcCount = _allBoards.where((b) => b.type == 'SBC').length;
    final mcCount = _allBoards.where((b) => b.type == 'MC').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.developer_board_rounded, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Board Vault',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sync / Refresh Boards',
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : () => _loadBoards(forceRefresh: true),
          ),
          IconButton(
            tooltip: 'About Board Vault',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => context.push('/about'),
          ),
        ],
        elevation: 1,
      ),
      body: FutureBuilder<List<Board>>(
        future: _boardsFuture,
        builder: (context, snapshot) {
          // Loading initial state
          if (snapshot.connectionState == ConnectionState.waiting && _allBoards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading hardware catalog...',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final isOffline = boardService.isOfflineMode;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Top Status & Search Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mode status badge (Live vs Offline Curated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isOffline
                              ? colorScheme.tertiaryContainer.withOpacity(0.5)
                              : colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isOffline
                                ? colorScheme.tertiary.withOpacity(0.3)
                                : colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOffline ? Icons.offline_bolt_rounded : Icons.cloud_done_rounded,
                              size: 18,
                              color: isOffline ? colorScheme.tertiary : colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isOffline
                                    ? 'Offline Curated Catalog — Ready with instant educational data'
                                    : 'Live Synchronized — Connected to Board Vault API',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOffline ? colorScheme.tertiary : colorScheme.primary,
                                ),
                              ),
                            ),
                            if (isOffline)
                              GestureDetector(
                                onTap: () => _loadBoards(forceRefresh: true),
                                child: Text(
                                  'Try Live',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.tertiary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Search input
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by board name, chip, category, or use case...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Segmented type selector: All | Single Board Computers | Microcontrollers
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _TypeFilterButton(
                              label: 'All Boards (${_allBoards.length})',
                              isSelected: _selectedType == '',
                              onTap: () {
                                setState(() => _selectedType = '');
                                _applyFilters();
                              },
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(width: 8),
                            _TypeFilterButton(
                              label: 'SBC ($sbcCount)',
                              icon: Icons.memory_rounded,
                              isSelected: _selectedType == 'SBC',
                              onTap: () {
                                setState(() => _selectedType = 'SBC');
                                _applyFilters();
                              },
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(width: 8),
                            _TypeFilterButton(
                              label: 'Microcontrollers ($mcCount)',
                              icon: Icons.developer_board_rounded,
                              isSelected: _selectedType == 'MC',
                              onTap: () {
                                setState(() => _selectedType = 'MC');
                                _applyFilters();
                              },
                              colorScheme: colorScheme,
                            ),
                            if (_selectedType.isNotEmpty ||
                                (_selectedCategory.isNotEmpty && _selectedCategory != 'All') ||
                                _searchQuery.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Reset all filters',
                                icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
                                onPressed: _resetFilters,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Category chip rail
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickCategories.map((category) {
                            final isSelected = (_selectedCategory == category) ||
                                (_selectedCategory.isEmpty && category == 'All');
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = category == 'All' ? '' : category;
                                  });
                                  _applyFilters();
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Results header count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${_filteredBoards.length} of ${_allBoards.length} boards',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            Text(
                              'Search: "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Boards List or Empty State
              if (_filteredBoards.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'No matching boards found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try clearing search keywords or switching filters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _resetFilters,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Reset Filters'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final board = _filteredBoards[index];
                        return _BoardCard(
                          board: board,
                          onTap: () => context.push('/board/${board.id}'),
                        );
                      },
                      childCount: _filteredBoards.length,
                    ),
                  ),
                ),

              // Bottom Footer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Footer(scrollController: _scrollController),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colorScheme,
  });

  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
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
    final isSBC = board.type.toUpperCase() == 'SBC';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Board Thumbnail or Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 95,
                  height: 95,
                  child: _buildThumbnail(board.photoFrontId, isSBC, colorScheme),
                ),
              ),
              const SizedBox(width: 14),

              // Board Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Tag & Category Pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSBC
                                ? colorScheme.primary.withOpacity(0.12)
                                : colorScheme.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSBC ? 'SBC' : 'MICROCONTROLLER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: isSBC ? colorScheme.primary : colorScheme.secondary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          isSBC ? Icons.memory_rounded : Icons.developer_board_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      board.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
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
                        height: 1.4,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Categories & Best-for preview
                    if (board.category.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: board.category.take(3).map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imageUrl, bool isSBC, ColorScheme colorScheme) {
    if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackThumbnail(isSBC, colorScheme),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }
    return _fallbackThumbnail(isSBC, colorScheme);
  }

  Widget _fallbackThumbnail(bool isSBC, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: isSBC
            ? colorScheme.primary.withOpacity(0.08)
            : colorScheme.secondary.withOpacity(0.08),
      ),
      child: Center(
        child: Icon(
          isSBC ? Icons.memory_rounded : Icons.developer_board_rounded,
          size: 40,
          color: isSBC ? colorScheme.primary : colorScheme.secondary,
        ),
      ),
    );
  }
}
