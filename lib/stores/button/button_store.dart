import 'dart:async';
import 'package:chatkuy/core/widgets/textfield/button_widget.dart';
import 'package:mobx/mobx.dart';

part 'button_store.g.dart';

class ButtonStore = _ButtonStore with _$ButtonStore;

abstract class _ButtonStore with Store {
  Timer? _timer;

  @observable
  int remainingSeconds = 0;

  @observable
  bool isButtonClicked = false;

  @computed
  bool get isDisabled => remainingSeconds > 0;

  @action
  void startCountdown({
    required int value,
    CountdownUnit unit = CountdownUnit.seconds,
  }) {
    remainingSeconds = unit == CountdownUnit.minutes ? value * 60 : value;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds <= 1) {
        remainingSeconds = 0;
        _timer?.cancel();
      } else {
        remainingSeconds--;
      }
    });

    isButtonClicked = true;
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return remainingSeconds.toString();
  }

  void dispose() {
    _timer?.cancel();
  }
}
