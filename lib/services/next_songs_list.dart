import 'package:flutter/material.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class NextSongsList extends StatefulWidget {
  final List<Video> playlist;
  final int currentIndex;
  final Function(int) onSongSelected;
  final VoidCallback onSongChange;
  final bool showAll;

  NextSongsList(
      this.playlist, this.currentIndex, this.onSongSelected, this.onSongChange, this.showAll,
      {Key? key})
      : super(key: key);

  @override
  State<NextSongsList> createState() => _NextSongsListState();
}

class _NextSongsListState extends State<NextSongsList> {
  @override
  Widget build(BuildContext context) {
    if (widget.playlist.isEmpty) {
      return Container();
    } else if (!widget.showAll) {
      return ListView.builder(
        itemCount: widget.playlist.length - widget.currentIndex - 1,
        itemBuilder: (context, index) {
          final songIndex = widget.currentIndex + 1 + index;
          return ListTile(
            title: Text(widget.playlist[songIndex].title),
            onTap: () {
              widget.onSongSelected(songIndex);
              widget.onSongChange();
            },
          );
        },
      );
    } else {
      return ListView.builder(
        itemCount: widget.playlist.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(widget.playlist[index].title),
            onTap: () {
              widget.onSongSelected(index);
              widget.onSongChange();
            },
          );
        },
      );
    }
  }
}
