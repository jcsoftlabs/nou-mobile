import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../constants/api_constants.dart';

class GlobalMiniPlayer extends StatelessWidget {
  const GlobalMiniPlayer({super.key});

  Widget _buildDefaultPodcastImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.mic,
        color: Colors.red,
        size: 25,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, audioService, child) {
        if (audioService.currentPodcast == null) {
          return const SizedBox.shrink();
        }

        final podcast = audioService.currentPodcast!;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barre de progression
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  activeTrackColor: Colors.red,
                  inactiveTrackColor: Colors.grey.shade300,
                  thumbColor: Colors.red,
                ),
                child: Slider(
                  value: audioService.currentPosition.inSeconds.toDouble(),
                  max: audioService.totalDuration.inSeconds.toDouble() > 0
                      ? audioService.totalDuration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) async {
                    await audioService.seek(Duration(seconds: value.toInt()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    // Image du podcast
                    if (podcast.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          podcast.imageUrl!.startsWith('/')
                              ? ApiConstants.baseUrl + podcast.imageUrl!
                              : podcast.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultPodcastImage(),
                        ),
                      )
                    else
                      _buildDefaultPodcastImage(),
                    const SizedBox(width: 12),
                    // Infos du podcast
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            podcast.titre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${audioService.formatDuration(audioService.currentPosition)} / ${audioService.formatDuration(audioService.totalDuration)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contrôles
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () async {
                        await audioService.seekBackward(const Duration(seconds: 10));
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        audioService.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 40,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        if (audioService.isPlaying) {
                          await audioService.pause();
                        } else {
                          await audioService.resume();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () async {
                        await audioService.seekForward(const Duration(seconds: 10));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
