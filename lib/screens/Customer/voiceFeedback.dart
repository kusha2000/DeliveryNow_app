import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:delivery_now_app/services/firebase_services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:record/record.dart';

class CustomerVoiceFeedbackScreen extends StatefulWidget {
  final String deliveryId;

  const CustomerVoiceFeedbackScreen({super.key, required this.deliveryId});

  @override
  State<CustomerVoiceFeedbackScreen> createState() =>
      _CustomerVoiceFeedbackScreenState();
}

class _CustomerVoiceFeedbackScreenState
    extends State<CustomerVoiceFeedbackScreen> with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;

  late AnimationController _rippleAnimationController;
  late Animation<double> _rippleAnimation;

  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  String? _recordedAudioPath;
  String? _recordedAudioBase64;
  String? _currentProcess;
  final FirebaseServices _firebaseServices = FirebaseServices();

  final AudioRecorder _recorder = AudioRecorder();
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

    _rippleAnimation = Tween<double>(begin: 0.8, end: 1.8).animate(
      CurvedAnimation(
        parent: _rippleAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _micAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _micAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initPlatformState();
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
      }
    } catch (e) {
      showToast('Error checking existing feedback: $e', AppColors.errorColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initPlatformState() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      showToast('Microphone permission is required to record voice feedback',
          AppColors.errorColor);
      return;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rippleAnimationController.dispose();
    _micAnimationController.dispose();
    _pulseAnimationController.dispose();
    _recorder.stop();
    _player.dispose();
    _cleanupTempFiles();
    super.dispose();
  }

  Future<void> _cleanupTempFiles() async {
    if (_recordedAudioPath != null) {
      try {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore file deletion errors
      }
    }

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

  void _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      if (_isPlaying) {
        await _stopPlayback();
      }
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _recordedAudioPath = '${tempDir.path}/voice_feedback.wav';

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
      );
      await _recorder.start(
        config,
        path: _recordedAudioPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = 0;
        _hasRecording = false;
        _currentProcess = null;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingDuration++;
        });
      });

      _micAnimationController.repeat(reverse: true);
    } catch (e) {
      showToast('Error starting recording: $e', AppColors.errorColor);
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stop();

      _timer?.cancel();
      _micAnimationController.stop();
      _rippleAnimationController.stop();

      setState(() {
        _isRecording = false;
      });

      if (_recordedAudioPath != null) {
        final File audioFile = File(_recordedAudioPath!);
        if (await audioFile.exists()) {
          final bytes = await audioFile.readAsBytes();
          _recordedAudioBase64 = base64Encode(bytes);

          setState(() {
            _hasRecording = true;
          });
        }
      }
    } catch (e) {
      showToast('Error stopping recording: $e', AppColors.errorColor);
    }
  }

  Future<void> _playRecording() async {
    if (_isPlaying) {
      await _stopPlayback();
      return;
    }

    try {
      if (_recordedAudioPath != null &&
          File(_recordedAudioPath!).existsSync()) {
        setState(() {
          _isPlaying = true;
        });

        await _player.setFilePath(_recordedAudioPath!);
        _player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _stopPlayback();
          }
        });

        await _player.play();
      }
    } catch (e) {
      showToast('Error playing recording: $e', AppColors.errorColor);
      setState(() {
        _isPlaying = false;
      });
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

  Future<void> _deleteRecording() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => _buildModernDialog(
        title: 'Delete Recording',
        content: 'Are you sure you want to delete this recording?',
        confirmText: 'Delete',
        confirmColor: AppColors.errorColor,
      ),
    );

    if (confirmDelete != true) return;

    setState(() => _isLoading = true);

    try {
      if (_isPlaying) {
        await _stopPlayback();
      }

      setState(() {
        _hasRecording = false;
        _recordedAudioBase64 = null;
        _currentProcess = null;
      });

      if (_recordedAudioPath != null) {
        final file = File(_recordedAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      showToast('Recording deleted', AppColors.successColor);
    } catch (e) {
      showToast('Error deleting recording: $e', AppColors.errorColor);
    } finally {
      setState(() => _isLoading = false);
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
        showToast('No existing feedback found', AppColors.errorColor);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      showToast('Error playing existing feedback: $e', AppColors.errorColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExistingFeedback() async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => _buildModernDialog(
        title: 'Delete Existing Feedback',
        content:
            'Are you sure you want to delete the existing feedback? This action cannot be undone.',
        confirmText: 'Delete',
        confirmColor: AppColors.errorColor,
      ),
    );

    if (confirmDelete != true) return;

    setState(() => _isLoading = true);

    try {
      if (_isPlaying) {
        await _stopPlayback();
      }

      await _firebaseServices.updateDeliveryVoiceFeedback(
        deliveryId: widget.deliveryId,
        voiceFeedbackBase64: '',
      );

      if (_existingAudioPath != null) {
        final file = File(_existingAudioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _hasExistingFeedback = false;
        _currentProcess = null;
      });

      showToast('Feedback deleted successfully', AppColors.successColor);
    } catch (e) {
      showToast('Error deleting feedback: $e', AppColors.errorColor);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (_recordedAudioBase64 == null) {
      showToast('Please record a voice feedback first', AppColors.warningColor);
      return;
    }

    setState(() {
      _isLoading = true;
      _currentProcess = 'Uploading audio...';
    });

    try {
      // Save feedback to Firebase
      await _firebaseServices.updateDeliveryVoiceFeedback(
        deliveryId: widget.deliveryId,
        voiceFeedbackBase64: _recordedAudioBase64!,
      );

      setState(() {
        _hasExistingFeedback = true;
        _hasRecording = false;
      });

      showToast('Voice feedback saved successfully!', AppColors.successColor);
    } catch (e) {
      showToast('Error processing feedback: $e', AppColors.errorColor);
    } finally {
      setState(() {
        _isLoading = false;
        _currentProcess = null;
      });
    }
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildModernDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.borderColor, width: 1),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        content,
        style: const TextStyle(
          color: AppColors.textSecondaryColor,
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
        ),
        Container(
          margin: const EdgeInsets.only(left: 8),
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: AppColors.whiteColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(confirmText,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(bool isExistingFeedback) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceColor,
            AppColors.cardColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.borderColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryColor.withOpacity(0.2),
                        AppColors.primaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3)),
                  ),
                  child: Icon(
                    isExistingFeedback
                        ? Icons.history_rounded
                        : Icons.mic_rounded,
                    size: 24,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isExistingFeedback
                            ? "Existing Voice Feedback"
                            : "Your Recording",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isExistingFeedback
                            ? "Previously submitted feedback"
                            : "Ready for analysis",
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.transparentColor,
                    AppColors.borderColor,
                    AppColors.transparentColor,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildModernControlButton(
                  onPressed: isExistingFeedback
                      ? _playExistingFeedback
                      : _playRecording,
                  icon: _isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: _isPlaying ? "Pause" : "Play",
                  color: AppColors.primaryColor,
                  isActive: _isPlaying,
                ),
                _buildModernControlButton(
                  onPressed: _isPlaying ? _stopPlayback : null,
                  icon: Icons.stop_rounded,
                  label: "Stop",
                  color: AppColors.grey600,
                  isActive: false,
                ),
                _buildModernControlButton(
                  onPressed: _isPlaying
                      ? null
                      : isExistingFeedback
                          ? _deleteExistingFeedback
                          : _deleteRecording,
                  icon: Icons.delete_outline_rounded,
                  label: "Delete",
                  color: AppColors.errorColor,
                  isActive: false,
                ),
              ],
            ),

            // Submit Button for new recordings
            if (!isExistingFeedback) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor, AppColors.violetColor],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isPlaying || _isLoading ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.transparentColor,
                    shadowColor: AppColors.transparentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_rounded,
                          size: 22, color: AppColors.whiteColor),
                      SizedBox(width: 12),
                      Text(
                        'Submit Feedback',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isActive,
  }) {
    final bool isEnabled = onPressed != null;

    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: isEnabled && isActive
                ? LinearGradient(colors: [color, color.withOpacity(0.7)])
                : null,
            color: isEnabled && !isActive
                ? color.withOpacity(0.15)
                : AppColors.grey800.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isEnabled ? color.withOpacity(0.5) : AppColors.grey700,
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: AppColors.transparentColor,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(32),
              child: Icon(
                icon,
                color: isEnabled
                    ? (isActive ? AppColors.whiteColor : color)
                    : AppColors.grey600,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? color : AppColors.grey600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingInterface() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Recording Duration
          if (_isRecording) ...[
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.6 + (0.4 * _pulseAnimation.value),
                  child: Text(
                    _formatDuration(_recordingDuration),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: AppColors.errorColor,
                      letterSpacing: 2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],

          // Recording Button with Ripple Effect
          Stack(
            alignment: Alignment.center,
            children: [
              // Ripple Effect
              if (_isRecording)
                AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 200 * _rippleAnimation.value,
                      height: 200 * _rippleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.errorColor.withOpacity(0.1),
                        border: Border.all(
                          color: AppColors.errorColor.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),

              // Main Recording Button
              ScaleTransition(
                scale: _isRecording
                    ? _micAnimation
                    : const AlwaysStoppedAnimation(1.0),
                child: GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isRecording
                            ? [
                                AppColors.errorColor,
                                AppColors.errorColor.withOpacity(0.8)
                              ]
                            : [AppColors.primaryColor, AppColors.violetColor],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                                  ? AppColors.errorColor
                                  : AppColors.primaryColor)
                              .withOpacity(0.4),
                          spreadRadius: 4,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: AppColors.whiteColor,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Status Text
          Text(
            _isRecording
                ? 'Recording in progress...'
                : _hasRecording
                    ? 'Recording complete'
                    : 'Tap the mic to start recording',
            style: TextStyle(
              fontSize: 18,
              color: _isRecording
                  ? AppColors.errorColor
                  : AppColors.textSecondaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Voice Feedback',
          style: TextStyle(
            color: AppColors.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  if (_currentProcess != null) ...[
                    Text(
                      _currentProcess!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Please wait...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Existing feedback display
                  if (_hasExistingFeedback) ...[
                    _buildPlaybackControls(true),
                    const SizedBox(height: 32),
                  ],

                  // New recording display
                  if (_hasRecording) ...[
                    _buildPlaybackControls(false),
                    const SizedBox(height: 32),
                  ],

                  // Recording interface
                  _buildRecordingInterface(),

                  // Help text when no recordings exist
                  if (!_hasRecording && !_hasExistingFeedback) ...[
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.borderColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 48,
                            color: AppColors.primaryColor.withOpacity(0.8),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Share Your Experience',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Press and hold the microphone button to record your feedback about this delivery experience.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
