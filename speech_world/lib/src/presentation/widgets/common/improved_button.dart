import 'package:flutter/material.dart';

/// Улучшенная кнопка с анимацией и поддержкой различных состояний
class ImprovedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;
  final double elevation;
  final BoxShadow? shadow;

  const ImprovedButton({
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.padding,
    this.margin,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.elevation = 2.0,
    this.shadow,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPressed = isLoading || isDisabled;
    final Color buttonColor = backgroundColor ?? Theme.of(context).primaryColor;
    final Color textButtonColor = textColor ?? Colors.white;
    final Color borderColorColor = borderColor ?? buttonColor;

    return Container(
      margin: margin,
      child: ElevatedButton(
        onPressed: isPressed ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPressed
              ? buttonColor.withValues(alpha: 0.6)
              : buttonColor,
          foregroundColor: textButtonColor,
          side: BorderSide(color: borderColorColor, width: 1.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding:
              padding ??
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          elevation: isPressed ? 0 : elevation,
          shadowColor: shadow?.color,
          minimumSize: Size(width ?? double.infinity, height ?? 50.0),
          textStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize ?? 20.0,
                color: iconColor ?? textButtonColor,
              ),
              const SizedBox(width: 8.0),
            ],
            if (isLoading) ...[
              const SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12.0),
            ],
            Text(
              text,
              style: TextStyle(
                color: textButtonColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Круглая кнопка с иконкой
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final String? tooltip;

  const CircularIconButton({
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 56.0,
    this.iconSize = 24.0,
    this.tooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: SizedBox(
        width: size,
        height: size,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
            foregroundColor: iconColor ?? Colors.white,
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            elevation: 4.0,
          ),
          child: Icon(icon, size: iconSize, color: iconColor ?? Colors.white),
        ),
      ),
    );
  }
}

/// Кнопка с градиентом
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> colors;
  final double? width;
  final double? height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;

  const GradientButton({
    required this.text,
    required this.onPressed,
    this.colors = const [Color(0xFF4285F4), Color(0xFF34A853)],
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.bold,
    this.padding,
    this.margin,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.iconSize,
    this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPressed = isLoading || isDisabled;

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPressed
              ? colors.map((color) => color.withValues(alpha: 0.6)).toList()
              : colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? []
            : [
                BoxShadow(
                  color: colors.first.withValues(alpha: 0.3),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isPressed ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding:
              padding ??
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: iconSize ?? 20.0,
                color: iconColor ?? Colors.white,
              ),
              const SizedBox(width: 8.0),
            ],
            if (isLoading) ...[
              const SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12.0),
            ],
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
