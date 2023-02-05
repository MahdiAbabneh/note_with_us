import 'dart:core';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mahdeko/Layout/Home/cubit/states.dart';

class HomeCubit extends Cubit<HomeStates> {
  HomeCubit() : super(HomeInitialState());

  static HomeCubit get(context) => BlocProvider.of(context);


}

