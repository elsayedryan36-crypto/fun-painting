import 'package:flutter_bloc/flutter_bloc.dart';

import 'main_event.dart';
import 'main_state.dart';

class MainScreenBloc extends Bloc<MainScreenEvent, MainScreenState> {
  MainScreenBloc() : super(MainScreenState(0)) {
    on<ChangeTab>((event, emit) {
      emit(MainScreenState(event.index));
    });
  }
}
