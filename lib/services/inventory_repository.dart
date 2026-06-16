import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_creator_ai/models/fridge_item.dart';

class InventoryRepository {
  InventoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _inventory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('inventory');
  }

  Stream<List<FridgeItem>> watchItems(String userId) {
    return _inventory(userId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(FridgeItem.fromDoc).toList());
  }

  Future<void> addItem(String userId, FridgeItem item) async {
    // Use lowercased name as doc id to avoid duplicates.
    final docId = item.name.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    await _inventory(userId).doc(docId).set({
      ...item.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeItem(String userId, String itemName) async {
    final docId = itemName.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    await _inventory(userId).doc(docId).delete();
  }
}
