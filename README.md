# Job Management Workshop

A cross-platform job management application built with Flutter. This project demonstrates modern mobile development practices, including integration with Supabase for backend services and SQL database management. It supports Android, iOS, Web, Windows, macOS, and Linux.

## Features

- Staff management
- Job assignment and tracking
- Supabase backend integration
- Multi-platform support

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (latest stable)
- [Supabase](https://supabase.com/) account
- Android Studio (for emulator)
- Git

## Demo Accounts

Use the following staff demo accounts to log in and explore the app:

| Staff ID | Password   | Name        |
| -------- | ---------- | ----------- |
| 2501     | staff@2501 | Alice Tan   |
| 2502     | staff@2502 | Ben Lim     |
| 2503     | staff@2503 | Cheryl Ng   |
| 2504     | staff@2504 | David Lee   |
| 2505     | staff@2505 | Evelyn Wong |

> Note: Demo account data may be reset periodically. For full access, create your own Supabase account and configure credentials.

## Supabase SQL Setup

1. Create a new project in Supabase.
2. Go to the SQL editor in your Supabase dashboard.
3. Copy the contents of `supabase_setup.sql` from this repository.
4. Paste and run the SQL script to set up the required tables and roles.
5. Get your Supabase project URL and anon/public API key from Project Settings > API.
6. Add these credentials to your Flutter app (usually in `lib/config/` or via environment variables).

## Running the Project

### 1. Install Dependencies

```
flutter pub get
```

### 2. Configure Supabase Credentials

- Update your Supabase URL and API key in the configuration files (e.g., `lib/config/` or as specified in your codebase).

### 3. Run on Android Emulator

- Open Android Studio and start an emulator.
- Run:

```
flutter run
```

- Select your emulator when prompted.

### 4. Run on Other Platforms

- For web:

```
flutter run -d chrome
```

- For Windows:

```
flutter run -d windows
```

- For macOS:

```
flutter run -d macos
```

- For Linux:

```
flutter run -d linux
```

## Troubleshooting

- If you encounter build issues, run:

```
flutter clean
flutter pub get
```

- Ensure your Supabase credentials are correct.
- Check your internet connection and emulator settings.

## Useful Links

- [Flutter Documentation](https://docs.flutter.dev/)
- [Supabase Documentation](https://supabase.com/docs)

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
