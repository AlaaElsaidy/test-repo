// import 'package:dio/dio.dart';

// import '../../l10n/app_localizations.dart';
// import '../../main.dart';
// import '../errors/failure.dart';
// import '../errors/response_code.dart';

// Failure DioErrorHandler(DioException error) {
//   final context = navigatorKey.currentState!.context;
//   final loc = AppLocalizations.of(context)!;

//   String _extractErrorMessage(dynamic data, String defaultMessage) {
//     if (data == null) return defaultMessage;

//     if (data is String && data.isNotEmpty) {
//       return data;
//     }
//     if (data is Map) {
//       if (data['message'] != null) return data['message'].toString();
//       if (data['error'] != null) return data['error'].toString();

//       if (data['errors'] is Map) {
//         final errorsMap = data['errors'] as Map;
//         for (final value in errorsMap.values) {
//           if (value is List && value.isNotEmpty) return value.first.toString();
//           if (value is String && value.isNotEmpty) return value;
//         }
//       }
//     }

//     return defaultMessage;
//   }

//   switch (error.type) {
//     case DioExceptionType.connectionTimeout:
//       return Failure(ResponseCode.connectTimeout, loc.connectTimeout);

//     case DioExceptionType.sendTimeout:
//       return Failure(ResponseCode.sendTimeout, loc.sendTimeout);

//     case DioExceptionType.receiveTimeout:
//       return Failure(ResponseCode.receiveTimeout, loc.receiveTimeout);

//     case DioExceptionType.badResponse:
//       final statusCode =
//           error.response?.statusCode ?? ResponseCode.defaultError;
//       final responseData = error.response?.data;
//       final serverMessage = _extractErrorMessage(
//         responseData,
//         error.response?.statusMessage ?? loc.badRequest,
//       );
//       return Failure(statusCode, serverMessage);

//     case DioExceptionType.cancel:
//       return Failure(ResponseCode.cancel, loc.cancel);

//     case DioExceptionType.unknown:
//       return Failure(
//         ResponseCode.noInternetConnection,
//         loc.noInternetConnection,
//       );

//     default:
//       return Failure(ResponseCode.defaultError, loc.defaultError);
//   }
// }
