# Expense Tracker App

A modern expense tracker application built with Flutter and Firebase, allowing users to manage their expenses, create budgets, and view spending analytics.

## Features

- User authentication (email/password)
- Expense tracking with categories and receipt attachments
- Budget management
- Category-based expense analytics
- Date range filtering

## Setup Instructions

### Prerequisites

- Flutter SDK (3.5.0 or higher)
- Firebase account

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   - Create a new Firebase project
   - Add Flutter apps (Android, iOS, Web) to your project
   - Download and add the configuration files
   - Enable Firestore, Authentication, and Storage

### Firestore Indexes

This application is designed to minimize Firestore index requirements. It only requires standard single-field indexes which are created by default.

The application performs filtering and sorting in memory for complex queries, avoiding the need for composite indexes. This approach works well for reasonable data volumes (up to a few thousand expenses per user).

For very large datasets, you may want to create additional indexes for better performance:

```
Collection: expenses
Fields indexed:
- userId (Ascending)
- date (Ascending)
```

### Running the App

```bash
flutter run
```

## Troubleshooting

### Firestore Index Errors

If you encounter any Firestore index errors, the application should still function correctly, but with potentially slower performance for queries with large result sets. The error message will typically contain a direct link to create the necessary index:

```
[cloud_firestore/failed-precondition] The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/expense-trucker-2c5ca/firestore/indexes?create_composite=...
```

You can click the link to create the index if you're experiencing performance issues. It may take a few minutes for the index to be created and become active.

### Common Issues

#### setState() Called During Build

If you encounter errors about `setState()` or `markNeedsBuild()` being called during build, it usually means a provider is updating state while the UI is rendering. The application has been designed to avoid this by:

1. Using `WidgetsBinding.instance.addPostFrameCallback` to defer initialization in StatefulWidgets
2. Using an `_isInitialized` flag to handle UI loading states
3. Using `Future.microtask` in providers to delay notifier updates

#### Budget Calculations

If budgets aren't updating correctly when expenses are added:

1. Make sure the expense category matches exactly with the budget category
2. Check that the expense date falls within the budget's month/year period
3. Verify that the expense was successfully saved to Firestore

#### Date Filtering Issues

The application uses in-memory filtering for date ranges to avoid complex Firestore indexes. If date filtering isn't working correctly:

1. Check that the timezone settings are consistent
2. Ensure date comparisons include time components (the app adds buffer minutes)
3. For large datasets, consider creating a composite index as described above

## Project Structure

- `lib/core`: Core utilities, constants, and widgets
- `lib/features`: Feature-based modules
  - `auth`: Authentication related screens and providers
  - `expenses`: Expense and budget management
- `assets`: Images, icons, and animations

## License

MIT
