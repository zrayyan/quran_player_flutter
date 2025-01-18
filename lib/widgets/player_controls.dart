import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/audio_service.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player Info Header
            _buildPlayerHeader(context),
            const Divider(height: 24),

            // Playback Status
            StreamBuilder<AudioServiceState>(
              stream: context.read<AudioService>().stateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                return Column(
                  children: [
                    Text(
                      state != null
                          ? 'Ayah ${state.currentAyahNumber} of ${state.totalAyahs}'
                          : 'No ayah selected',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (state?.isBuffering ?? false)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Control Buttons
            _buildControlButtons(context),

            const SizedBox(height: 16),

            // Progress Indicator
            _buildProgressIndicator(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text(
                  'UTC: 2025-01-18 19:21:13',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(
                  'User: zrayyan',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        StreamBuilder<AudioServiceState>(
          stream: context.read<AudioService>().stateStream,
          builder: (context, snapshot) {
            final state = snapshot.data;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(state),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(state),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          context,
          Icons.skip_previous,
          'Previous Ayah',
          () => context.read<AudioService>().seekToPreviousAyah(),
        ),
        const SizedBox(width: 16),
        StreamBuilder<AudioServiceState>(
          stream: context.read<AudioService>().stateStream,
          builder: (context, snapshot) {
            final isPlaying = snapshot.data?.isPlaying ?? false;
            final isBuffering = snapshot.data?.isBuffering ?? false;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildControlButton(
                  context,
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  isPlaying ? 'Pause' : 'Play',
                  isBuffering
                      ? null
                      : () {
                          final audioService = context.read<AudioService>();
                          if (isPlaying) {
                            audioService.pause();
                          } else {
                            audioService.resume();
                          }
                        },
                ),
                const SizedBox(width: 8),
                _buildControlButton(
                  context,
                  Icons.stop,
                  'Stop',
                  () => context.read<AudioService>().stop(),
                ),
              ],
            );
          },
        ),
        const SizedBox(width: 16),
        _buildControlButton(
          context,
          Icons.skip_next,
          'Next Ayah',
          () => context.read<AudioService>().seekToNextAyah(),
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback? onPressed,
  ) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 24,
              color: onPressed == null
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return StreamBuilder<AudioServiceState>(
      stream: context.read<AudioService>().stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final position = state?.position ?? Duration.zero;
        final duration = state?.duration ?? Duration.zero;

        if (duration == Duration.zero) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            LinearProgressIndicator(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0.0,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Color _getStatusColor(AudioServiceState? state) {
    if (state == null) return Colors.grey;
    if (state.isBuffering) return Colors.orange;
    if (state.isPlaying) return Colors.green;
    return Colors.grey;
  }

  String _getStatusText(AudioServiceState? state) {
    if (state == null) return 'NOT READY';
    if (state.isBuffering) return 'BUFFERING';
    if (state.isPlaying) return 'PLAYING';
    return 'STOPPED';
  }
}
