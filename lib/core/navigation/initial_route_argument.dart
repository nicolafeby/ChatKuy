import 'package:chatkuy/ui/update/update_screen.dart';
import 'package:chatkuy/ui/chat/call/call_argument.dart';

class InitialRouteArgument {
  InitialRouteArgument._();

  static CallArgument? call;
  static AppUpdateScreenArgument? appUpdate;

  static CallArgument? takeCall() {
    final argument = call;
    call = null;
    return argument;
  }

  static AppUpdateScreenArgument? takeAppUpdate() {
    final argument = appUpdate;
    appUpdate = null;
    return argument;
  }
}
