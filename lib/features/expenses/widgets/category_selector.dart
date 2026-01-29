import 'package:flutter/material.dart';
import '../models/expense_category.dart';

/// Widget pre výber kategórie výdavku
/// Zobrazuje grid všetkých kategórií s ikonami a farbami
class CategorySelector extends StatefulWidget {
  final ExpenseCategory? selectedCategory;
  final ExpenseCategory? suggestedCategory;
  final int? suggestionConfidence;
  final Function(ExpenseCategory) onCategorySelected;

  const CategorySelector({
    super.key,
    this.selectedCategory,
    this.suggestedCategory,
    this.suggestionConfidence,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  String _searchQuery = '';
  String? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Suggestion Banner
        if (widget.suggestedCategory != null &&
            widget.suggestionConfidence != null)
          _buildSuggestionBanner(),

        const SizedBox(height: 16),

        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Hľadať kategóriu...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),

        const SizedBox(height: 16),

        // Group Filter Chips
        _buildGroupFilters(),

        const SizedBox(height: 16),

        // Categories Grid
        Expanded(
          child: _buildCategoriesGrid(),
        ),
      ],
    );
  }

  Widget _buildSuggestionBanner() {
    final category = widget.suggestedCategory!;
    final confidence = widget.suggestionConfidence!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            color: category.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI návrh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  category.displayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$confidence%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: category.color,
                ),
              ),
              Text(
                'istota',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.check_circle),
            color: category.color,
            onPressed: () {
              widget.onCategorySelected(category);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupFilters() {
    final groups = groupedCategories.keys.toList();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          FilterChip(
            label: const Text('Všetko'),
            selected: _selectedGroup == null,
            onSelected: (selected) {
              setState(() {
                _selectedGroup = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ...groups.map((group) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(group),
                selected: _selectedGroup == group,
                onSelected: (selected) {
                  setState(() {
                    _selectedGroup = selected ? group : null;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    List<ExpenseCategory> categories;

    if (_selectedGroup != null) {
      categories = groupedCategories[_selectedGroup]!;
    } else {
      categories = ExpenseCategory.values;
    }

    if (_searchQuery.isNotEmpty) {
      categories = categories.where((cat) {
        return cat.displayName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Žiadne kategórie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = widget.selectedCategory == category;
        final isSuggested = widget.suggestedCategory == category;

        return _buildCategoryCard(category, isSelected, isSuggested);
      },
    );
  }

  Widget _buildCategoryCard(
    ExpenseCategory category,
    bool isSelected,
    bool isSuggested,
  ) {
    return GestureDetector(
      onTap: () {
        widget.onCategorySelected(category);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color
              : category.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? category.color
                : isSuggested
                    ? category.color.withValues(alpha: 0.5)
                    : Colors.transparent,
            width: isSelected ? 3 : (isSuggested ? 2 : 1),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    size: 32,
                    color: isSelected ? Colors.white : category.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.displayName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : category.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSuggested && !isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: category.color,
                ),
              ),
            if (isSelected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
