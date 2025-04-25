import 'package:apps/Pages/splash_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'Pages/theme_provider.dart';
import 'package:provider/provider.dart';
import 'Services/cart_service.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder:
          (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (context) => ThemeProvider()),
              ChangeNotifierProvider(create: (context) => CartService()),
            ],
            child: MyApp(),
          ),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          theme: themeProvider.isDarkMode ? themeProvider.darkTheme : ThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
        );
      },
    );
  }
}
