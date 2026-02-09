import 'package:equatable/equatable.dart';
import 'package:speech_world/src/domain/entities/pricing_config_entity.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final UserEntity user;

  const UserLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

class UserLoadedWithConfig extends UserState {
  final UserEntity user;
  final PricingConfigEntity config;

  const UserLoadedWithConfig({required this.user, required this.config});

  @override
  List<Object?> get props => [user, config];
}

class UserError extends UserState {
  final String message;

  const UserError({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserUpdated extends UserState {
  final UserEntity user;

  const UserUpdated({required this.user});

  @override
  List<Object?> get props => [user];
}