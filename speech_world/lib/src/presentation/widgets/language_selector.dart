/// Language Selector Widget
/// 
/// UI component for selecting L1 and L2 languages in Dialogue Mode.
/// Provides a dropdown interface with flags and native names.
library;

import 'package:flutter/material.dart';
import '../../core/config/languages.dart';

/// Callback when language selection changes
typedef OnLanguageChanged = void Function(String l1Code, String l2Code);

/// Language Selector Widget
/// 
/// Displays two language selectors (L1 and L2) with swap button.
class LanguageSelector extends StatefulWidget {
  final String initialL1;
  final String initialL2;
  final OnLanguageChanged onChanged;

  const LanguageSelector({
    super.key,
    this.initialL1 = defaultL1Language,
    this.initialL2 = defaultL2Language,
    required this.onChanged,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  late String _l1Code;
  late String _l2Code;

  @override
  void initState() {
    super.initState();
    _l1Code = widget.initialL1;
    _l2Code = widget.initialL2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Select Languages',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Language selectors row
          Row(
            children: [
              // L1 Selector
              Expanded(
                child: _LanguageDropdown(
                  label: 'I speak',
                  selectedCode: _l1Code,
                  excludeCode: _l2Code,
                  onChanged: (code) {
                    setState(() => _l1Code = code);
                    widget.onChanged(_l1Code, _l2Code);
                  },
                ),
              ),
              
              // Swap button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _SwapButton(
                  onPressed: _swapLanguages,
                ),
              ),
              
              // L2 Selector
              Expanded(
                child: _LanguageDropdown(
                  label: 'They speak',
                  selectedCode: _l2Code,
                  excludeCode: _l1Code,
                  onChanged: (code) {
                    setState(() => _l2Code = code);
                    widget.onChanged(_l1Code, _l2Code);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _swapLanguages() {
    setState(() {
      final temp = _l1Code;
      _l1Code = _l2Code;
      _l2Code = temp;
    });
    widget.onChanged(_l1Code, _l2Code);
  }
}

/// Individual language dropdown
class _LanguageDropdown extends StatelessWidget {
  final String label;
  final String selectedCode;
  final String? excludeCode;
  final ValueChanged<String> onChanged;

  const _LanguageDropdown({
    required this.label,
    required this.selectedCode,
    this.excludeCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        // Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCode,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(12),
              items: supportedLanguages
                  .where((lang) => lang.code != excludeCode)
                  .map((language) => DropdownMenuItem(
                        value: language.code,
                        child: Row(
                          children: [
                            Text(language.flag, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    language.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    language.nativeName,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (code) {
                if (code != null) onChanged(code);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Swap languages button
class _SwapButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SwapButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.swap_horiz,
          color: Colors.blue,
        ),
        tooltip: 'Swap languages',
      ),
    );
  }
}

/// Compact language selector for small spaces
class CompactLanguageSelector extends StatelessWidget {
  final String l1Code;
  final String l2Code;
  final VoidCallback onTap;

  const CompactLanguageSelector({
    super.key,
    required this.l1Code,
    required this.l2Code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l1 = getLanguageByCode(l1Code);
    final l2 = getLanguageByCode(l2Code);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // L1
            Text(l1?.flag ?? '🏳️', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              l1?.code.toUpperCase() ?? 'L1',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.swap_horiz,
                color: Colors.grey[400],
                size: 20,
              ),
            ),
            
            // L2
            Text(l2?.flag ?? '🏳️', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              l2?.code.toUpperCase() ?? 'L2',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
