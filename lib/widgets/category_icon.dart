import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryIcon extends StatelessWidget {
  final Category category;

  const CategoryIcon({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: category.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            category.icon,
            color: category.iconColor,
            size: 30,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          category.title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
