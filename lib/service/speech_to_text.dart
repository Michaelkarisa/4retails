import 'package:retails/models/sale_entry.dart';
import 'package:retails/models/product.dart';
import 'package:retails/service/data_service.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';

class RetailSpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<bool> init(Function(String) onStatus,Function(SpeechRecognitionError error) onError) async {
    return await _speech.initialize(
      onStatus: (status) => onStatus(status),
      onError: (error) => onError(error),
    );
  }

  void startListening(Function(String) onText) {
    if (_isListening) return;

    _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation
      ),
      localeId: 'en_US',
      onResult: (result) {
        if (result.finalResult) {
          onText(result.recognizedWords.toLowerCase());
        }
      },
    );

    _isListening = true;
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
  }

  bool get isAvailable => _speech.isAvailable;
}

class RetailSpeechParser {
  final DataService _dataService = DataService();

  // Common Kenyan products mapping (brand + product)
  final Map<String, String> kenyanProducts = {
    // Sugar brands
    'mumias sugar': 'sugar',
    'mumia sugar': 'sugar',
    'kabras sugar': 'sugar',
    'sony sugar': 'sugar',
    'nzoia sugar': 'sugar',
    'chemelil sugar': 'sugar',

    // Milk brands
    'brookside milk': 'milk',
    'tuzo milk': 'milk',
    'ilara milk': 'milk',
    'fresha milk': 'milk',
    'mala milk': 'milk',
    'daima milk': 'milk',

    // Cooking oil brands
    'elianto oil': 'cooking oil',
    'rina oil': 'cooking oil',
    'kimbo fat': 'cooking fat',
    'kasuku oil': 'cooking oil',
    'salad oil': 'cooking oil',
    'frymate oil': 'cooking oil',

    // Flour brands
    'exe flour': 'wheat flour',
    'soko flour': 'maize flour',
    'jogoo flour': 'maize flour',
    'pembe flour': 'wheat flour',
    'hostess flour': 'wheat flour',

    // Rice brands
    'pishori rice': 'rice',
    'basmati rice': 'rice',
    'mwea rice': 'rice',
    'komboka rice': 'rice',

    // Tea brands
    'ketepa tea': 'tea',
    'kericho gold tea': 'tea',
    'chai ya ketepa': 'tea',

    // Bread brands
    'festive bread': 'bread',
    'supa loaf': 'bread',
    'elliots bread': 'bread',

    // Sodas
    'coca cola': 'soda',
    'coke': 'soda',
    'fanta': 'soda',
    'sprite': 'soda',
    'stoney': 'soda',
    'novida': 'soda',

    // Water
    'keringet water': 'water',
    'dasani water': 'water',
    'aquamist water': 'water',

    // Common products (generic)
    'sugar': 'sugar',
    'milk': 'milk',
    'bread': 'bread',
    'flour': 'wheat flour',
    'rice': 'rice',
    'tea': 'tea',
    'salt': 'salt',
    'maize': 'maize',
    'beans': 'beans',
    'cooking oil': 'cooking oil',
    'cooking fat': 'cooking fat',
    'unga': 'wheat flour', // Swahili for flour
    'sukari': 'sugar', // Swahili for sugar
    'maziwa': 'milk', // Swahili for milk
    'mafuta': 'cooking oil', // Swahili for oil
    'mchuzi': 'cooking oil',
    'chumvi': 'salt', // Swahili for salt
    'mahindi': 'maize', // Swahili for maize
    'maharage': 'beans', // Swahili for beans
  };

