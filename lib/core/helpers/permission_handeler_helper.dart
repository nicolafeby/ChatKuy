import 'package:permission_handler/permission_handler.dart';

Future<T> handlePermission<T>({
  required Permission permission,
  required Function() onSuccess,
  required Function(PermissionStatus) onDenied,
}) async {
  final status = await permission.request();
  if (status.isGranted) {
    return onSuccess();
  } else {
    return onDenied(status);
  }
}
