// ignore_for_file: library_private_types_in_public_api

import 'package:mobx/mobx.dart';

part 'base_store.g.dart';

class BaseStore = _BaseStore with _$BaseStore;

abstract class _BaseStore with Store {
  @observable
  int selectedIndex = 0;

  @action
  void onTapItem(int index) {
    selectedIndex = index;
  }
}
