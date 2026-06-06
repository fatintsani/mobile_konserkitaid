import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/wishlist_service.dart';

class WishlistProvider with ChangeNotifier {
  final WishlistService _service = WishlistService();
  
  List<Event> _wishlists = [];
  bool _isLoading = false;
  String? _error;

  List<Event> get wishlists => _wishlists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchWishlists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wishlists = await _service.getWishlists();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isInWishlist(int eventId) {
    return _wishlists.any((event) => event.id == eventId);
  }

  Future<bool> toggleWishlist(int eventId) async {
    final isCurrentlyInWishlist = isInWishlist(eventId);
    bool success = false;

    if (isCurrentlyInWishlist) {
      // Optimistic update
      _wishlists.removeWhere((e) => e.id == eventId);
      notifyListeners();
      
      success = await _service.removeFromWishlist(eventId);
      if (!success) {
        // Revert on failure
        fetchWishlists(); 
      }
    } else {
      success = await _service.addToWishlist(eventId);
      if (success) {
        fetchWishlists();
      }
    }
    
    return success;
  }
}
