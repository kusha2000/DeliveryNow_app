import 'package:delivery_now_app/utils/show_toast.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'dart:convert';
import 'dart:typed_data';

class CustomerSignaturePad extends StatefulWidget {
  final Function(String) onSave;
  final String? existingSignature;

  const CustomerSignaturePad({
    super.key,
    required this.onSave,
    this.existingSignature,
  });

  @override
  _CustomerSignaturePadState createState() => _CustomerSignaturePadState();
}

class _CustomerSignaturePadState extends State<CustomerSignaturePad> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 4,
    penColor: Colors.black,
  );

  bool _isShowingExisting = false;

  @override
  void initState() {
    super.initState();
    // Check if we have an existing signature to display
    if (widget.existingSignature != null &&
        widget.existingSignature!.isNotEmpty) {
      _isShowingExisting = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_isShowingExisting && widget.existingSignature != null) {
      widget.onSave(widget.existingSignature!);
      Navigator.pop(context, widget.existingSignature);
      return;
    }

    if (_controller.isEmpty) {
      showToast('Please provide a signature first', AppColors.errorColor);
      return;
    }

    final Uint8List? data = await _controller.toPngBytes();
    if (data != null) {
      final String base64Image = base64Encode(data);
      widget.onSave(base64Image);
      showToast('Signature Added Successfully', AppColors.successColor);
    }
  }

  void _clearAndStartNew() {
    setState(() {
      _isShowingExisting = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modern header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isShowingExisting ? Icons.preview : Icons.edit,
                  color: AppColors.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isShowingExisting
                          ? 'Existing Signature'
                          : 'Digital Signature',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isShowingExisting
                          ? 'Your saved signature'
                          : 'Please sign in the area below',
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

          // Modern signature container with glassmorphism effect
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.borderColor.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightShadowColor,
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _isShowingExisting && widget.existingSignature != null
                  ? Container(
                      height: 220,
                      width: double.infinity,
                      color: AppColors.whiteColor,
                      child: Image.memory(
                        base64Decode(widget.existingSignature!),
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Signature(
                        controller: _controller,
                        height: 220,
                        backgroundColor: AppColors.whiteColor,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),

          // Modern action buttons
          Row(
            children: [
              // Clear/New Signature Button
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.grey700.withOpacity(0.8),
                        AppColors.grey600.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightShadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isShowingExisting
                        ? _clearAndStartNew
                        : _controller.clear,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isShowingExisting ? Icons.add : Icons.clear,
                          color: AppColors.whiteColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isShowingExisting ? 'New' : 'Clear',
                          style: const TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Submit Button
              Expanded(
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveSignature,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.whiteColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Submit',
                          style: TextStyle(
                            color: AppColors.whiteColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
