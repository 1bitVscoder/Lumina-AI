import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/theme.dart';
import 'voice_input_button.dart';
import '../../../shared/widgets/glass_container.dart';

class ChatInputBar extends StatefulWidget {
  final Function(String text, String? imageBase64) onSend;
  final VoidCallback? onAttach;
  final bool enabled;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onAttach,
    this.enabled = true,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;
  late AnimationController _sendBounceController;
  late Animation<double> _sendScaleAnimation;

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImageFile;
  String? _compressedBase64Image;
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _sendBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _sendScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.9), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 0.9, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _sendBounceController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _sendBounceController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    _updateCanSend(hasText);
  }

  void _updateCanSend(bool hasText) {
    final canSendNow = hasText || _compressedBase64Image != null;
    if (canSendNow != _canSend) {
      setState(() {
        _canSend = canSendNow;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return;
      
      setState(() {
        _isCompressing = true;
        _selectedImageFile = pickedFile;
      });
      _updateCanSend(_controller.text.trim().isNotEmpty);

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        pickedFile.path,
        minWidth: 512,
        minHeight: 512,
        quality: 85,
      );

      if (compressedBytes != null) {
        setState(() {
          _compressedBase64Image = base64Encode(compressedBytes);
          _isCompressing = false;
        });
      } else {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _compressedBase64Image = base64Encode(bytes);
          _isCompressing = false;
        });
      }
      _updateCanSend(_controller.text.trim().isNotEmpty);
    } catch (e) {
      debugPrint("Error picking/compressing image: $e");
      setState(() {
        _isCompressing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load image")),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImageFile = null;
      _compressedBase64Image = null;
    });
    _updateCanSend(_controller.text.trim().isNotEmpty);
  }

  void _handleSend() {
    final text = _controller.text.trim();
    final image = _compressedBase64Image;
    if (text.isEmpty && image == null) return;

    _sendBounceController.forward(from: 0.0);
    widget.onSend(text, image);
    
    _controller.clear();
    _clearImage();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final inputBgColor = isDarkMode ? LuminaColors.backgroundDark : LuminaColors.inputBackground;
    final textColor = widget.enabled 
        ? (isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary)
        : (isDarkMode ? LuminaColors.textSecDark : LuminaColors.disabled);
    final hintColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textTimestamp;

    return GlassContainer(
      blur: 20.0,
      opacity: isDarkMode ? 0.15 : 0.45,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.symmetric(
        horizontal: LuminaSpacing.sm,
        vertical: LuminaSpacing.sm,
      ),
      border: Border(
        top: BorderSide(
          color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
          width: 0.8,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Attached Image Preview Bubble
            if (_selectedImageFile != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: LuminaSpacing.md, bottom: LuminaSpacing.sm),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.topRight,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
                              width: 0.8,
                            ),
                            image: DecorationImage(
                              image: FileImage(File(_selectedImageFile!.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: _clearImage,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: LuminaSpacing.md),
                    if (_isCompressing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: LuminaColors.accentAmber),
                      )
                    else
                      Text(
                        "Image attached",
                        style: GoogleFonts.dmSans(
                          fontSize: LuminaTypography.sizeCaption,
                          color: LuminaColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            
            // Text Entry and Actions Row
            Row(
              children: [
                // Attachment Icon
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: widget.enabled 
                        ? (isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary)
                        : LuminaColors.disabled,
                    size: 24,
                  ),
                  onPressed: widget.enabled ? _pickImage : null,
                ),
                
                // Text Input Pill
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _focusNode.requestFocus();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: inputBgColor,
                        borderRadius: BorderRadius.circular(LuminaRadius.input),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: LuminaSpacing.md),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLines: 5,
                              minLines: 1,
                              enabled: widget.enabled,
                              style: GoogleFonts.dmSans(
                                fontSize: LuminaTypography.sizeBody,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: widget.enabled ? "Type something..." : "Locked",
                                hintStyle: GoogleFonts.dmSans(color: hintColor),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _handleSend(),
                            ),
                          ),
                        
                        // Voice Mic Icon (Replaced with VoiceInputButton)
                        if (widget.enabled)
                          VoiceInputButton(
                            onResult: (transcript) {
                              setState(() {
                                _controller.text = transcript;
                                _controller.selection = TextSelection.fromPosition(
                                  TextPosition(offset: _controller.text.length),
                                );
                              });
                            },
                          )
                        else
                          const IconButton(
                            icon: Icon(
                              Icons.mic_none_outlined,
                              color: LuminaColors.disabled,
                              size: 22,
                            ),
                            onPressed: null,
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.all(8),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
                
                const SizedBox(width: LuminaSpacing.sm),

                // Send Button with tap bounce animation
                ScaleTransition(
                  scale: _sendScaleAnimation,
                  child: GestureDetector(
                    onTap: (_canSend && widget.enabled) ? _handleSend : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (_canSend && widget.enabled) ? LuminaColors.accentAmber : LuminaColors.disabled,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
