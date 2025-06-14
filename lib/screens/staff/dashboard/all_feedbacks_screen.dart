import 'dart:convert';

import 'package:delivery_now_app/models/delivery_model.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

class AllFeedbacksScreen extends StatefulWidget {
  final List<DeliveryModel> deliveries;

  const AllFeedbacksScreen({super.key, required this.deliveries});

  @override
  State<AllFeedbacksScreen> createState() => _AllFeedbacksScreenState();
}

class _AllFeedbacksScreenState extends State<AllFeedbacksScreen> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final Map<String, bool> _isPlayingMap = {};
  bool _isPlayerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    for (var delivery in widget.deliveries) {
      _isPlayingMap[delivery.id] = false;
    }
  }

  Future<void> _initializePlayer() async {
    await _player.openPlayer();
    setState(() {
      _isPlayerInitialized = true;
    });
  }

  Future<void> _playAudio(String base64Audio, String deliveryId) async {
    if (!_isPlayerInitialized) return;
    try {
      await _stopAudio();
      final bytes = base64Decode(base64Audio);
      await _player.startPlayer(
        fromDataBuffer: bytes,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlayingMap[deliveryId] = false;
          });
        },
      );
      setState(() {
        _isPlayingMap[deliveryId] = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  Future<void> _stopAudio() async {
    if (!_isPlayerInitialized) return;
    try {
      await _player.stopPlayer();
      setState(() {
        _isPlayingMap.updateAll((key, value) => false);
      });
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedbackList =
        widget.deliveries.where((d) => d.voiceFeedback != null).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceColor,
        surfaceTintColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimaryColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Voice Feedback',
          style: TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  Icons.headphones_rounded,
                  color: AppColors.textSecondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${feedbackList.length}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: feedbackList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.mic_off_rounded,
                      color: AppColors.textSecondaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Voice Feedback',
                    style: TextStyle(
                      color: AppColors.textPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Voice feedback will appear here once\ncustomers leave audio reviews',
                    style: TextStyle(
                      color: AppColors.textSecondaryColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final delivery = feedbackList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: modernFeedbackCard(
                    delivery.customerName,
                    delivery.stars,
                    delivery.voiceFeedbackText,
                    isPlaying: _isPlayingMap[delivery.id] ?? false,
                    onPlay: () =>
                        _playAudio(delivery.voiceFeedback!, delivery.id),
                    onStop: _stopAudio,
                  ),
                );
              },
            ),
    );
  }
}

Widget modernFeedbackCard(
  String customerName,
  double? stars,
  String? voiceFeedbackText, {
  required bool isPlaying,
  required VoidCallback onPlay,
  required VoidCallback onStop,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.borderColor,
        width: 1,
      ),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textSecondaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      color: Color(0xFFE5E5E7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.mic_rounded,
                        color: AppColors.successColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Voice Feedback',
                        style: TextStyle(
                          color: AppColors.textSecondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Rating Stars
            if (stars != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStarBackgroundColor(stars),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: _getStarColor(stars),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stars.toStringAsFixed(1),
                      style: TextStyle(
                        color: _getStarColor(stars),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        // Voice Feedback Text
        if (voiceFeedbackText != null && voiceFeedbackText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderColor,
                width: 1,
              ),
            ),
            child: Text(
              voiceFeedbackText,
              style: TextStyle(
                color: AppColors.textPrimaryColor,
                fontSize: 14,
                height: 1.5,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],

        // Audio Control
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPlaying ? AppColors.infoColor : AppColors.borderColor,
              width: isPlaying ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isPlaying ? onStop : onPlay,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? AppColors.infoColor
                            : AppColors.borderColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.textPrimaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPlaying
                                ? 'Playing Audio...'
                                : 'Tap to Play Audio',
                            style: TextStyle(
                              color: AppColors.textPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPlaying
                                ? 'Tap to stop'
                                : 'Voice feedback recording',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.waving_hand_rounded,
                      color: isPlaying
                          ? AppColors.infoColor
                          : AppColors.textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

Color _getStarBackgroundColor(double stars) {
  if (stars >= 4.0) return AppColors.successColor.withOpacity(0.1);
  if (stars >= 3.0) return AppColors.warningColor.withOpacity(0.1);
  return AppColors.errorColor.withOpacity(0.1);
}

Color _getStarColor(double stars) {
  if (stars >= 4.0) return AppColors.successColor;
  if (stars >= 3.0) return AppColors.warningColor;
  return AppColors.errorColor;
}
