import 'package:chatkuy/ui/chat/voice_call/voice_call_argument.dart';

class InitialRouteArgument {
  InitialRouteArgument._();

  static VoiceCallArgument? voiceCall;

  static VoiceCallArgument? takeVoiceCall() {
    final argument = voiceCall;
    voiceCall = null;
    return argument;
  }
}
