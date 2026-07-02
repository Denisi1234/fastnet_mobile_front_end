# FASTNET Mobile App
Built with Flutter.

FASTNET is a premium, professional mobile application providing seamless real-time lodge booking, destination exploration, and interactive user settings.

## Getting Started

To run the FASTNET mobile front-end application locally, ensure you have the Flutter SDK configured.

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the application:
   ```bash
   flutter run
   ```

## Production Application Architecture

- **State Management**: Scalable architecture using the `provider` package (`BookingsProvider`, `WishlistProvider`, `UserSessionProvider`).
- **Interactive Map Engine**: Leverages high-performance maps via `flutter_map` and coordinates management using `latlong2`.
- **UI Customizations**: Dedicated design systems with custom typography (`AirbnbCereal` fonts) and consistent professional spacing.