  // Number mappings including fractions
  final Map<String, QuantityValue> numberWords = {
    // Fractions
    'quarter': QuantityValue(0.25, '¼'),
    'half': QuantityValue(0.5, '½'),
    'three quarters': QuantityValue(0.75, '¾'),

    // Swahili fractions
    'robo': QuantityValue(0.25, '¼'),
    'nusu': QuantityValue(0.5, '½'),
    'robo tatu': QuantityValue(0.75, '¾'),

    // Whole numbers
    'zero': QuantityValue(0, '0'),
    'one': QuantityValue(1, '1'),
    'two': QuantityValue(2, '2'),
    'three': QuantityValue(3, '3'),
    'four': QuantityValue(4, '4'),
    'five': QuantityValue(5, '5'),
    'six': QuantityValue(6, '6'),
    'seven': QuantityValue(7, '7'),
    'eight': QuantityValue(8, '8'),
    'nine': QuantityValue(9, '9'),
    'ten': QuantityValue(10, '10'),
    'eleven': QuantityValue(11, '11'),
    'twelve': QuantityValue(12, '12'),
    'thirteen': QuantityValue(13, '13'),
    'fourteen': QuantityValue(14, '14'),
    'fifteen': QuantityValue(15, '15'),
    'sixteen': QuantityValue(16, '16'),
    'seventeen': QuantityValue(17, '17'),
    'eighteen': QuantityValue(18, '18'),
    'nineteen': QuantityValue(19, '19'),
    'twenty': QuantityValue(20, '20'),
    'thirty': QuantityValue(30, '30'),
    'forty': QuantityValue(40, '40'),
    'fifty': QuantityValue(50, '50'),

    // Swahili numbers
    'moja': QuantityValue(1, '1'),
    'mbili': QuantityValue(2, '2'),
    'tatu': QuantityValue(3, '3'),
    'nne': QuantityValue(4, '4'),
    'tano': QuantityValue(5, '5'),
    'sita': QuantityValue(6, '6'),
    'saba': QuantityValue(7, '7'),
    'nane': QuantityValue(8, '8'),
    'tisa': QuantityValue(9, '9'),
    'kumi': QuantityValue(10, '10'),
  };

  // Unit variations
  final Map<String, String> unitAliases = {
    'kilogram': 'kg',
    'kilograms': 'kg',
    'kilo': 'kg',
    'kilos': 'kg',
    'kgs': 'kg',
    'kg': 'kg',

    'litre': 'litre',
    'litres': 'litre',
    'liter': 'litre',
    'liters': 'litre',
    'ltr': 'litre',

    'piece': 'piece',
    'pieces': 'piece',
    'pcs': 'piece',
    'pc': 'piece',

    'box': 'box',
    'boxes': 'box',

    'packet': 'packet',
    'packets': 'packet',
    'pack': 'packet',
    'packs': 'packet',

    'can': 'can',
    'cans': 'can',
    'tin': 'can',
    'tins': 'can',

    'bag': 'bag',
    'bags': 'bag',

    'bottle': 'bottle',
    'bottles': 'bottle',

    'sachet': 'sachet',
    'sachets': 'sachet',
  };

  /// Parse quantity from speech text
  QuantityValue parseQuantity(String text) {
    text = text.toLowerCase().trim();

    // Try to find numeric values first (e.g., "2.5", "0.25", "3")
    final numericRegex = RegExp(r'\b(\d+\.?\d*)\b');
    final numericMatch = numericRegex.firstMatch(text);
    if (numericMatch != null) {
      final value = double.tryParse(numericMatch.group(1)!) ?? 1.0;
      return QuantityValue(value, _formatQuantity(value));
    }

    // Check for compound fractions first (e.g., "three quarters")
    if (text.contains('three quarters') || text.contains('three quarter')) {
      return numberWords['three quarters']!;
    }

    // Try to find word numbers (check longer phrases first)
    final sortedNumberWords = numberWords.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (var entry in sortedNumberWords) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    // Check for compound numbers (e.g., "twenty five")
    final words = text.split(' ');
    double total = 0;
    for (var word in words) {
      if (numberWords.containsKey(word)) {
        total += numberWords[word]!.numericValue;
      }
    }

    if (total > 0) {
      return QuantityValue(total, _formatQuantity(total));
    }

    return QuantityValue(1, '1');
  }

  String _formatQuantity(double value) {
    if (value == 0.25) return '¼';
    if (value == 0.5) return '½';
    if (value == 0.75) return '¾';

    // If it's a whole number, show as int
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    // Otherwise show with decimal
    return value.toString();
  }

