class AppFormatter {
  static final RegExp usernameRegex = RegExp(r'[a-z0-9._]');
  static final RegExp nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'-]+$");
}
