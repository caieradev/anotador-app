class AppConstants {
  static const appName = 'Anotador IA';
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://193.123.110.120',
  );
}