  /// Parse unit from speech text
  String? parseUnit(String text) {
    text = text.toLowerCase().trim();

    // Sort units by length (longer first) to match "kilograms" before "kg"
    final sortedUnits = unitAliases.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (var entry in sortedUnits) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Extract product name from speech text using existing products from database
  Future<ProductMatch?> parseProductName(String text) async {
    text = text.toLowerCase().trim();

    // Get all products from database
    final allProducts = _dataService.getAllProducts();

    // First, try to match against database products (longer names first)
    final sortedProducts = allProducts.toList()
      ..sort((a, b) => b.name.length.compareTo(a.name.length));

    for (var product in sortedProducts) {
      final productNameLower = product.name.toLowerCase();
      if (text.contains(productNameLower)) {
        return ProductMatch(
          productName: product.name,
          matchedText: productNameLower,
          isExisting: true,
        );
      }
    }

    // Second, try to match against Kenyan products mapping (longer phrases first)
    final sortedKenyanProducts = kenyanProducts.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (var entry in sortedKenyanProducts) {
      if (text.contains(entry.key)) {
        return ProductMatch(
          productName: entry.value,
          matchedText: entry.key,
          isExisting: false,
          brandName: entry.key,
        );
      }
    }

    // Third, extract potential product name by removing numbers and units
    String extractedName = text;

    // Remove "of" preposition
    extractedName = extractedName.replaceAll(' of ', ' ');

    // Remove numbers (digits)
    extractedName = extractedName.replaceAll(RegExp(r'\d+\.?\d*'), '');

    // Remove number words (sort by length to remove longer phrases first)
    final sortedNumberWords = numberWords.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (var word in sortedNumberWords) {
      extractedName = extractedName.replaceAll(' $word ', ' ');
      // Also remove if at start or end
      if (extractedName.startsWith('$word ')) {
        extractedName = extractedName.substring(word.length + 1);
      }
      if (extractedName.endsWith(' $word')) {
        extractedName = extractedName.substring(0, extractedName.length - word.length - 1);
      }
    }

    // Remove units (sort by length to remove longer phrases first)
    final sortedUnits = unitAliases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (var unit in sortedUnits) {
      extractedName = extractedName.replaceAll(' $unit ', ' ');
      // Also remove if at start or end
      if (extractedName.startsWith('$unit ')) {
        extractedName = extractedName.substring(unit.length + 1);
      }
      if (extractedName.endsWith(' $unit')) {
        extractedName = extractedName.substring(0, extractedName.length - unit.length - 1);
      }
      if (extractedName == unit) {
        extractedName = '';
      }
    }

    // Remove common filler words
    extractedName = extractedName
        .replaceAll(' of ', ' ')
        .replaceAll(' a ', ' ')
        .replaceAll(' the ', ' ');

    // Clean up multiple spaces and trim
    extractedName = extractedName
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    if (extractedName.isNotEmpty) {
      return ProductMatch(
        productName: extractedName,
        matchedText: extractedName,
        isExisting: false,
      );
    }

    return null;
  }

  /// Calculate price based on quantity and unit pricing tiers
  double calculatePrice({
    required double quantity,
    required String unit,
    required Map<String, dynamic> unitPrices,
  }) {
    final key = '$quantity-$unit';

    // Check for exact match first
    if (unitPrices.containsKey(key)) {
      return unitPrices[key]!;
    }

    // For whole number quantities, multiply base price
    if (quantity >= 1 && quantity % 1 == 0) {
      final baseKey = '1-$unit';
      if (unitPrices.containsKey(baseKey)) {
        return unitPrices[baseKey]! * quantity;
      }
    }

    // Fallback: calculate proportionally from 1 unit
    final oneUnitKey = '1-$unit';
    if (unitPrices.containsKey(oneUnitKey)) {
      return unitPrices[oneUnitKey]! * quantity;
    }

    // Last resort: try any available price for this unit
    for (var priceKey in unitPrices.keys) {
      if (priceKey.endsWith('-$unit')) {
        final parts = priceKey.split('-');
        final tierQty = double.tryParse(parts[0]) ?? 1.0;
        final tierPrice = unitPrices[priceKey]!;
        return (tierPrice / tierQty) * quantity;
      }
    }

    return 0.0;
  }

  /// Parse complete sale from speech text
  Future<ParsedSale?> parseSale(String text) async {
    try {
      text = text.toLowerCase().trim();

      print('=== PARSING ===');
      print('Input: "$text"');

      final quantityValue = parseQuantity(text);
      print('Quantity: ${quantityValue.displayValue} (numeric: ${quantityValue.numericValue})');

      final unit = parseUnit(text);
      print('Unit: ${unit ?? "none"}');

      final productMatch = await parseProductName(text);
      print('Product: ${productMatch?.productName ?? "none"}');
      if (productMatch?.brandName != null) {
        print('Brand: ${productMatch!.brandName}');
      }

      if (productMatch == null) {
        print('ERROR: No product found');
        return null;
      }

      // Find or create product
      final product = await _dataService.findOrCreateProduct(productMatch.productName);

      // Get unit price from product
      final unitPrices = product.unitPrice;

      // Determine the actual unit to use
      String finalUnit = unit ?? 'piece';

      // Calculate price
      final pricePerItem = calculatePrice(
        quantity: quantityValue.numericValue,
        unit: finalUnit,
        unitPrices: unitPrices,
      );

      print('Price: KES $pricePerItem');
      print('===============');

      if (pricePerItem == 0) {
        // No price found - needs to be configured
        return ParsedSale(
          productName: productMatch.productName,
          quantity: quantityValue.numericValue,
          quantityDisplay: quantityValue.displayValue,
          unit: finalUnit,
          pricePerItem: 0.0,
          needsPriceConfiguration: true,
          originalText: text,
          brandName: productMatch.brandName,
        );
      }

      return ParsedSale(
        productName: productMatch.productName,
        quantity: quantityValue.numericValue,
        quantityDisplay: quantityValue.displayValue,
        unit: finalUnit,
        pricePerItem: pricePerItem,
        needsPriceConfiguration: false,
        originalText: text,
        brandName: productMatch.brandName,
      );
    } catch (e) {
      print('Error parsing sale: $e');
      return null;
    }
  }

  /// Create sale entry from parsed sale
  Future<SaleEntry?> createSaleEntry(ParsedSale parsedSale) async {
    if (parsedSale.needsPriceConfiguration) {
      return null; // Needs price configuration first
    }

    final product = await _dataService.findOrCreateProduct(parsedSale.productName);

    // Quantity should be an integer for the sale entry
    final intQuantity = parsedSale.quantity;

    return SaleEntry(
      id: const Uuid().v4(),
      product: product,
      date: DateTime.now(),
      quantity: intQuantity,
      primaryUnit: parsedSale.unit,
      pricePerItem: parsedSale.pricePerItem,
      paid: true,
    );
  }

  /// Detect intent from speech (sale, query, etc.)
  SpeechIntent detectIntent(String text) {
    text = text.toLowerCase();

    // Check for query patterns
    if (text.contains('how much') ||
        text.contains('what is the price') ||
        text.contains('price of') ||
        text.contains('bei ya') ||
        text.contains('ngapi')) {
      return SpeechIntent.priceQuery;
    }

    // Check for stock query
    if (text.contains('how many') ||
        text.contains('stock') ||
        text.contains('available') ||
        text.contains('iko wapi')) {
      return SpeechIntent.stockQuery;
    }

    // Check for cancellation
    if (text.contains('cancel') ||
        text.contains('delete') ||
        text.contains('remove') ||
        text.contains('futa')) {
      return SpeechIntent.cancel;
    }

    // Check for confirmation
    if (text.contains('yes') ||
        text.contains('confirm') ||
        text.contains('ok') ||
        text.contains('ndio')) {
      return SpeechIntent.confirm;
    }

    // Default to sale
    return SpeechIntent.sale;
  }
}

enum SpeechIntent {
  sale,
  priceQuery,
  stockQuery,
  cancel,
  confirm,
}

class QuantityValue {
  final double numericValue;
  final String displayValue;

  QuantityValue(this.numericValue, this.displayValue);
}

class ProductMatch {
  final String productName;
  final String matchedText;
  final bool isExisting;
  final String? brandName;

  ProductMatch({
    required this.productName,
    required this.matchedText,
    required this.isExisting,
    this.brandName,
  });
}

class ParsedSale {
  final String productName;
  final double quantity;
  final String quantityDisplay; // e.g., "½", "2", "¼"
  final String unit;
  final double pricePerItem;
  final bool needsPriceConfiguration;
  final String originalText;
  final String? brandName;

  ParsedSale({
    required this.productName,
    required this.quantityDisplay,
    required this.quantity,
    required this.unit,
    required this.pricePerItem,
    required this.needsPriceConfiguration,
    required this.originalText,
    this.brandName,
  });

  double get total => quantity * pricePerItem;

  @override
  String toString() {
    final brand = brandName != null ? ' ($brandName)' : '';
    return '$quantityDisplay $unit of $productName$brand @ KES ${pricePerItem.toStringAsFixed(2)} = KES ${total.toStringAsFixed(2)}';
  }
}