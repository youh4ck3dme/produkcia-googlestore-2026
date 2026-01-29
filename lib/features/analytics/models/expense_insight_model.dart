import 'package:flutter/material.dart';

enum InsightPriority { low, medium, high }

class ExpenseInsight {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double? potentialSavings;
  final InsightPriority priority;
  final DateTime createdAt;
  final String category; // e.g., 'optimization', 'anomaly', 'trend'

  ExpenseInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.potentialSavings,
    this.priority = InsightPriority.medium,
    required this.createdAt,
    required this.category,
  });

  factory ExpenseInsight.fromJson(Map<String, dynamic> json) {
    return ExpenseInsight(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: _parseIcon(json['icon'] as String),
      color: _parseColor(json['color'] as String),
      potentialSavings: (json['potentialSavings'] as num?)?.toDouble(),
      priority: _parsePriority(json['priority'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      category: json['category'] as String,
    );
  }

  static IconData _parseIcon(String iconName) {
    switch (iconName) {
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'savings':
        return Icons.savings_outlined;
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      default:
        return Icons.info_outline;
    }
  }

  static Color _parseColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static InsightPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return InsightPriority.high;
      case 'low':
        return InsightPriority.low;
      default:
        return InsightPriority.medium;
    }
  }
}
