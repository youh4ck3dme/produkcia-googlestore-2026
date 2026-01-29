import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_category.dart';

enum ExpenseSortOption {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc,
}

class ExpenseFilterCriteria {
  final ExpenseSortOption sortOption;
  final List<ExpenseCategory> selectedCategories;
  final DateTimeRange? dateRange;
  final RangeValues? amountRange;

  const ExpenseFilterCriteria({
    this.sortOption = ExpenseSortOption.dateDesc,
    this.selectedCategories = const [],
    this.dateRange,
    this.amountRange,
  });

  ExpenseFilterCriteria copyWith({
    ExpenseSortOption? sortOption,
    List<ExpenseCategory>? selectedCategories,
    DateTimeRange? dateRange,
    RangeValues? amountRange,
  }) {
    return ExpenseFilterCriteria(
      sortOption: sortOption ?? this.sortOption,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      dateRange: dateRange ?? this.dateRange,
      amountRange: amountRange ?? this.amountRange,
    );
  }
}

class ExpenseFilterSheet extends StatefulWidget {
  final ExpenseFilterCriteria initialCriteria;
  final Function(ExpenseFilterCriteria) onApply;

  const ExpenseFilterSheet({
    super.key,
    required this.initialCriteria,
    required this.onApply,
  });

  @override
  State<ExpenseFilterSheet> createState() => _ExpenseFilterSheetState();
}

class _ExpenseFilterSheetState extends State<ExpenseFilterSheet> {
  late ExpenseSortOption _sortOption;
  late List<ExpenseCategory> _selectedCategories;
  DateTimeRange? _dateRange;
  RangeValues _amountRange = const RangeValues(0, 500);

  @override
  void initState() {
    super.initState();
    _sortOption = widget.initialCriteria.sortOption;
    _selectedCategories = List.from(widget.initialCriteria.selectedCategories);
    _dateRange = widget.initialCriteria.dateRange;
    if (widget.initialCriteria.amountRange != null) {
      _amountRange = widget.initialCriteria.amountRange!;
    }
  }

  void _applyFilters() {
    widget.onApply(ExpenseFilterCriteria(
      sortOption: _sortOption,
      selectedCategories: _selectedCategories,
      dateRange: _dateRange,
      amountRange: _amountRange,
    ));
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _sortOption = ExpenseSortOption.dateDesc;
      _selectedCategories = [];
      _dateRange = null;
      _amountRange = const RangeValues(0, 500);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtrovať a Zoradiť',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Resetovať'),
              ),
            ],
          ),
          const Divider(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort Options
                  const Text('Zoradiť podľa',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSortChip('Najnovšie', ExpenseSortOption.dateDesc),
                      _buildSortChip('Najstaršie', ExpenseSortOption.dateAsc),
                      _buildSortChip(
                          'Najvyššia suma', ExpenseSortOption.amountDesc),
                      _buildSortChip(
                          'Najnižšia suma', ExpenseSortOption.amountAsc),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Date Range
                  const Text('Obdobie',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _dateRange,
                        locale: const Locale('sk', 'SK'),
                      );
                      if (picked != null) {
                        setState(() {
                          _dateRange = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            _dateRange == null
                                ? 'Všetky dátumy'
                                : '${DateFormat('dd.MM.yyyy').format(_dateRange!.start)} - ${DateFormat('dd.MM.yyyy').format(_dateRange!.end)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          if (_dateRange != null)
                            GestureDetector(
                              onTap: () => setState(() => _dateRange = null),
                              child: const Icon(Icons.close,
                                  size: 20, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Suma (€)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          '${_amountRange.start.round()} - ${_amountRange.end.round()} €'),
                    ],
                  ),
                  RangeSlider(
                    values: _amountRange,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    labels: RangeLabels(
                      '${_amountRange.start.round()}€',
                      '${_amountRange.end.round()}€',
                    ),
                    onChanged: (values) {
                      setState(() {
                        _amountRange = values;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Categories
                  const Text('Kategórie',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ExpenseCategory.values.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category.displayName),
                        selected: isSelected,
                        avatar: Icon(category.icon,
                            size: 16,
                            color: isSelected ? Colors.white : category.color),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        selectedColor: category.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 12,
                        ),
                        backgroundColor: category.color.withValues(alpha: 0.1),
                        checkmarkColor: Colors.white,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aplikovať filtre'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, ExpenseSortOption option) {
    final isSelected = _sortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortOption = option;
          });
        }
      },
    );
  }
}
