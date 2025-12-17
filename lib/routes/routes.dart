import 'package:flutter/material.dart';
// LOGIN FLOW
import 'package:proyecto_tutorias/features/login/views/welcome_view.dart';
import 'package:proyecto_tutorias/features/login/views/login_view.dart';
import 'package:proyecto_tutorias/features/login/views/student_lookup_view.dart';
import 'package:proyecto_tutorias/features/login/views/forgot_password_view.dart';

//ADMIN
import 'package:proyecto_tutorias/features/admin/views/admin_dashboard_view.dart';

// DASHBOARD
import 'package:proyecto_tutorias/features/dashboard/views/home_menu_view.dart';

Map<String, WidgetBuilder> appRoutes = {
  "/welcome": (_) => const WelcomeView(),
  "/login": (_) => const LoginView(),
  "/activation": (_) => const StudentLookupView(),
  "/recover": (_) => ForgotPasswordView(),
  "/home": (_) => const HomeMenuView(),
  "/admin": (_) => const AdminDashboardView(),
};