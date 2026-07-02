import 'package:flutter/material.dart';
import 'package:airbnb_ui_clone/models/destination.dart';

class WishlistGroup {
  String name;
  List<Destination> items;
  bool isPrivate;

  WishlistGroup({
    required this.name,
    required this.items,
    this.isPrivate = true,
  });
}

class WishlistProvider extends ChangeNotifier {
  final List<WishlistGroup> _groups = [
    WishlistGroup(name: 'Favorites', items: [], isPrivate: true),
  ];

  List<WishlistGroup> get groups => _groups;

  List<Destination> get list {
    if (_groups.isEmpty) return [];
    return _groups[0].items;
  }

  void toggle(Destination destination) {
    if (_groups.isEmpty) {
      _groups.add(WishlistGroup(name: 'Favorites', items: [], isPrivate: true));
    }
    final defaultGroup = _groups[0];
    bool found = false;
    for (int i = 0; i < defaultGroup.items.length; i++) {
      if (defaultGroup.items[i].name == destination.name) {
        defaultGroup.items.removeAt(i);
        found = true;
        break;
      }
    }
    if (!found) {
      defaultGroup.items.add(destination);
    }
    notifyListeners();
  }

  bool contains(Destination destination) {
    for (var group in _groups) {
      for (var item in group.items) {
        if (item.name == destination.name) {
          return true;
        }
      }
    }
    return false;
  }

  void createGroup(String name, {bool isPrivate = true}) {
    _groups.add(WishlistGroup(name: name, items: [], isPrivate: isPrivate));
    notifyListeners();
  }

  void deleteGroup(int index) {
    if (index >= 0 && index < _groups.length) {
      _groups.removeAt(index);
      notifyListeners();
    }
  }

  void renameGroup(int index, String newName) {
    if (index >= 0 && index < _groups.length) {
      _groups[index].name = newName;
      notifyListeners();
    }
  }

  void toggleGroupPrivacy(int index) {
    if (index >= 0 && index < _groups.length) {
      _groups[index].isPrivate = !_groups[index].isPrivate;
      notifyListeners();
    }
  }
}
