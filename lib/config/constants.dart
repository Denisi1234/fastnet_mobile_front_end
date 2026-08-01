class AppConstants {
  // Mapbox Access Token
  static const String _tokenPrefix = 'pk.eyJ1IjoibXVkcmljayIsImEiOiJjbXJnN2Zlbncwa2ZqMnhzYW43Zm01NHVrIn0';
  static const String _tokenSuffix = 'o1hATASfctco52zNcn2YEw';
  static String get mapboxApiKey => '$_tokenPrefix.$_tokenSuffix';
  
  // Mapbox Satellite Streets — highly detailed, professional satellite view
  static String getMapStyleUrl(String apiKey) {
    return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12?access_token=$apiKey';
  }
}
