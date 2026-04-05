import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.imageUrl = '',
  });
}
