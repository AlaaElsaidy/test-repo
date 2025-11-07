// import 'package:GPS/l10n/app_localizations.dart';
//
// import '../../main.dart';
// import '../errors/data_source_enum.dart';
// import '../errors/failure.dart';
// import '../errors/response_code.dart';
// import '../errors/response_message.dart';
//
// extension DataSourcextension on DataSource {
//
//   Failure getFailure() {
//     final context = navigatorKey!.currentState!.context;
//     switch (this) {
//       case DataSource.success:
//         return Failure(ResponseCode.success, AppLocalizations.of(context)!.success);
//       case DataSource.noContent:
//         return Failure(ResponseCode.noContent, AppLocalizations.of(context)!.noContent);
//       case DataSource.badRequest:
//         return Failure(ResponseCode.badRequest, AppLocalizations.of(context)!.badRequest);
//       case DataSource.forbidden:
//         return Failure(ResponseCode.forbidden, AppLocalizations.of(context)!.forbidden);
//       case DataSource.unauthorised:
//         return Failure(ResponseCode.unauthorised, AppLocalizations.of(context)!.unauthorised);
//       case DataSource.notFound:
//         return Failure(ResponseCode.notFound, AppLocalizations.of(context)!.notFound);
//       case DataSource.internetServerError:
//         return Failure(ResponseCode.internalServerError,
//             AppLocalizations.of(context)!.internalServerError);
//       case DataSource.connectTimeout:
//         return Failure(
//             ResponseCode.connectTimeout, AppLocalizations.of(context)!.connectTimeout);
//       case DataSource.connectionError:
//         return Failure(
//             ResponseCode.connectionError, AppLocalizations.of(context)!.connectionError);
//       case DataSource.cancel:
//         return Failure(ResponseCode.cancel, AppLocalizations.of(context)!.cancel);
//       case DataSource.receiveTimeout:
//         return Failure(
//             ResponseCode.receiveTimeout, AppLocalizations.of(context)!.receiveTimeout);
//       case DataSource.sendTimeout:
//         return Failure(ResponseCode.sendTimeout, AppLocalizations.of(context)!.sendTimeout);
//       case DataSource.cacheError:
//         return Failure(ResponseCode.cacheError, AppLocalizations.of(context)!.cacheError);
//       case DataSource.noInternetConnection:
//         return Failure(ResponseCode.noInternetConnection,
//             ResponseMessage.noInternetConnection);
//       case DataSource.defaultError:
//         return Failure(ResponseCode.defaultError, AppLocalizations.of(context)!.defaultError);
//     }
//   }
// }
