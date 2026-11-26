enum AppLanguage { uz, ru, en }

class Translations {
  static final Map<AppLanguage, Map<String, String>> _localizedValues = {
    AppLanguage.uz: {
      'app_name': 'GameHub',
      'home': 'Asosiy',
      'catalog': 'Katalog',
      'favorites': 'Sevimlilar',
      'settings': 'Sozlamalar',
      'refresh': 'Yangilash',
      'back': 'Orqaga',
      'forward': 'Oldinga',
      'language': 'Til',
      'select_language': 'Ilova tilini tanlang',
      'url_placeholder': 'Sayt manzili (https://...)',
      'load_url': 'Ochish',
      'no_internet': 'Internet aloqasi yo‘q',
      'retry': 'Qayta urinish',
    },
    AppLanguage.ru: {
      'app_name': 'GameHub',
      'home': 'Главная',
      'catalog': 'Каталог',
      'favorites': 'Избранное',
      'settings': 'Настройки',
      'refresh': 'Обновить',
      'back': 'Назад',
      'forward': 'Вперёд',
      'language': 'Язык',
      'select_language': 'Выберите язык приложения',
      'url_placeholder': 'Адрес сайта (https://...)',
      'load_url': 'Открыть',
      'no_internet': 'Нет подключения к интернету',
      'retry': 'Повторить',
    },
    AppLanguage.en: {
      'app_name': 'GameHub',
      'home': 'Home',
      'catalog': 'Catalog',
      'favorites': 'Favorites',
      'settings': 'Settings',
      'refresh': 'Refresh',
      'back': 'Back',
      'forward': 'Forward',
      'language': 'Language',
      'select_language': 'Select application language',
      'url_placeholder': 'Website URL (https://...)',
      'load_url': 'Open',
      'no_internet': 'No internet connection',
      'retry': 'Retry',
    },
  };

  static String get(AppLanguage lang, String key) {
    return _localizedValues[lang]?[key] ??
        _localizedValues[AppLanguage.uz]?[key] ??
        key;
  }
}