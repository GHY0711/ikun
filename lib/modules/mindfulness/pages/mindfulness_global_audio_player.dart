import 'package:audioplayers/audioplayers.dart';

class GlobalAudioPlayer {
  GlobalAudioPlayer._();

  static final AudioPlayer player = AudioPlayer();

  static String? currentSource;
}
