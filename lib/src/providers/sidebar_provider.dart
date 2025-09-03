import 'package:flutter/material.dart';

class SidebarProvider extends ChangeNotifier {
  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  void toggleSidebar() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void setExpanded(bool expanded) {
    _isExpanded = expanded;
    notifyListeners();
  }
}
