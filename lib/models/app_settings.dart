import 'package:flutter/material.dart';

enum AppLanguage { english, swahili, spanish }
enum AppCurrency { tzs, usd, eur, gbp }

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._internal();

  AppSettings._internal();

  AppLanguage _language = AppLanguage.english;
  AppCurrency _currency = AppCurrency.tzs;
  bool _isMobileShellMode = false;

  AppLanguage get language => _language;
  AppCurrency get currency => _currency;
  bool get isMobileShellMode => _isMobileShellMode;

  void setLanguage(AppLanguage lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }

  void setCurrency(AppCurrency cur) {
    if (_currency != cur) {
      _currency = cur;
      notifyListeners();
    }
  }

  void toggleMobileShellMode() {
    _isMobileShellMode = !_isMobileShellMode;
    notifyListeners();
  }

  // Conversion rates (Base is TZS)
  double get conversionRate {
    switch (_currency) {
      case AppCurrency.usd:
        return 1 / 2500;
      case AppCurrency.eur:
        return 1 / 2700;
      case AppCurrency.gbp:
        return 1 / 3100;
      case AppCurrency.tzs:
      default:
        return 1.0;
    }
  }

  String get currencySymbol {
    switch (_currency) {
      case AppCurrency.usd:
        return r'$';
      case AppCurrency.eur:
        return '€';
      case AppCurrency.gbp:
        return '£';
      case AppCurrency.tzs:
      default:
        return 'TSh';
    }
  }

  String formatPrice(int priceInTzs) {
    final double converted = priceInTzs * conversionRate;
    if (_currency == AppCurrency.tzs) {
      // TZS formatting: round to whole and show comma separators
      final int rounded = converted.round();
      final String formattedStr = rounded.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      return '$currencySymbol $formattedStr';
    } else {
      // Other currencies: show 2 decimal places
      return '$currencySymbol${converted.toStringAsFixed(2)}';
    }
  }

  // Translation lookups
  String translate(String key) {
    final translations = _localizedValues[_language];
    if (translations != null && translations.containsKey(key)) {
      return translations[key]!;
    }
    return key; // Fallback
  }

  static const Map<AppLanguage, Map<String, String>> _localizedValues = {
    AppLanguage.english: {
      'explore_title': 'Find your next stay',
      'explore_subtitle': 'Search lodges, private rooms, and apartments.',
      'where_to': 'Where to?',
      'search_destination': 'Search destination',
      'dates': 'Dates',
      'guests': 'Guests',
      'search_button': 'Search Lodges',
      'explore_tz': 'Explore Tanzania',
      'explore_tz_sub': 'Tap a city to find rooms instantly',
      'featured_lodges': 'Featured Lodges',
      'featured_lodges_sub': 'Top-rated stays near your location',
      'night': 'night',
      'nights': 'nights',
      'apply': 'Apply',
      'choose_dates': 'Choose Dates',
      'select_guests': 'Select Guests',
      'num_occupants': 'Number of occupants',
      'adults_kids_infants': 'Adults, kids or infants',
      'gold_member': 'Gold Member',
      'account_settings': 'Account Settings',
      'personal_info': 'Personal Information',
      'payments_payouts': 'Payments & Payouts',
      'notifications': 'Notifications',
      'hosting_booking': 'Hosting & Booking',
      'list_lodge': 'List your lodge',
      'support_help': 'Lodge Support & Help',
      'logout': 'Log Out',
      'my_bookings': 'My Bookings',
      'no_active_bookings': 'No active bookings',
      'reserved_appear_here': 'Your reserved rooms will appear here.',
      'code': 'Code',
      'dates_header': 'DATES',
      'total_amount': 'TOTAL AMOUNT',
      'confirm_book': 'Confirm and book',
      'trip_details': 'Your trip details',
      'guest_info': 'Guest information',
      'full_name': 'Full Name',
      'enter_guest_name': 'Enter guest full name',
      'phone_number': 'Phone Number',
      'payment_method': 'Payment method',
      'price_details': 'Price details',
      'service_fee': 'Service Fee',
      'total_tzs': 'Total Amount',
      'confirm_booking_btn': 'Confirm booking',
      'securing_booking': 'Securing your booking...',
      'booked_success': 'Lodge Booked Successfully!',
      'reservation_confirmed': 'Your room reservation has been confirmed.',
      'summary_header': 'RESERVATION SUMMARY',
      'booking_code': 'Booking Code',
      'lodge_name': 'Lodge Name',
      'location': 'Location',
      'payment_option': 'Payment Option',
      'go_home': 'Go Back to Home',
      'what_offers': 'What this place offers',
      'conditions_rules': 'Lodge Conditions & Rules',
      'checkin_guidelines': 'Check-in guidelines',
      'reserve': 'Reserve',
      'genius_member': 'Genius Level 2',
      'genius_sub': 'Genius Member • 10% Discount active',
      'filters': 'Filter Stays',
      'sort': 'Sort Stays',
      'clear_all': 'Clear all',
      'view_results': 'View results',
    },
    AppLanguage.swahili: {
      'explore_title': 'Tafuta malazi yako yajayo',
      'explore_subtitle': 'Tafuta nyumba za wageni, vyumba binafsi, na vyumba vya kupanga.',
      'where_to': 'Unaenda wapi?',
      'search_destination': 'Tafuta eneo',
      'dates': 'Tarehe',
      'guests': 'Wageni',
      'search_button': 'Tafuta Malazi',
      'explore_tz': 'Gundua Tanzania',
      'explore_tz_sub': 'Gusa mji kupata vyumba papo hapo',
      'featured_lodges': 'Malazi Yanayopendekezwa',
      'featured_lodges_sub': 'Malazi yenye ukadiriaji wa juu karibu nawe',
      'night': 'usiku',
      'nights': 'usiku',
      'apply': 'Weka',
      'choose_dates': 'Chagua Tarehe',
      'select_guests': 'Chagua Wageni',
      'num_occupants': 'Idadi ya wakaaji',
      'adults_kids_infants': 'Watu wazima, watoto au watoto wachanga',
      'gold_member': 'Mwanachama wa Dhahabu',
      'account_settings': 'Mipangilio ya Akaunti',
      'personal_info': 'Taarifa Binafsi',
      'payments_payouts': 'Malipo na Mapato',
      'notifications': 'Taarifa',
      'hosting_booking': 'Uenyeji na Uhifadhi',
      'list_lodge': 'Weka nyumba yako ya wageni',
      'support_help': 'Msaada na Usaidizi',
      'logout': 'Ondoka',
      'my_bookings': 'Uhifadhi Wangu',
      'no_active_bookings': 'Hakuna uhifadhi unaoendelea',
      'reserved_appear_here': 'Vyumba ulivyohifadhi vitaonekana hapa.',
      'code': 'Nambari',
      'dates_header': 'TAREHE',
      'total_amount': 'KIASI CHOTE',
      'confirm_book': 'Thibitisha na uhifadhi',
      'trip_details': 'Maelezo ya safari yako',
      'guest_info': 'Taarifa za mgeni',
      'full_name': 'Jina Kamili',
      'enter_guest_name': 'Ingiza jina kamili la mgeni',
      'phone_number': 'Namba ya Simu',
      'payment_method': 'Njia ya malipo',
      'price_details': 'Maelezo ya bei',
      'service_fee': 'Ada ya Huduma',
      'total_tzs': 'Kiasi Chote',
      'confirm_booking_btn': 'Thibitisha uhifadhi',
      'securing_booking': 'Tunasajili uhifadhi wako...',
      'booked_success': 'Umejipatia Malazi Kufanikiwa!',
      'reservation_confirmed': 'Uhifadhi wa chumba chako umethibitishwa.',
      'summary_header': 'MUHTASARI WA UHIFADHI',
      'booking_code': 'Nambari ya Uhifadhi',
      'lodge_name': 'Jina la Malazi',
      'location': 'Eneo',
      'payment_option': 'Njia ya Malipo',
      'go_home': 'Rudi Nyumbani',
      'what_offers': 'Kile eneo hili linatoa',
      'conditions_rules': 'Masharti na Sheria za Malazi',
      'checkin_guidelines': 'Miongozo ya kuingia',
      'reserve': 'Hifadhi',
      'genius_member': 'Genius Kiwango cha 2',
      'genius_sub': 'Mwanachama wa Genius • Punguzo la 10% lipo tayari',
      'filters': 'Chuja Malazi',
      'sort': 'Panga Malazi',
      'clear_all': 'Futa zote',
      'view_results': 'Onyesha matokeo',
    },
    AppLanguage.spanish: {
      'explore_title': 'Encuentra tu próxima estancia',
      'explore_subtitle': 'Busca pensiones, habitaciones privadas y apartamentos.',
      'where_to': '¿A dónde vas?',
      'search_destination': 'Buscar destino',
      'dates': 'Fechas',
      'guests': 'Huéspedes',
      'search_button': 'Buscar Alojamientos',
      'explore_tz': 'Explorar Tanzania',
      'explore_tz_sub': 'Toca una ciudad para buscar habitaciones al instante',
      'featured_lodges': 'Alojamientos Destacados',
      'featured_lodges_sub': 'Alojamientos mejor valorados cerca de ti',
      'night': 'noche',
      'nights': 'noches',
      'apply': 'Aplicar',
      'choose_dates': 'Elegir Fechas',
      'select_guests': 'Seleccionar Huéspedes',
      'num_occupants': 'Número de ocupantes',
      'adults_kids_infants': 'Adultos, niños o bebés',
      'gold_member': 'Miembro Oro',
      'account_settings': 'Configuración de Cuenta',
      'personal_info': 'Información Personal',
      'payments_payouts': 'Pagos y Cobros',
      'notifications': 'Notificaciones',
      'hosting_booking': 'Hospedar y Reservar',
      'list_lodge': 'Registra tu alojamiento',
      'support_help': 'Soporte y Ayuda',
      'logout': 'Cerrar Sesión',
      'my_bookings': 'Mis Reservas',
      'no_active_bookings': 'No hay reservas activas',
      'reserved_appear_here': 'Tus habitaciones reservadas aparecerán aquí.',
      'code': 'Código',
      'dates_header': 'FECHAS',
      'total_amount': 'IMPORTE TOTAL',
      'confirm_book': 'Confirmar y reservar',
      'trip_details': 'Detalles de tu viaje',
      'guest_info': 'Información del huésped',
      'full_name': 'Nombre Completo',
      'enter_guest_name': 'Ingresar nombre completo del huésped',
      'phone_number': 'Número de Teléfono',
      'payment_method': 'Método de pago',
      'price_details': 'Detalles del precio',
      'service_fee': 'Tarifa de Servicio',
      'total_tzs': 'Importe Total',
      'confirm_booking_btn': 'Confirmar reserva',
      'securing_booking': 'Asegurando su reserva...',
      'booked_success': '¡Alojamiento Reservado con Éxito!',
      'reservation_confirmed': 'La reserva de su habitación ha sido confirmada.',
      'summary_header': 'RESUMEN DE LA RESERVA',
      'booking_code': 'Código de Reserva',
      'lodge_name': 'Nombre del Alojamiento',
      'location': 'Ubicación',
      'payment_option': 'Opción de Pago',
      'go_home': 'Volver al Inicio',
      'what_offers': 'Lo que ofrece este lugar',
      'conditions_rules': 'Reglas y Condiciones del Alojamiento',
      'checkin_guidelines': 'Pautas de entrada',
      'reserve': 'Reservar',
      'genius_member': 'Genius Nivel 2',
      'genius_sub': 'Miembro Genius • 10% Descuento activo',
      'filters': 'Filtrar Alojamientos',
      'sort': 'Ordenar Alojamientos',
      'clear_all': 'Limpiar todo',
      'view_results': 'Ver resultados',
    }
  };
}
