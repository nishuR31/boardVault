class AppEnv {
  static const backendUrl = String.fromEnvironment(
    'BACKEND',
    defaultValue: 'http://localhost:3030',
  );
}