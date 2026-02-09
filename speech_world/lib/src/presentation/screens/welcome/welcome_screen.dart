import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_world/src/app/theme.dart';
import 'package:speech_world/src/presentation/controllers/auth_cubit.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background gradient circles
          _buildBackgroundDecorations(),
          
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  
                  // Logo and App Icon
                  _buildLogoSection(),
                  
                  const SizedBox(height: AppTheme.space2Xl),
                  
                  // Title and Subtitle
                  _buildTitleSection(),
                  
                  const Spacer(flex: 3),
                  
                  // Features showcase
                  _buildFeaturesSection(),
                  
                  const Spacer(flex: 2),
                  
                  // Auth Buttons
                  _buildAuthButtons(context),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Terms text
                  _buildTermsText(),
                  
                  const SizedBox(height: AppTheme.spaceMd),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Background decorative elements
  Widget _buildBackgroundDecorations() {
    return Stack(
      children: [
        // Top right circle
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: 0.2),
                  AppTheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Bottom left circle
        Positioned(
          bottom: -50,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondary.withValues(alpha: 0.15),
                  AppTheme.secondary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Logo section with app icon
  Widget _buildLogoSection() {
    return Center(
      child: Column(
        children: [
          // Main logo container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.translate_rounded,
              size: 72,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          
          // App name badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceMd,
              vertical: AppTheme.spaceXs,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Speech Translation',
                  style: AppTheme.labelMedium.copyWith(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Title and subtitle section
  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Speech World',
          style: AppTheme.heading1.copyWith(
            fontSize: 36,
            letterSpacing: -1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text(
          'Мгновенный перевод речи с помощью искусственного интеллекта',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Features showcase
  Widget _buildFeaturesSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFeatureItem(
          icon: Icons.mic,
          label: 'Голос',
          color: AppTheme.primary,
        ),
        const SizedBox(width: AppTheme.spaceLg),
        _buildFeatureItem(
          icon: Icons.translate,
          label: 'Перевод',
          color: AppTheme.secondary,
        ),
        const SizedBox(width: AppTheme.spaceLg),
        _buildFeatureItem(
          icon: Icons.volume_up,
          label: 'Озвучка',
          color: AppTheme.accent1,
        ),
      ],
    );
  }

  // Individual feature item
  Widget _buildFeatureItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // Authentication buttons
  Widget _buildAuthButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Google Sign In Button
        _buildGoogleButton(context),
        
        const SizedBox(height: AppTheme.spaceMd),
        
        // Or divider
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.glassBorder,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
              child: Text(
                'или',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppTheme.glassBorder,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spaceMd),
        
        // Continue as guest button
        _buildGuestButton(context),
      ],
    );
  }

  // Google sign in button
  Widget _buildGoogleButton(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: AppTheme.glassBorder,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.read<AuthCubit>().signInWithGoogle();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google "G" icon representation
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.g_mobiledata,
                  color: AppTheme.error,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Text(
                'Продолжить с Google',
                style: AppTheme.labelLarge.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Guest button
  Widget _buildGuestButton(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // For now, use Google sign in as primary method
            context.read<AuthCubit>().signInWithGoogle();
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login_rounded,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: AppTheme.spaceMd),
              Text(
                'Войти в приложение',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Terms and privacy text
  Widget _buildTermsText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: Text(
        'Продолжая, вы соглашаетесь с Условиями использования и Политикой конфиденциальности',
        style: AppTheme.labelMedium.copyWith(
          color: AppTheme.textMuted,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
