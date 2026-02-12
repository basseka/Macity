class EnvConfig {
  EnvConfig._();

  // Sirene API credentials (to be set via environment or secure storage)
  static String sireneConsumerKey = '';
  static String sireneConsumerSecret = '';

  static void init({
    String? sireneKey,
    String? sireneSecret,
  }) {
    if (sireneKey != null) sireneConsumerKey = sireneKey;
    if (sireneSecret != null) sireneConsumerSecret = sireneSecret;
  }
}
