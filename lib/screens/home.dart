import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:ytmusicstreamer/services/custom_source.dart';
import 'package:ytmusicstreamer/services/next_songs_list.dart';
import 'dart:async';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int sleepTimerSeconds = 0;
  final TextEditingController _urlController = TextEditingController();
  final player = AudioPlayer();
  final YoutubeExplode yt = YoutubeExplode();
  Duration actualDurationMs = Duration.zero;
  List<Video> playlist = [];
  int currentIndex = 0;
  bool isShuffle = false;
  bool isRepeat = false;
  Video? currentVideo;
  bool sleepTimer = false;
  Duration remainingSleepTime = Duration.zero;


  Future<void> _play() async {
    final String url = _urlController.text;

    if (url.contains("list=")) {
      await _playPlaylist(url);
    } else {
      await _playVideo(url);
    }

  }

  void setSleepTimer(int seconds) {
    sleepTimer = true;
    sleepTimerSeconds = seconds;
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (sleepTimerSeconds > 0) {
        sleepTimerSeconds--;
        remainingSleepTime = Duration(seconds: sleepTimerSeconds);
        setState(() {});
      } else {
        timer.cancel();
        player.stop();
        player.seek(Duration.zero);
        sleepTimer = false;
        sleepTimerSeconds = 0;
        setState(() {});
      }
    });
  }

  void cancelSleepTimer() {
    sleepTimer = false;
    sleepTimerSeconds = 0;
  }


  Future<void> _playPlaylist(String playlistUrl) async {
    playlist = await yt.playlists.getVideos(playlistUrl).toList();
    currentIndex = 0;
    if (isShuffle) {
      _shufflePlaylist();
    }
    await _playCurrentVideo();
  }

  Future<void> _playVideo(String url) async {
    var video = await yt.videos.get(url);
    playlist = [video];
    currentIndex = 0;
    await _playCurrentVideo();
  }

  Future<void> _playNextSong(int index) async {
    // Stop the current video
    await player.stop();

    // Play the next video in the playlist
    currentIndex = index;
    await _playCurrentVideo();

    _updateSongList();
  }

  Future<void> _playCurrentVideo() async {
    var video = playlist[currentIndex];
    var id = video.id;
    var manifest = await yt.videos.streamsClient.getManifest(id);
    var streamInfo = manifest.audioOnly
        .where((element) => element.audioCodec.contains("mp4a"))
        .last;
    actualDurationMs = video.duration!;
    var stream = yt.videos.streamsClient.get(streamInfo);
    List<int> bytes = await stream.expand((element) => element).toList();
    await player.setAudioSource(MyCustomSource(bytes));

    currentVideo = video;
    setState(() {});

    await player.play();
  }

  void _updateSongList() {
    setState(() {
      playlist = playlist;
      remainingSleepTime = sleepTimer ? Duration(seconds: sleepTimerSeconds) : Duration.zero;
    });
  }


  Future<void> _playNext() async {
    // Stop the current video
    await player.stop();

    if (!isRepeat && currentIndex == playlist.length - 1) {
      return;
    }
    currentIndex = (currentIndex + 1) % playlist.length;


    await _playCurrentVideo();

    _updateSongList();
  }

  Future<void> _playPrevious() async {
    // Stop the current video
    await player.stop();
    // Play the previous video in the playlist
    currentIndex = (currentIndex - 1 + playlist.length) % playlist.length;
    await _playCurrentVideo();
  }

  void _shufflePlaylist() {
    playlist.shuffle();
    playlist.shuffle();
    playlist.shuffle();
    currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            const Text('flandy\'s yt music streamer',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'URL: ',
              ),
            ),
            const SizedBox(height: 5),
            FilledButton(onPressed: _play, child: const Text('Play')),
            const SizedBox(height: 5),
            Text("${playlist.length} songs in playlist"),
            Expanded(child: Container()),
            Text(currentVideo?.title ?? "", style: const TextStyle(fontSize: 30),),
            Text(currentVideo?.author ?? "", style: const TextStyle(fontSize: 20),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _shufflePlaylist();
                    });
                  },
                  icon: const Icon(Icons.shuffle),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isRepeat = !isRepeat;
                    });
                  },
                  icon: Icon(
                    isRepeat ? Icons.repeat_on : Icons.repeat,
                    color: isRepeat ? Colors.white : null,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {
                    setState(() {
                      player.setSpeed(player.speed == 1.0 ? 1.3 : 1.0);
                    });
                  },
                  icon: Icon(
                    Icons.speed,
                    color: player.speed == 1.3 ? Colors.white : null,
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () {
                    setState(() {
                      sleepTimer ? cancelSleepTimer() : setSleepTimer(60 * 60);
                    });
                  },
                  icon: sleepTimer ? const Icon(Icons.timer) : const Icon(Icons.timer_off),
                )
              ],
            ),
            StreamBuilder<Duration?>(
              stream: player.positionStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    player.duration == null) {
                  return const LinearProgressIndicator(value: null);
                }

                Duration position = snapshot.data ?? Duration.zero;

                // Check if the current position exceeds or equals actualDurationMs
                if (position >= actualDurationMs) {
                  // Stop the player
                  player.stop();
                  player.seek(Duration.zero);
                  // Play the next video in the playlist
                  _playNext();

                  // Update the position to avoid overflow
                  position = Duration.zero;
                }

                return Column(
                  children: [
                    Slider(
                      value: position.inMilliseconds.toDouble(),
                      min: 0.0,
                      max: actualDurationMs.inMilliseconds.toDouble(),
                      onChanged: (double value) {
                        setState(() {
                          // Check if the value is within valid bounds
                          if (value >= 0 &&
                              value <= actualDurationMs.inMilliseconds) {
                            player.seek(Duration(milliseconds: value.toInt()));
                          }
                        });
                      },
                      onChangeStart: (double value) {
                        player.pause();
                      },
                      onChangeEnd: (double value) {
                        player.play();
                        setState(() {});
                      },
                    ),
                    Text(
                      "${position.inMinutes}:${position.inSeconds.remainder(60).toString().padLeft(2, '0')} / ${actualDurationMs.inMinutes}:${actualDurationMs.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                    ),
                    Text(
                      "Sleep: ${remainingSleepTime.inMinutes}:${remainingSleepTime.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                    ),

                  ],
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _playPrevious,
                  icon: const Icon(Icons.skip_previous),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (player.playing) {
                        player.pause();
                      } else {
                        player.play();
                      }
                    });
                  },
                  icon: Icon(
                    player.playing
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _playNext,
                  icon: const Icon(Icons.skip_next),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                  child: NextSongsList(
                                    playlist,
                                    currentIndex,
                                    _playNextSong,
                                    _updateSongList,
                                    true
                                  )),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Close'),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text('Show All Songs'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return Container(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                  child: NextSongsList(
                                    playlist,
                                    currentIndex,
                                    _playNextSong,
                                    _updateSongList,
                                    false
                                  )),
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Close'),
                              ),
                              SizedBox(height: 10),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Text('Show Next Songs'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
