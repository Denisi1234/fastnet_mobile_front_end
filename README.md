# FASTNET Mobile App
Built with Flutter. Talks to the **same Laravel backend as the web app**
(`https://api.fastnetstays.com/api` in production) — no mocks, no Supabase.

FASTNET is a premium, professional mobile application providing seamless real-time lodge booking, destination exploration, and interactive user settings.

## Backend contract (mirrors `web/`)

- Base URL comes from `--dart-define=BACKEND_API_URL=...` (same value as web
  `BACKEND_API_URL`), falling back to `--dart-define=IS_PRODUCTION=true`.
- Local dev defaults: Android emulator `http://10.0.2.2:8000/api`,
  iOS simulator / desktop / web `http://localhost:8000/api`.
- Booking flow parity with web: `POST /bookings/calculate` → `POST /bookings/lock`
  → `POST /bookings/create` → `POST /payments/checkout` (mobile money only —
  card is rejected, same as web) → `GET /payments/status/{code}` →
  `POST /receipts/generate`.
- Check-in/out is host-driven (`POST /bookings/{id}/check-in|check-out`);
  guests track status in My Bookings (same rows as web `/my-booking`).
- Live sync: explore re-queries on open + before search; Trips, Notifications
  (30s poll + pull-to-refresh), Wishlist sync from `/wishlist`. Same backend
  rows the web renders — no parallel store.

## Getting Started

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run against local backend (Laravel on `:8000`):
   ```bash
   # Android emulator
   flutter run
   # physical device on the same LAN (replace IP):
   flutter run --dart-define=BACKEND_API_URL=http://192.168.1.50:8000/api
   ```

3. Run against production API:
   ```bash
   flutter run -d chrome --dart-define=BACKEND_API_URL=https://api.fastnetstays.com/api
   ```

4. Release APK (production):
   ```bash
   flutter build apk --release \
     --dart-define=BACKEND_API_URL=https://api.fastnetstays.com/api \
     --dart-define=IS_PRODUCTION=true
   ```

## Test accounts (local dev seed)

- Guest: `guest@fastnetstays.com` / `Guest12345!`
- Host: `host@fastnetstays.com` / `Host12345!`

## Production Application Architecture

- **State Management**: Scalable architecture using the `provider` package (`BookingsProvider`, `WishlistProvider`, `UserSessionProvider`).
- **Interactive Map Engine**: Uses Mapbox for interactive lodge maps, routing, and location-based exploration.
- **UI Customizations**: Dedicated design systems with custom typography (`AirbnbCereal` fonts) and consistent professional spacing.
