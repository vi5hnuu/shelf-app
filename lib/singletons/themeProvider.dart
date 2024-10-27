import 'dart:async';

import 'package:flutter/material.dart';

class ThemeProvider{
  static final ThemeProvider _instance=ThemeProvider._();
  static final StreamController<ThemeMode> _themeStreamController=StreamController<ThemeMode>();
  ThemeMode? _currentTheme=ThemeMode.light;

  ThemeProvider._();

  get stream{
    return _themeStreamController.stream;
  }

  factory ThemeProvider(){
    return _instance;
  }

  lightMode(){
    _themeStreamController.sink.add(_currentTheme=ThemeMode.light);
  }

  darkMode(){
    _themeStreamController.sink.add(_currentTheme=ThemeMode.dark);
  }

  get theme{
    return _currentTheme;
  }

  void dispose(){
    _themeStreamController.close();
  }
}