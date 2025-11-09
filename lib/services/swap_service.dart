import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/swap_model.dart';

class SwapService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createSwapOffer(SwapModel swap) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference swapRef = _firestore.collection('swaps').doc();
        DocumentReference bookRef = _firestore.collection('books').doc(swap.bookId);

        transaction.set(swapRef, swap.toMap());
        transaction.update(bookRef, {'status': 'pending'});
      });
    } catch (e) {
      throw Exception('Failed to create swap offer: ${e.toString()}');
    }
  }

  Stream<List<SwapModel>> getUserSwaps(String userId) {
    return _firestore
        .collection('swaps')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SwapModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<SwapModel>> getReceivedSwaps(String userId) {
    return _firestore
        .collection('swaps')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SwapModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateSwapStatus(String swapId, String status) async {
    try {
      await _firestore.collection('swaps').doc(swapId).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update swap status: ${e.toString()}');
    }
  }
}
