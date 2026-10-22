import 'package:flutter_bloc/flutter_bloc.dart';

enum HomeTab { vault, generator, starred, settings }

/// The selected tab of the home screen.
class HomeTabCubit extends Cubit<HomeTab> {
  HomeTabCubit() : super(HomeTab.vault);

  /// False when [tab] is already selected.
  bool select(HomeTab tab) {
    if (tab == state) return false;
    emit(tab);
    return true;
  }
}
