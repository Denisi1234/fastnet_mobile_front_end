class AppConstants {
  // Mapbox Access Token
  static const String _tokenPrefix = 'pk.eyJ1IjoibXVkcmljayIsImEiOiJjbXJnN2Zlbncwa2ZqMnhzYW43Zm01NHVrIn0';
  static const String _tokenSuffix = 'o1hATASfctco52zNcn2YEw';
  static String get mapboxApiKey => '$_tokenPrefix.$_tokenSuffix';
  
  // Mapbox Satellite Streets — highly detailed, professional satellite view
  static String getMapStyleUrl(String apiKey) {
    return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12?access_token=$apiKey';
  }

  // Supabase Configuration (supports --dart-define environment flags with live fallbacks)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://potpocgevsyoxxopwtaq.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvdHBvY2dldnN5b3h4b3B3dGFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU2NDk4NzIsImV4cCI6MjEwMTIyNTg3Mn0.7tV7zZ7fajLGd6lPePK-s7LUh2fTu5TQYoA4ckNBTWY',
  );
}
