class AppEnv {
  static final backendUrl = String.fromEnvironment(
    'BACKEND',
    defaultValue: 'http://localhost:3030',
  ).trim();
}
