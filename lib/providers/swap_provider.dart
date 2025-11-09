import 'package:flutter/material.dart';
import '../models/swap_model.dart';
import '../services/swap_service.dart';

class SwapProvider with ChangeNotifier {
  final SwapService _swapService = SwapService();
  List<SwapModel> _userSwaps = [];
  List<SwapModel> _receivedSwaps = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SwapModel> get userSwaps => _userSwaps;
  List<SwapModel> get sentSwaps => _userSwaps; // Alias for compatibility
  List<SwapModel> get receivedSwaps => _receivedSwaps;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenToUserSwaps(String userId) {
    _swapService.getUserSwaps(userId).listen((swaps) {
      _userSwaps = swaps;
      notifyListeners();
    });
  }

  void listenToReceivedSwaps(String userId) {
    _swapService.getReceivedSwaps(userId).listen((swaps) {
      _receivedSwaps = swaps;
      notifyListeners();
    });
  }

  Future<bool> createSwapOffer(SwapModel swap) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _swapService.createSwapOffer(swap);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSwapStatus(String swapId, String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _swapService.updateSwapStatus(swapId, status);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Alias methods for better naming
  Future<bool> createSwap(SwapModel swap) => createSwapOffer(swap);
  
  Future<bool> acceptSwap(String swapId) => updateSwapStatus(swapId, 'accepted');
  
  Future<bool> rejectSwap(String swapId) => updateSwapStatus(swapId, 'rejected');

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
