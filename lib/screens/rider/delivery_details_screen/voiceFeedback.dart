import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'dart:math' show sin, pi;

class VoiceFeedbackScreen extends StatefulWidget {
  final String deliveryId;

  const VoiceFeedbackScreen({super.key, required this.deliveryId});

  @override
  State<VoiceFeedbackScreen> createState() => _VoiceFeedbackScreenState();
}

class _VoiceFeedbackScreenState extends State<VoiceFeedbackScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  Timer? _timer;

  late AnimationController _rippleAnimationController;
  late AnimationController _micAnimationController;
  late AnimationController _fadeAnimationController;
  late AnimationController _scaleAnimationController;

  String? _currentProcess;
  final FirebaseServices _firebaseServices = FirebaseServices();

  final AudioPlayer _player = AudioPlayer();
  bool _isLoading = false;
  bool _hasExistingFeedback = false;
  String? _existingAudioPath;

  @override
  void initState() {
    super.initState();

    _rippleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkExistingFeedback();
  }

  Future<void> _checkExistingFeedback() async {
    setState(() => _isLoading = true);
    try {
      final delivery =
          await _firebaseServices.getDeliveryById(widget.deliveryId);
      if (delivery != null &&
          delivery.voiceFeedback != null &&
          delivery.voiceFeedback!.isNotEmpty) {
        setState(() {
          _hasExistingFeedback = true;
        });
        _fadeAnimationController.forward();
        _scaleAnimationController.forward();
      } else {
        _fadeAnimationController.forward();
      }
    } catch (e) {
      showToast('Error checking existing feedback: $e', AppColors.redColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rippleAnimationController.dispose();
    _micAnimationController.dispose();
    _fadeAnimationController.dispose();
    _scaleAnimationController.dispose();
    _player.dispose();
    _cleanupTempFiles();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    if (_existingAudioPath != null) {
      try {
        final file = File(_existingAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors
      }
    }
  }

  Future<void> _stopPlayback() async {
    if (_isPlaying) {
      await _player.stop();
      setState(() {
        _isPlaying = false;
      });
    }
  }

  Future<void> _playExistingFeedback() async {
    if (_isPlaying) {
      await _stopPlayback();
      return;
    }

    try {
      final delivery =
          await _firebaseServices.getDeliveryById(widget.deliveryId);
      if (delivery != null &&
          delivery.voiceFeedback != null &&
          delivery.voiceFeedback!.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        _existingAudioPath = '${tempDir.path}/existing_feedback.wav';
        final File tempFile = File(_existingAudioPath!);

        final bytes = base64Decode(delivery.voiceFeedback!);
        await tempFile.writeAsBytes(bytes);

        await _player.setFilePath(_existingAudioPath!);
        setState(() {
          _isLoading = false;
          _isPlaying = true;
        });

        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _stopPlayback();
          }
        });

        await _player.play();
      } else {
        showToast('No existing feedback found', AppColors.redColor);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      showToast('Error playing existing feedback: $e', AppColors.redColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: AppColors.whiteColor,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _currentProcess ?? 'Loading voice feedback...',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFeedbackState() {
    return FadeTransition(
      opacity: _fadeAnimationController,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardColor.withOpacity(0.9),
              AppColors.surfaceColor.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Animated Icon Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.violetColor.withOpacity(0.2),
                    AppColors.primaryColor.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: AnimatedBuilder(
                animation: _rippleAnimationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withOpacity(
                            0.3 * (1 - _rippleAnimationController.value),
                          ),
                          blurRadius: 20 * _rippleAnimationController.value,
                          spreadRadius: 10 * _rippleAnimationController.value,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mic_none_rounded,
                        size: 50,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'No Voice Feedback Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'This delivery doesn\'t have any voice feedback recorded yet. Voice feedback helps improve our service quality.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryColor,
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Decorative Elements
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDecoIcon(
                    Icons.record_voice_over_rounded, AppColors.tealColor),
                const SizedBox(width: 20),
                _buildDecoIcon(Icons.feedback_rounded, AppColors.violetColor),
                const SizedBox(width: 20),
                _buildDecoIcon(Icons.star_rounded, AppColors.primaryColor),
              ],
            ),

            const SizedBox(height: 24),

            // Action hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Feedbacks will appear once recorded',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecoIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  Widget _buildExistingFeedbackCard() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(
          parent: _scaleAnimationController,
          curve: Curves.elasticOut,
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimationController,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardColor,
                AppColors.surfaceColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 25,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 24,
                        color: AppColors.whiteColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Feedback Available',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap play to listen to the recorded feedback',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Audio Visualizer (Decorative)
                Container(
                  height: 60,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      20,
                      (index) => AnimatedBuilder(
                        animation: _rippleAnimationController,
                        builder: (context, child) {
                          final delay = index * 0.1;
                          final animValue =
                              (_rippleAnimationController.value + delay) % 1.0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 3,
                            height: _isPlaying
                                ? 20 + (20 * sin(animValue * 2 * pi))
                                : 10 + (index % 3) * 8,
                            decoration: BoxDecoration(
                              color: _isPlaying
                                  ? AppColors.primaryColor
                                  : AppColors.primaryColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModernControlButton(
                      onPressed: _playExistingFeedback,
                      icon: _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: AppColors.primaryColor,
                      text: _isPlaying ? "Pause" : "Play",
                      isActive: true,
                    ),
                    _buildModernControlButton(
                      onPressed: _isPlaying ? _stopPlayback : null,
                      icon: Icons.stop_rounded,
                      color: AppColors.errorColor,
                      text: "Stop",
                      isActive: _isPlaying,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required Color color,
    required String text,
    required bool isActive,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(25),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color,
                          color.withOpacity(0.8),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          AppColors.grey600.withOpacity(0.3),
                          AppColors.grey700.withOpacity(0.3),
                        ],
                      ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isActive
                      ? color.withOpacity(0.5)
                      : AppColors.grey600.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isActive ? AppColors.whiteColor : AppColors.grey600,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isActive ? color : AppColors.grey600,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppColors.textPrimaryColor,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Feedback',
                            style: TextStyle(
                              color: AppColors.textPrimaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Delivery #${widget.deliveryId.substring(0, 8)}',
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            if (_hasExistingFeedback)
                              _buildExistingFeedbackCard()
                            else
                              _buildNoFeedbackState(),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
