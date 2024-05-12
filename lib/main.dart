import 'package:flutter/material.dart';
import 'package:sound_wave/home_page.dart';
import 'package:sound_wave/pallete.dart';

void main() {
  //debugProfileBuildsEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SoundWave',
        theme: ThemeData.light(useMaterial3: true).copyWith(
            scaffoldBackgroundColor: Pallete.whiteColor,
            appBarTheme:
                const AppBarTheme(backgroundColor: Pallete.whiteColor)),
        home: const HomePage());
  }
}
