import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/bindings/initial_binding.dart';
import 'package:sweetipie/routes/app_pages.dart';
import 'package:sweetipie/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SweetiePie',
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
