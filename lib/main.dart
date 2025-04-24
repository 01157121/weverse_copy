import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'home.dart';

final AudioPlayer _audioPlayer = AudioPlayer();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize and start background music
  try {
    await _audioPlayer.setAsset('assets/images/cheerful-marimba-melody-for-happy-moments-232400');
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.play();
  } catch (e) {
    print('Error loading audio: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weverse Shop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
