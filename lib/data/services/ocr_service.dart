import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

abstract class OCRServiceInterface {
  Future<String> extractTextFromImage(File imageFile);
  Future<Map<String, dynamic>> extractProductInfo(File imageFile);
  Future<Map<String, dynamic>> extractReceiptInfo(File imageFile);
}

class OCRService implements OCRServiceInterface {
  final TextRecognizer _textRecognizer = TextRecognizer();

  @override
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> extractProductInfo(File imageFile) async {
    try {
      final text = await extractTextFromImage(imageFile);
      
      // Basic text analysis to extract product information
      final lines = text.split('\n');
      String? productName;
      DateTime? expiryDate;
      
      for (final line in lines) {
        // Try to detect expiry date patterns
        final datePattern = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})|(\d{4}[/-]\d{1,2}[/-]\d{1,2})');
        final dateMatch = datePattern.firstMatch(line);
        
        if (dateMatch != null) {
          final dateString = dateMatch.group(0);
          if (dateString != null) {
            expiryDate = _parseDate(dateString);
          }
        }
        
        // First substantial line might be product name
        if (productName == null && line.trim().length > 3 && !_isDateLine(line)) {
          productName = line.trim();
        }
      }
      
      return {
        'productName': productName,
        'expiryDate': expiryDate,
        'rawText': text,
      };
    } catch (e) {
      throw Exception('Product info extraction failed: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> extractReceiptInfo(File imageFile) async {
    try {
      final text = await extractTextFromImage(imageFile);
      
      // Basic text analysis to extract receipt information
      final lines = text.split('\n');
      String? merchantName;
      double? totalAmount;
      
      for (final line in lines) {
        // Try to detect merchant name (usually first substantial line)
        if (merchantName == null && line.trim().length > 3 && !_isDateLine(line)) {
          merchantName = line.trim();
        }
        
        // Try to detect total amount
        final amountPattern = RegExp(r'[$€£]?\s*\d+\.?\d*\s*(?:total|amount|sum)', caseSensitive: false);
        final amountMatch = amountPattern.firstMatch(line);
        
        if (amountMatch != null) {
          final amountString = amountMatch.group(0);
          if (amountString != null) {
            totalAmount = _parseAmount(amountString);
          }
        }
      }
      
      return {
        'merchantName': merchantName,
        'totalAmount': totalAmount,
        'rawText': text,
      };
    } catch (e) {
      throw Exception('Receipt info extraction failed: $e');
    }
  }

  DateTime? _parseDate(String dateString) {
    try {
      // This is a simplified approach - in production, use intl package
      final parts = dateString.split(RegExp(r'[/-]'));
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          // Handle 2-digit years
          final fullYear = year < 100 ? year + 2000 : year;
          return DateTime(fullYear, month, day);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  double? _parseAmount(String amountString) {
    try {
      // Extract numeric value from string
      final numericPattern = RegExp(r'\d+\.?\d*');
      final match = numericPattern.firstMatch(amountString);
      if (match != null) {
        return double.tryParse(match.group(0)!);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  bool _isDateLine(String line) {
    final datePattern = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})|(\d{4}[/-]\d{1,2}[/-]\d{1,2})');
    return datePattern.hasMatch(line);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
