import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_world/src/app/theme.dart';
import 'package:speech_world/src/presentation/controllers/user_cubit.dart';
import 'package:speech_world/src/presentation/states/user_state.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          _buildAppBar(),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Current plan info
                  _buildCurrentPlanCard(context),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Section title
                  Text(
                    'Выберите тариф',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Обновите план для получения дополнительных возможностей',
                    style: AppTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Free plan
                  _buildPlanCard(
                    context,
                    name: 'Free',
                    description: 'Базовые возможности перевода',
                    price: 'Бесплатно',
                    period: '',
                    features: const [
                      '50 кредитов при регистрации',
                      'Базовый перевод речи',
                      'Стандартное качество',
                      'Онлайн режим',
                    ],
                    isPopular: false,
                    isCurrent: true,
                    onTap: () {
                      // Already on free plan
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spaceMd),
                  
                  // Plus plan
                  _buildPlanCard(
                    context,
                    name: 'Plus',
                    description: 'Расширенные возможности',
                    price: '\$9.99',
                    period: '/месяц',
                    features: const [
                      '500 кредитов в месяц',
                      'Продвинутый перевод',
                      'Высокое качество',
                      'Приоритетная обработка',
                    ],
                    isPopular: true,
                    isCurrent: false,
                    accentColor: AppTheme.secondary,
                    onTap: () {
                      _showComingSoonSnackbar(context);
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spaceMd),
                  
                  // Pro plan
                  _buildPlanCard(
                    context,
                    name: 'Pro',
                    description: 'Максимальные возможности',
                    price: '\$19.99',
                    period: '/месяц',
                    features: const [
                      'Безлимитные кредиты',
                      'Премиум перевод',
                      'Максимальное качество',
                      '24/7 поддержка',
                    ],
                    isPopular: false,
                    isCurrent: false,
                    accentColor: AppTheme.accent1,
                    onTap: () {
                      _showComingSoonSnackbar(context);
                    },
                  ),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Credits info card
                  _buildCreditsInfoCard(context),
                  
                  const SizedBox(height: AppTheme.spaceXl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // App Bar with gradient
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Подписка',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      leading: const BackButton(color: Colors.white),
    );
  }

  // Current plan info card
  Widget _buildCurrentPlanCard(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        String planName = 'Free';
        String status = 'active';
        int credits = 0;

        if (state is UserLoaded) {
          planName = state.user.subscription['planId']?.toString() ?? 'Free';
          status = state.user.subscription['status']?.toString() ?? 'active';
          credits = state.user.credits;
        } else if (state is UserLoadedWithConfig) {
          planName = state.user.subscription['planId']?.toString() ?? 'Free';
          status = state.user.subscription['status']?.toString() ?? 'active';
          credits = state.user.credits;
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.1),
                AppTheme.primaryLight.withValues(alpha: 0.3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Icon(
                        Icons.card_membership,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Текущий план',
                            style: AppTheme.bodyMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            planName.toUpperCase(),
                            style: AppTheme.heading3.copyWith(
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMd,
                        vertical: AppTheme.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status == 'active'
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status == 'active' ? 'Активен' : 'Приостановлен',
                            style: AppTheme.labelMedium.copyWith(
                              color: status == 'active'
                                  ? AppTheme.success
                                  : AppTheme.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Divider(
                  color: AppTheme.glassBorder,
                  height: 1,
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Доступно кредитов:',
                      style: AppTheme.bodyMedium,
                    ),
                    Text(
                      '$credits',
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Plan card widget
  Widget _buildPlanCard(
    BuildContext context, {
    required String name,
    required String description,
    required String price,
    required String period,
    required List<String> features,
    required bool isPopular,
    required bool isCurrent,
    Color accentColor = AppTheme.primary,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isCurrent
            ? accentColor.withValues(alpha: 0.05)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isCurrent
              ? accentColor.withValues(alpha: 0.4)
              : isPopular
                  ? accentColor.withValues(alpha: 0.3)
                  : AppTheme.glassBorder,
          width: isCurrent || isPopular ? 2 : 1,
        ),
        boxShadow: isPopular ? AppTheme.mediumShadow : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusLarge - 2),
                  topRight: Radius.circular(AppTheme.radiusLarge - 2),
                ),
              ),
              child: const Center(
                child: Text(
                  'ПОПУЛЯРНЫЙ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTheme.heading2.copyWith(
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: AppTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMd,
                          vertical: AppTheme.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.success,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Текущий',
                              style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: AppTheme.heading1.copyWith(
                        fontSize: 32,
                      ),
                    ),
                    if (period.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          period,
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceMd),
                Divider(color: AppTheme.glassBorder),
                const SizedBox(height: AppTheme.spaceMd),
                ...features.map((feature) => _buildFeatureItem(feature)),
                const SizedBox(height: AppTheme.spaceLg),
                if (!isCurrent)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: const Text(
                        'Выбрать',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Feature item
  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppTheme.success,
            size: 18,
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Credits info card
  Widget _buildCreditsInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.accent3.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.info_outline,
              color: AppTheme.accent3,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Что такое кредиты?',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '1 кредит = 1 минута перевода речи. Кредиты обновляются каждый месяц в зависимости от вашего тарифа.',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.white),
            SizedBox(width: 12),
            Text('Скоро будет доступно'),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppTheme.spaceMd),
      ),
    );
  }
}
