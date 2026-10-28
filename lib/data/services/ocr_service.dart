import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

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
      
      // Enhanced text analysis to extract product information
      final lines = text.split('\n');
      String? productName;
      String? brand;
      DateTime? expiryDate;
      String? batchNumber;
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;
        
        // Try to detect expiry date patterns (multiple formats)
        final dateMatch = _findDateMatch(trimmedLine);
        if (dateMatch != null) {
          expiryDate = _parseDate(dateMatch);
        }
        
        // Try to detect batch number patterns
        final batchMatch = _findBatchMatch(trimmedLine);
        if (batchMatch != null) {
          batchNumber = batchMatch;
        }
        
        // First substantial line might be product name (skip dates and batch numbers)
        if (productName == null && 
            trimmedLine.length > 3 && 
            trimmedLine.length < 100 &&
            !_isDateLine(trimmedLine) &&
            !_isBatchLine(trimmedLine) &&
            !_isPriceLine(trimmedLine)) {
          productName = trimmedLine;
        }
        
        // Try to detect brand (usually uppercase, short)
        if (brand == null && 
            trimmedLine.length > 2 && 
            trimmedLine.length < 20 &&
            trimmedLine == trimmedLine.toUpperCase() &&
            !_isDateLine(trimmedLine) &&
            !_isBatchLine(trimmedLine)) {
          brand = trimmedLine;
        }
      }
      
      // Combine brand and product name if both found
      String? displayName;
      if (brand != null && productName != null) {
        displayName = '$brand $productName';
      } else if (productName != null) {
        displayName = productName;
      } else if (brand != null) {
        displayName = brand;
      }
      
      return {
        'productName': displayName,
        'brand': brand,
        'expiryDate': expiryDate,
        'batchNumber': batchNumber,
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

  String? _findDateMatch(String line) {
    // Multiple date format patterns
    final patterns = [
      // DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY
      RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})\b'),
      // YYYY/MM/DD, YYYY-MM-DD, YYYY.MM.DD
      RegExp(r'\b(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})\b'),
      // MM/DD/YYYY, MM-DD-YYYY
      RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b'),
      // With expiry keywords
      RegExp(r'(?:exp|expiry|exp date|best before|use by)[:\s]*(\d{1,2}[/.-]\d{1,2}[/.-]\d{2,4})', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        // Return the matched date portion
        for (int i = 1; i <= match.groupCount; i++) {
          final group = match.group(i);
          if (group != null && RegExp(r'\d').hasMatch(group)) {
            return match.group(0) ?? group;
          }
        }
        return match.group(0);
      }
    }
    return null;
  }

  String? _findBatchMatch(String line) {
    // Batch number patterns
    final patterns = [
      RegExp(r'(?:batch|lot|no|number)[:\s]*([A-Za-z0-9-]+)', caseSensitive: false),
      RegExp(r'\b([A-Z]{2,4}[-]?\d{4,10})\b'), // Pattern like ABC123456
      RegExp(r'\b(\d{6,12})\b'), // Pure numeric batch
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return match.group(1) ?? match.group(0);
      }
    }
    return null;
  }

  DateTime? _parseDate(String dateString) {
    try {
      // Clean the date string
      final cleanDate = dateString.replaceAll(RegExp(r'[^\d/.-]'), '');
      
      // Try different date formats using intl
      final formats = [
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'dd.MM.yyyy',
        'MM/dd/yyyy',
        'MM-dd-yyyy',
        'yyyy/MM/dd',
        'yyyy-MM-dd',
        'yyyy.MM.dd',
      ];
      
      for (final format in formats) {
        try {
          final date = DateFormat(format).parse(cleanDate);
          // Ensure date is reasonable (not too far in past or future)
          if (date.year > 2000 && date.year < 2100) {
            return date;
          }
        } catch (e) {
          continue;
        }
      }
      
      // Fallback to manual parsing
      final parts = cleanDate.split(RegExp(r'[/.-]'));
      if (parts.length == 3) {
        final num1 = int.tryParse(parts[0]);
        final num2 = int.tryParse(parts[1]);
        final num3 = int.tryParse(parts[2]);

        if (num1 != null && num2 != null && num3 != null) {
          // Try DD/MM/YYYY or MM/DD/YYYY
          if (num1 <= 31 && num2 <= 12 && num3 >= 2000) {
            return DateTime(num3, num2, num1);
          }
          // Try YYYY/MM/DD
          if (num1 >= 2000 && num2 <= 12 && num3 <= 31) {
            return DateTime(num1, num2, num3);
          }
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
    return _findDateMatch(line) != null;
  }

  bool _isBatchLine(String line) {
    return _findBatchMatch(line) != null;
  }

  bool _isPriceLine(String line) {
    final pricePattern = RegExp(r'\$\s*\d+\.?\d*|\d+\.?\d*\s*\$');
    return pricePattern.hasMatch(line);
  }

  void dispose() {
    _textRecognizer.close();
  }
}
