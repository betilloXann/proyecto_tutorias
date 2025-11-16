import 'package:flutter/material.dart';
import 'package:proyecto_tutorias/features/login/views/login_view.dart';
import 'package:proyecto_tutorias/features/login/views/register_view.dart';
import 'package:proyecto_tutorias/features/login/views/welcome_view.dart';
import 'package:proyecto_tutorias/features/login/views/verify_code_view.dart';
import 'package:proyecto_tutorias/features/dashboard/views/home_menu_view.dart';

Map<String, WidgetBuilder> appRoutes = {
  "/welcome": (_) => WelcomeView(),
  "/login": (_) => LoginView(),
  "/register": (_) => RegisterView(),
  "/verify": (_) => VerifyCodeView(),
  "/home": (_) => HomeMenuView(),
};
