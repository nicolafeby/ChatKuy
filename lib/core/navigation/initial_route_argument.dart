import 'package:chatkuy/ui/update/update_screen.dart';
import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';

class InitialRouteArgument {
  InitialRouteArgument._();

  static VoiceCallArgument? voiceCall;
  static AppUpdateScreenArgument? appUpdate;

  static VoiceCallArgument? takeVoiceCall() {
    final argument = voiceCall;
    voiceCall = null;
    return argument;
  }

  static AppUpdateScreenArgument? takeAppUpdate() {
    final argument = appUpdate;
    appUpdate = null;
    return argument;
  }
}
