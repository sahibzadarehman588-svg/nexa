import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

abstract class StorageServiceInterface {
  Future<String> uploadProductImage(String userId, String productId, File imageFile);
  Future<String> uploadReceiptImage(String userId, String expenseId, File imageFile);
  Future<String> uploadDocumentImage(String userId, String documentId, File imageFile);
  Future<void> deleteImage(String imageUrl);
  Future<String> getDownloadUrl(String path);
}

class StorageService implements StorageServiceInterface {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String> uploadProductImage(String userId, String productId, File imageFile) async {
    try {
      final path = 'users/$userId/products/$productId.jpg';
      final ref = _storage.ref().child(path);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  @override
  Future<String> uploadReceiptImage(String userId, String expenseId, File imageFile) async {
    try {
      final path = 'users/$userId/receipts/$expenseId.jpg';
      final ref = _storage.ref().child(path);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload receipt image: $e');
    }
  }

  @override
  Future<String> uploadDocumentImage(String userId, String documentId, File imageFile) async {
    try {
      final path = 'users/$userId/documents/$documentId.jpg';
      final ref = _storage.ref().child(path);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload document image: $e');
    }
  }

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  @override
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}
