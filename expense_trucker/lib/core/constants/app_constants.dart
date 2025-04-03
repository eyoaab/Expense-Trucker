class AppConstants {
  // App Information
  static const String appName = 'Expense Tracker';
  static const String appVersion = '1.0.0';

  // Shared Preferences Keys
  static const String themeModeKey = 'theme_mode';
  static const String currencyCodeKey = 'currency_code';
  static const String firstTimeUserKey = 'first_time_user';

  // Default Values
  static const String defaultCurrencyCode = 'ETB';
  static const double defaultBudgetAmount = 1000.0;

  // Supported Currencies
  static const List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'INR',
    'CNY',
    'ETB'
  ];

  // Error Messages
  static const String defaultErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String internetConnectionError =
      'No internet connection. Please check your network settings.';
  static const String authFailedError =
      'Authentication failed. Please try again.';
  static const String userNotFoundError = 'No user found with this email.';
  static const String wrongPasswordError = 'Incorrect password.';
  static const String invalidEmailError = 'Please enter a valid email address.';
  static const String weakPasswordError =
      'Password should be at least 6 characters.';
  static const String emailInUseError = 'This email is already in use.';
  static const String noExpensesMessage =
      'No expenses found. Add your first expense.';
  static const String noBudgetsMessage =
      'No budgets found. Create your first budget.';
  static const String noCategoriesMessage = 'No categories found.';
  static const String unauthorizedMessage =
      'You are not authorized to perform this action.';

  // Collection Names
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';
  static const String budgetsCollection = 'budgets';
  static const String categoriesCollection = 'categories';

  // Storage Paths
  static const String receiptStoragePath = 'receipts';

  // Field Names
  static const String userIdField = 'userId';
  static const String emailField = 'email';
  static const String nameField = 'name';
  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';

  // Durations
  static const int splashDuration = 2000; // milliseconds
  static const int toastDuration = 3000; // milliseconds

  // Animation Durations
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 500; // milliseconds
  static const int longAnimationDuration = 800; // milliseconds

  // Pagination
  static const int defaultPageSize = 20;

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String monthYearFormat = 'MMMM yyyy';

  // Currency Symbols
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'INR': '₹',
    'CNY': '¥',
    'ETB': 'Br',
  };

  // Default Categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {
      'name': 'Food',
      'color': 0xFF4CAF50,
      'icon': 0xE56C, // restaurant icon
      'isDefault': true,
    },
    {
      'name': 'Transport',
      'color': 0xFF2196F3,
      'icon': 0xE57D, // directions_car icon
      'isDefault': true,
    },
    {
      'name': 'Entertainment',
      'color': 0xFFF44336,
      'icon': 0xE87C, // movie icon
      'isDefault': true,
    },
    {
      'name': 'Shopping',
      'color': 0xFF9C27B0,
      'icon': 0xE8CC, // shopping_cart icon
      'isDefault': true,
    },
    {
      'name': 'Bills',
      'color': 0xFFFF9800,
      'icon': 0xE85E, // receipt icon
      'isDefault': true,
    },
    {
      'name': 'Health',
      'color': 0xFF00BCD4,
      'icon': 0xE251, // favorite icon
      'isDefault': true,
    },
    {
      'name': 'Education',
      'color': 0xFF795548,
      'icon': 0xE80C, // school icon
      'isDefault': true,
    },
    {
      'name': 'Other',
      'color': 0xFF607D8B,
      'icon': 0xE53B, // more_horiz icon
      'isDefault': true,
    },
  ];
}
