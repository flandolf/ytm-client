import 'package:flutter/material.dart';
import 'package:ytmusicstreamer/screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'YTMusicStreamer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const Home(),
      )
  );
}
