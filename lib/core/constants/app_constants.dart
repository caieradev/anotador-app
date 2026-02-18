class AppConstants {
  static const appName = 'Anotador IA';
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://anotador-api.stratus.dev.br',
  );
}
