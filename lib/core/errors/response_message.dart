class ResponseMessage {
  static const String success = "Success";
  static const String noContent = "No content";
  static const String badRequest = "Bad request, try again later";
  static const String forbidden = "Forbidden request";
  static const String unauthorized = "User unauthorized, try again";
  static const String notFound = "Url not found, try again later";
  static const String internalServerError =
      "Something went wrong, try again later";

  // local errors
  static const String connectTimeout = "Connection timeout, try again later";
  static const String cancel = "Request was cancelled, try again later";
  static const String receiveTimeout = "Receive timeout, try again later";
  static const String sendTimeout = "Send timeout, try again later";
  static const String cacheError = "Cache error, try again later";
  static const String noInternetConnection =
      "Please check your internet connection";
  static const String defaultError = "Something went wrong, try again later";
}
