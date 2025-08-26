import 'package:flutter/material.dart';

class DarkThemeColors {
  // Colores de fondo
  static Color get surfaceColor => Colors.grey[900]!;
  static Color get cardColor => Colors.grey[800]!;
  static Color get containerColor => Colors.grey[700]!;
  static Color get inputColor => Colors.grey[800]!;
  
  // Colores de bordes
  static Color get borderColor => Colors.grey[600]!;
  static Color get dividerColor => Colors.grey[700]!;
  
  // Colores de texto
  static Color get primaryTextColor => Colors.white;
  static Color get secondaryTextColor => Colors.grey[300]!;
  static Color get tertiaryTextColor => Colors.grey[400]!;
  static Color get disabledTextColor => Colors.grey[500]!;
  
  // Colores de estados
  static Color get successColor => Colors.green[400]!;
  static Color get warningColor => Colors.orange[400]!;
  static Color get errorColor => Colors.red[400]!;
  static Color get infoColor => Colors.blue[400]!;
  
  // Colores de fondo para estados
  static Color get successBackgroundColor => Colors.green[900]!.withOpacity(0.2);
  static Color get warningBackgroundColor => Colors.orange[900]!.withOpacity(0.2);
  static Color get errorBackgroundColor => Colors.red[900]!.withOpacity(0.2);
  static Color get infoBackgroundColor => Colors.blue[900]!.withOpacity(0.2);
  
  // Método para obtener colores basados en el tema
  static Color getSurfaceColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? surfaceColor : theme.colorScheme.surface;
  }
  
  static Color getCardColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? cardColor : Colors.white;
  }
  
  static Color getContainerColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? containerColor : Colors.grey[50]!;
  }
  
  static Color getBorderColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? borderColor : Colors.grey[300]!;
  }
  
  static Color getPrimaryTextColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? primaryTextColor : Colors.black87;
  }
  
  static Color getSecondaryTextColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? secondaryTextColor : Colors.grey[700]!;
  }
  
  static Color getTertiaryTextColor(ThemeData theme) {
    return theme.brightness == Brightness.dark ? tertiaryTextColor : Colors.grey[600]!;
  }
  
  // Método para obtener color de fondo con opacidad
  static Color getBackgroundWithOpacity(ThemeData theme, Color color, double opacity) {
    final isDark = theme.brightness == Brightness.dark;
    return isDark ? color.withOpacity(opacity * 1.5) : color.withOpacity(opacity);
  }
  
  // Método para obtener color de estado con mejor contraste
  static Color getStateColor(ThemeData theme, Color color) {
    final isDark = theme.brightness == Brightness.dark;
    if (isDark) {
      // Aumentar la luminosidad para mejor contraste en tema oscuro
      final hsl = HSLColor.fromColor(color);
      return hsl.withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0)).toColor();
    }
    return color;
  }
}
