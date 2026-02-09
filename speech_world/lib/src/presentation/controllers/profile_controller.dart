import 'package:flutter/material.dart';
import 'package:speech_world/src/presentation/controllers/user_cubit.dart';
import 'package:speech_world/src/presentation/states/user_state.dart';

class ProfileController {
  final UserCubit userCubit;

  ProfileController({required this.userCubit});

  void setEditing(bool isEditing) {
    // Реализовать редактирование профиля
    debugPrint('Editing mode: $isEditing');
  }

  Future<void> refreshProfile() async {
    // Получаем текущего пользователя из состояния
    final currentState = userCubit.state;
    if (currentState is UserLoaded) {
      // Перезагружаем пользователя
      await userCubit.loadUser(currentState.user.id);
    }
  }

  void dispose() {
    // В данном случае, так как UserCubit управляется через BLOC,
    // мы не должны его здесь удалять
  }
}
