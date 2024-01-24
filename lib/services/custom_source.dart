import 'package:just_audio/just_audio.dart';

class MyCustomSource extends StreamAudioSource {
  final List<int> bytes;

  MyCustomSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;

    return StreamAudioResponse(
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mp4',
      sourceLength: bytes.length,
    );
  }
}
