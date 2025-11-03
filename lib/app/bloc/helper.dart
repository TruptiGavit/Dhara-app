import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

BindConfig<T> cubitConfig<T extends Cubit>(){

  print("cubitConfig: ");
  return BindConfig(
    notifier: (cubit) => cubit.stream,
    onDispose: (cubit) => cubit.close(),
  );
} 
