import 'package:flutter/material.dart';

class TourGuideStepData {
  const TourGuideStepData({
    required this.targetId,
    required this.title,
    required this.description,
    this.icon = Icons.explore_outlined,
  });

  final String targetId;
  final String title;
  final String description;
  final IconData icon;
}
