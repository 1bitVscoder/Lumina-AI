import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../core/providers/update_provider.dart';
import 'glass_container.dart';

class UpdatePromptDialog extends ConsumerWidget {
  const UpdatePromptDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateProvider);
    final updateNotifier = ref.read(updateProvider.notifier);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;

    if (updateState.status == UpdateStatus.idle || 
        updateState.status == UpdateStatus.noUpdate || 
        updateState.status == UpdateStatus.checking) {
      return const SizedBox.shrink();
    }

    final info = updateState.updateInfo;
    if (info == null) return const SizedBox.shrink();

    return WillPopScope(
      onWillPop: () async => updateState.status != UpdateStatus.downloading,
      child: Stack(
        children: [
          // Semi-transparent blurred backdrop overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: updateState.status != UpdateStatus.downloading 
                  ? () => updateNotifier.dismissUpdate() 
                  : null,
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LuminaSpacing.xl),
              child: Hero(
                tag: 'update_prompt',
                child: Material(
                  color: Colors.transparent,
                  child: GlassContainer(
                    blur: 24,
                    opacity: isDarkMode ? 0.22 : 0.65,
                    borderRadius: BorderRadius.circular(LuminaRadius.card),
                    border: Border.all(
                      color: isDarkMode ? const Color(0x2BFFFFFF) : const Color(0x1F000000),
                      width: 1.2,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(LuminaSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(LuminaSpacing.sm),
                                decoration: BoxDecoration(
                                  color: LuminaColors.accentAmber.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.system_update_rounded,
                                  color: LuminaColors.accentAmber,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: LuminaSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New Update Available',
                                      style: GoogleFonts.lora(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: primaryTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      '${info.currentVersion} ➔ ${info.latestVersion}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: LuminaColors.accentAmber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: LuminaSpacing.lg),

                          // Release Notes Header
                          Text(
                            'What\'s New:',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 2.0),

                          // Release Notes content
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            width: double.infinity,
                            padding: const EdgeInsets.all(LuminaSpacing.md),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(LuminaRadius.card - 4),
                              border: Border.all(
                                color: isDarkMode ? const Color(0x14FFFFFF) : const Color(0x0A000000),
                              ),
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Text(
                                  info.releaseNotes,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: LuminaSpacing.xl),

                          // Downloading progress visualizer
                          if (updateState.status == UpdateStatus.downloading) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: updateState.downloadProgress,
                                    backgroundColor: isDarkMode ? const Color(0x1AFFFFFF) : const Color(0x0F000000),
                                    valueColor: const AlwaysStoppedAnimation<Color>(LuminaColors.accentAmber),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(height: LuminaSpacing.xs),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Downloading release...',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                    Text(
                                      '${(updateState.downloadProgress * 100).toStringAsFixed(0)}%',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: LuminaColors.accentAmber,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: LuminaSpacing.lg),
                          ],

                          // Error message if update fails
                          if (updateState.status == UpdateStatus.error) ...[
                            Text(
                              updateState.errorMessage ?? 'An error occurred during update.',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: LuminaColors.accentRed,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: LuminaSpacing.md),
                          ],

                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // "Later" / Dismiss Button
                              if (updateState.status != UpdateStatus.downloading && 
                                  updateState.status != UpdateStatus.downloadSuccess)
                                TextButton(
                                  onPressed: () => updateNotifier.dismissUpdate(),
                                  child: Text(
                                    'Later',
                                    style: GoogleFonts.dmSans(
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: LuminaSpacing.md),

                              // Dynamic primary action button
                              _buildPrimaryButton(context, updateState, updateNotifier),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context, UpdateState state, UpdateNotifier notifier) {
    String label = 'Download & Install';
    VoidCallback? onPressed = () => notifier.startDownload();
    Color btnColor = LuminaColors.accentAmber;
    Color txtColor = Colors.black;

    if (state.status == UpdateStatus.downloading) {
      label = 'Downloading...';
      onPressed = null;
    } else if (state.status == UpdateStatus.downloadSuccess) {
      label = 'Install & Restart';
      onPressed = () => notifier.installUpdate();
      btnColor = LuminaColors.accentGreen;
      txtColor = Colors.white;
    } else if (state.status == UpdateStatus.error) {
      label = 'Retry';
      onPressed = () => notifier.startDownload();
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: btnColor,
        foregroundColor: txtColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuminaRadius.button),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LuminaSpacing.lg,
          vertical: LuminaSpacing.md,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
