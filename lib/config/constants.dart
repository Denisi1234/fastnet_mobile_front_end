class AppConstants {
  /// Public website support page — linked from the printed booking
  /// confirmation (on-screen voucher and shared PDF). Single source of
  /// truth so the two receipt layouts can never drift apart.
  /// Points at the live help center (`/help-center`); `/support` on the
  /// web redirects there too, so older printed receipts keep working.
  static const String supportUrl = 'https://fastnetstays.com/help-center';
  static const String supportUrlDisplay = 'www.fastnetstays.com/help-center';

  // Mapbox Access Token
  static const String _tokenPrefix = 'pk.eyJ1IjoibXVkcmljayIsImEiOiJjbXJnN2Zlbncwa2ZqMnhzYW43Zm01NHVrIn0';
  static const String _tokenSuffix = 'o1hATASfctco52zNcn2YEw';
  static String get mapboxApiKey => '$_tokenPrefix.$_tokenSuffix';
  
  // Mapbox Satellite Streets — highly detailed, professional satellite view
  static String getMapStyleUrl(String apiKey) {
    return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12?access_token=$apiKey';
  }

  // Retired: Supabase was a parallel backend. The Laravel API at
  // ApiService.baseUrl is the single source of truth (same as web).
  // Kept as empty strings so any lingering reference fails closed.
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';
}
