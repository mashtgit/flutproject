import 'package:flutter/material.dart';
import 'package:speech_world/src/app/theme.dart';
import 'package:speech_world/src/presentation/controllers/home_controller.dart';

class HomeScreen extends StatefulWidget {
  final HomeController controller;
  const HomeScreen({super.key, required this.controller});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HomeController _controller;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _textController = TextEditingController(text: _controller.inputText);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (_textController.text != _controller.inputText) {
      _textController.text = _controller.inputText;
    }
    setState(() {});
  }

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
                  // Language selector
                  _buildLanguageSelector(),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Dialogue Mode Card
                  _buildDialogueModeCard(),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Text Mode Card
                  _buildTextModeCard(),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Test Mode Card (Echo Mode)
                  _buildTestModeCard(),
                  
                  const SizedBox(height: AppTheme.spaceLg),
                  
                  // Error message
                  if (_controller.errorMessage != null)
                    _buildErrorCard(),
                    
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
      expandedHeight: 120,
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
          'Перевод',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  // Language selector row
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.glassBorder,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          // Source language
          Expanded(
            child: _buildLanguageDropdown(
              value: _controller.sourceLanguage,
              label: 'С',
              options: const [
                ('en', 'English'),
                ('es', 'Spanish'),
                ('ru', 'Russian'),
              ],
              onChanged: (value) => _controller.setSourceLanguage(value!),
            ),
          ),
          
          // Swap button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {
                final temp = _controller.sourceLanguage;
                _controller.setSourceLanguage(_controller.targetLanguage);
                _controller.setTargetLanguage(temp);
              },
              icon: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          
          // Target language
          Expanded(
            child: _buildLanguageDropdown(
              value: _controller.targetLanguage,
              label: 'На',
              options: const [
                ('ru', 'Russian'),
                ('fr', 'French'),
                ('en', 'English'),
              ],
              onChanged: (value) => _controller.setTargetLanguage(value!),
            ),
          ),
        ],
      ),
    );
  }

  // Language dropdown widget
  Widget _buildLanguageDropdown({
    required String value,
    required String label,
    required List<(String, String)> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.labelMedium.copyWith(
            color: AppTheme.textMuted,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.glassBorder,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
              items: options.map((option) {
                return DropdownMenuItem(
                  value: option.$1,
                  child: Text(option.$2),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // Dialogue Mode Card (Voice translation)
  Widget _buildDialogueModeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.1),
            AppTheme.primaryLight.withValues(alpha: 0.2),
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
          children: [
            // Mode badge
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
                  const Icon(
                    Icons.mic,
                    size: 16,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'РЕЖИМ ДИАЛОГА',
                    style: AppTheme.labelMedium.copyWith(
                      color: AppTheme.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLg),
            
            // Description
            Text(
              'Говорите, и приложение автоматически переведет речь',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppTheme.spaceLg),
            
            // Large microphone button
            GestureDetector(
              onTap: () {
                _controller.startVoiceRecognition();
              },
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMd),
            
            // Hint text
            Text(
              'Нажмите и говорите',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Text Mode Card
  Widget _buildTextModeCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.glassBorder,
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Mode badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.translate,
                        size: 16,
                        color: AppTheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ТЕКСТОВЫЙ РЕЖИМ',
                        style: AppTheme.labelMedium.copyWith(
                          color: AppTheme.secondaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Clear button
                IconButton(
                  onPressed: () {
                    _controller.setInputText('');
                  },
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surfaceVariant,
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spaceMd),
            
            // Text input
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.glassBorder,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Введите текст для перевода...',
                  hintStyle: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textMuted,
                  ),
                  border: InputBorder.none,
                ),
                style: AppTheme.bodyLarge,
                maxLines: 4,
                onChanged: (value) {
                  _controller.setInputText(value);
                },
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceMd),
            
            // Action buttons
            Row(
              children: [
                // Translate button
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.secondary, AppTheme.secondaryDark],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _controller.translateText,
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.translate,
                              color: Colors.white,
                              size: 22,
                            ),
                            SizedBox(width: AppTheme.spaceSm),
                            Text(
                              'Перевести',
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
                  ),
                ),
                
                const SizedBox(width: AppTheme.spaceMd),
                
                // Voice input button
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _controller.isListening
                        ? AppTheme.primary
                        : AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    boxShadow: _controller.isListening
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    onPressed: () {
                      _controller.startVoiceRecognition();
                    },
                    icon: Icon(
                      _controller.isListening ? Icons.hearing : Icons.mic,
                      color: _controller.isListening
                          ? Colors.white
                          : AppTheme.textSecondary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Test Mode Card (Echo Mode for testing)
  Widget _buildTestModeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          children: [
            // Mode badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: AppTheme.spaceXs,
              ),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.build,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ТЕСТОВЫЙ РЕЖИМ',
                    style: AppTheme.labelMedium.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spaceLg),
            
            // Description
            Text(
              'Тестирование аудио без сервера. Запись и воспроизведение.',
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppTheme.spaceLg),
            
            // Test button
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.orange.shade700],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/echo-test');
                  },
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: AppTheme.spaceSm),
                      Text(
                        'Тест аудио',
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
            ),
          ],
        ),
      ),
    );
  }

  // Error card
  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppTheme.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppTheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Text(
              _controller.errorMessage!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.error,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              _controller.clearError();
            },
            icon: const Icon(Icons.close, size: 18),
            color: AppTheme.textMuted,
          ),
        ],
      ),
    );
  }
}
