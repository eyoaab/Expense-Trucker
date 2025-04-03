import 'package:intl/intl.dart';

class CurrencyUtils {
  static final Map<String, String> currencySymbols = {
    'ETB': 'Br',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF',
    'CNY': '¥',
    'INR': '₹',
    'BRL': 'R\$',
  };

  static final List<String> availableCurrencies = [
    'ETB',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'BRL'
  ];

  static String formatCurrency(double amount, String currencyCode) {
    final symbol = currencySymbols[currencyCode] ?? currencyCode;

    // Special handling for ETB
    if (currencyCode == 'ETB') {
      return '${NumberFormat('#,##0.00').format(amount)} $symbol';
    }

    try {
      return NumberFormat.currency(
        symbol: symbol,
        decimalDigits: 2,
      ).format(amount);
    } catch (e) {
      // Fallback formatting if the currency is not supported by intl
      return '$symbol ${NumberFormat('#,##0.00').format(amount)}';
    }
  }

  static Map<String, dynamic> getCurrencyInfo(String currencyCode) {
    final Map<String, Map<String, dynamic>> currencyInfo = {
      'ETB': {
        'name': 'Ethiopian Birr',
        'code': 'ETB',
        'symbol': 'Br',
        'country': 'Ethiopia',
        'info':
            'The Birr has been the currency of Ethiopia since 1893. The name "Birr" comes from the local word for silver. It is subdivided into 100 santim.'
      },
      'USD': {
        'name': 'US Dollar',
        'code': 'USD',
        'symbol': '\$',
        'country': 'United States',
        'info': 'The world\'s primary reserve currency.'
      },
      'EUR': {
        'name': 'Euro',
        'code': 'EUR',
        'symbol': '€',
        'country': 'Euro Zone',
        'info':
            'Official currency of 19 of the 27 member states of the European Union.'
      },
      'GBP': {
        'name': 'British Pound',
        'code': 'GBP',
        'symbol': '£',
        'country': 'United Kingdom',
        'info': 'The world\'s oldest currency still in use.'
      },
      'JPY': {
        'name': 'Japanese Yen',
        'code': 'JPY',
        'symbol': '¥',
        'country': 'Japan',
        'info': 'Third most traded currency in the foreign exchange market.'
      },
      'CAD': {
        'name': 'Canadian Dollar',
        'code': 'CAD',
        'symbol': 'C\$',
        'country': 'Canada',
        'info': 'The seventh-most traded currency in the world.'
      },
      'AUD': {
        'name': 'Australian Dollar',
        'code': 'AUD',
        'symbol': 'A\$',
        'country': 'Australia',
        'info': 'The fifth-most traded currency in the world.'
      },
      'CHF': {
        'name': 'Swiss Franc',
        'code': 'CHF',
        'symbol': 'CHF',
        'country': 'Switzerland',
        'info': 'A safe-haven currency.'
      },
      'CNY': {
        'name': 'Chinese Yuan',
        'code': 'CNY',
        'symbol': '¥',
        'country': 'China',
        'info': 'Official currency of the People\'s Republic of China.'
      },
      'INR': {
        'name': 'Indian Rupee',
        'code': 'INR',
        'symbol': '₹',
        'country': 'India',
        'info': 'The official currency of India.'
      },
      'BRL': {
        'name': 'Brazilian Real',
        'code': 'BRL',
        'symbol': 'R\$',
        'country': 'Brazil',
        'info': 'The official currency of Brazil.'
      }
    };

    // Default to currency code if not found in our info map
    return currencyInfo[currencyCode] ??
        {
          'name': currencyCode,
          'code': currencyCode,
          'symbol': currencySymbols[currencyCode] ?? currencyCode,
          'country': 'Multiple Countries',
          'info': 'No additional information available'
        };
  }
}
