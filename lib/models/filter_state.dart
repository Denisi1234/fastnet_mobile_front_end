import 'package:flutter/material.dart';

enum SortOption { none, priceLowHigh, priceHighLow, bestRating, distance }

class FilterState extends ChangeNotifier {
  // Price range in TZS
  RangeValues priceRange;
  // Minimum rating (0.0 - 5.0)
  double minRating;
  // Free cancellation filter
  bool freeCancellation;
  // Selected amenities
  Set<String> amenities;
  // Selected neighborhoods/areas
  Set<String> neighborhoods;
  // Selected sort option
  SortOption sortOption;

  FilterState({
    this.priceRange = const RangeValues(0, 200000),
    this.minRating = 0.0,
    this.freeCancellation = false,
    Set<String>? amenities,
    Set<String>? neighborhoods,
    this.sortOption = SortOption.none,
  })  : amenities = amenities ?? <String>{},
        neighborhoods = neighborhoods ?? <String>{};

  // Update helpers
  void setPriceRange(RangeValues range) {
    priceRange = range;
    notifyListeners();
  }

  void setMinRating(double rating) {
    minRating = rating;
    notifyListeners();
  }

  void toggleFreeCancellation(bool value) {
    freeCancellation = value;
    notifyListeners();
  }

  void toggleAmenity(String amenity, bool selected) {
    if (selected) {
      amenities.add(amenity);
    } else {
      amenities.remove(amenity);
    }
    notifyListeners();
  }

  void toggleNeighborhood(String area, bool selected) {
    if (selected) {
      neighborhoods.add(area);
    } else {
      neighborhoods.remove(area);
    }
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    sortOption = option;
    notifyListeners();
  }
}
