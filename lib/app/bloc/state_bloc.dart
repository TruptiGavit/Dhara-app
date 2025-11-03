import 'package:equatable/equatable.dart';

abstract class BlocState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BlocStateDefault extends BlocState {}

abstract class BlocStateLoaded extends BlocState {}

class BlocStateLoading extends BlocState {}

class BlocStateError extends BlocState {
  final String? message;
  final Exception? e;

  BlocStateError(this.message, {this.e});

  @override
  List<Object?> get props => [message, e];
}
