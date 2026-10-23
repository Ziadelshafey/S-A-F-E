import 'package:flutter/material.dart';
import 'router.dart';
import 'theme.dart';

class SafeApp extends StatelessWidget {
  const SafeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SAFE',
        debugShowCheckedModeBanner: false,
        theme: SafeTheme.dark,
        initialRoute: Routes.home,
        onGenerateRoute: AppRouter.generate,
      );
}
