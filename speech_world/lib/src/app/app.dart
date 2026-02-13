import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_world/src/app/app_colors.dart';
import 'package:speech_world/src/data/repositories/auth_repository_impl.dart';
import 'package:speech_world/src/data/repositories/user_repository_impl.dart';
import 'package:speech_world/src/domain/repositories/auth_repository.dart';
import 'package:speech_world/src/domain/repositories/user_repository.dart';
import 'package:speech_world/src/domain/usecases/create_user_if_not_exists_usecase.dart';
import 'package:speech_world/src/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:speech_world/src/domain/usecases/sign_out_usecase.dart';
import 'package:speech_world/src/presentation/controllers/auth_cubit.dart';
import 'package:speech_world/src/presentation/controllers/home_controller.dart';
import 'package:speech_world/src/presentation/controllers/profile_controller.dart';
import 'package:speech_world/src/presentation/controllers/subscription_controller.dart';
import 'package:speech_world/src/presentation/controllers/user_cubit.dart';
import 'package:speech_world/src/presentation/screens/dialogue_screen.dart';
import 'package:speech_world/src/presentation/screens/profile/profile_screen.dart';
import 'package:speech_world/src/presentation/screens/subscription/subscription_screen.dart';
import 'package:speech_world/src/presentation/screens/welcome/welcome_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  // Initialize controllers
  late final HomeController _homeController;
  late final ProfileController _profileController;
  late final SubscriptionController _subscriptionController;
  late final AuthCubit _authCubit;
  late final UserCubit _userCubit;

  // Repository instances
  late final AuthRepository _authRepository;
  late final UserRepository _userRepository;

  // Use cases
  late final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  late final SignOutUseCase _signOutUseCase;
  late final CreateUserIfNotExistsUseCase _createUserIfNotExistsUseCase;

  late final List<Widget> _screens;
  // Flag to indicate async dependency initialization completed
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Firebase уже инициализирован в main.dart
    // Не вызываем FirebaseService.initialize() здесь

    // Инициализация зависимостей (ждём завершения и помечаем флаг)
    _initDependencies().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  Future<void> _initDependencies() async {
    final preferences = await SharedPreferences.getInstance();

    _authRepository = AuthRepositoryImpl(
      firebaseAuth: FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(
        scopes: ['email'],
        serverClientId:
            '137235369956-ehr5ldr7vcf41f5vvgpgfl6bhdb6gpl1.apps.googleusercontent.com',
      ),
    );
    _userRepository = UserRepositoryImpl();
    _signInWithGoogleUseCase = SignInWithGoogleUseCase(
      authRepository: _authRepository,
    );
    _signOutUseCase = SignOutUseCase(authRepository: _authRepository);
    _createUserIfNotExistsUseCase = CreateUserIfNotExistsUseCase(
      userRepository: _userRepository,
    );

    // Инициализация Cubit'ов
    _authCubit = AuthCubit(
      authRepository: _authRepository,
      firebaseAuth: FirebaseAuth.instance,
      googleSignIn: GoogleSignIn(
        scopes: ['email'],
        serverClientId:
            '137235369956-ehr5ldr7vcf41f5vvgpgfl6bhdb6gpl1.apps.googleusercontent.com',
      ),
      preferences: preferences,
    );

    _userCubit = UserCubit();

    _homeController = HomeController();
    _profileController = ProfileController(userCubit: _userCubit);
    _subscriptionController = SubscriptionController();

    _screens = [
      BlocProvider.value(value: _authCubit, child: const WelcomeScreen()),
      BlocProvider.value(
        value: _userCubit,
        child: const DialogueScreen(),
      ),
      BlocProvider.value(
        value: _userCubit,
        child: const ProfileScreen(),
      ),
      const SubscriptionScreen(),
    ];

    // Проверяем статус аутентификации при старте
    _authCubit.checkAuthStatus();

    // Инициализируем use case'ы для будущих возможностей
    _signInWithGoogleUseCase;
    _signOutUseCase;
    _createUserIfNotExistsUseCase;
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _userCubit),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          debugPrint(
            'BlocListener(AuthCubit) received state: ${state.runtimeType}',
          );
          // Возвращаемся на Welcome screen при выходе
          if (state is AuthUnauthenticated) {
            setState(() {
              _currentIndex = 0;
            });
          }
          // Переходим на Home screen при успешной аутентификации
          if (state is Authenticated) {
            debugPrint(
              'Auth state is Authenticated; current index=$_currentIndex',
            );
            // Load user data into UserCubit
            _userCubit.loadUser(state.user.id);
            
            // Остаемся на Welcome или переходим на Home по выбору
            if (_currentIndex == 0) {
              setState(() {
                _currentIndex = 1;
              });
            }
          }
        },
        child: Scaffold(
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.bottomBar,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  // Проверяем аутентификацию для перехода на главный экран
                  if (index == 1 || index == 2 || index == 3) {
                    final authState = _authCubit.state;
                    if (authState is! Authenticated) {
                      // Показываем WelcomeScreen, если пользователь не авторизован
                      setState(() {
                        _currentIndex = 0;
                      });
                      return;
                    }
                  }
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primaryYellow,
                unselectedItemColor: AppColors.textSecondary,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Welcome',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.translate),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.star),
                    label: 'Subscription',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose only if initialization completed (avoid accessing uninitialized late fields)
    if (_initialized) {
      _homeController.dispose();
      _profileController.dispose();
      _subscriptionController.dispose();
      _authCubit.close();
      _userCubit.close();
    }
    super.dispose();
  }
}