import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/theme.dart';
import '../../../core/network.dart';
import '../../auth/providers/auth_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../../chat/providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../../../shared/widgets/glass_container.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;
  bool _isSavingName = false;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.aiName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _getArchetypeVibe(String archetype) {
    switch (archetype.toLowerCase()) {
      case 'venter':
        return "Venter (Always here to listen)";
      case 'analyst':
        return "Analyst (Logical & thoughtful)";
      case 'jester':
        return "Jester (Keeping it light & playful)";
      case 'seeker':
        return "Seeker (Deep & reflective)";
      case 'drifter':
        return "Drifter (Chill & spontaneous)";
      default:
        return archetype.isNotEmpty ? archetype : "Neutral Companion";
    }
  }

  Future<void> _saveCompanionName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    if (newName.length < 3 || newName.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name must be between 3 and 20 characters")),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSavingName = true;
    });

    try {
      final client = supabase.Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        // 1. Update database
        await client.from('users').update({
          'ai_name': newName,
        }).eq('google_uid', user.id);

        // 2. Update secure storage
        await ref.read(settingsProvider.notifier).setAiName(newName);

        // 3. Update global profile provider
        final oldProfile = ref.read(userProfileProvider);
        ref.read(userProfileProvider.notifier).updateProfile(
          oldProfile.copyWith(aiName: newName),
        );

        setState(() {
          _isEditingName = false;
        });
        
        messenger.showSnackBar(
          const SnackBar(content: Text("Companion renamed successfully!")),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text("Error renaming: $e")),
      );
    } finally {
      setState(() {
        _isSavingName = false;
      });
    }
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Clear Chat History?",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This will permanently delete all messages and conversations. This action cannot be undone.",
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: GoogleFonts.dmSans(color: Theme.of(context).brightness == Brightness.dark ? LuminaColors.textSecDark : LuminaColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Clear", style: GoogleFonts.dmSans(color: LuminaColors.accentRed, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(chatProvider.notifier).clearHistory();
              messenger.showSnackBar(
                const SnackBar(content: Text("Chat history cleared")),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Your Account?",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: LuminaColors.accentRed),
        ),
        content: Text(
          "This will permanently delete your profile, chat history, companion preferences, and account memory. This action is irreversible.",
          style: GoogleFonts.dmSans(),
        ),
        actions: [
          TextButton(
            child: Text("Cancel", style: GoogleFonts.dmSans(color: Theme.of(context).brightness == Brightness.dark ? LuminaColors.textSecDark : LuminaColors.textSecondary)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Delete Permanently", style: GoogleFonts.dmSans(color: LuminaColors.accentRed, fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              _executeDeleteAccount();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteAccount() async {
    // Show spinner overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: LuminaColors.accentAmber),
      ),
    );

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final dio = ref.read(dioProvider);
      
      // 1. Call delete account backend endpoint
      await dio.delete('/account');
      
      // 2. Clear secure storage
      await ref.read(settingsProvider.notifier).clearAll();
      
      // 3. Clear auth notifier (signout locally)
      await ref.read(authProvider.notifier).signOut();
      
      // 4. Pop loader and redirect to login
      if (mounted) {
        Navigator.pop(context); // Remove progress loader
        router.go('/login');
        messenger.showSnackBar(
          const SnackBar(content: Text("Account deleted successfully.")),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Remove progress loader
      messenger.showSnackBar(
        SnackBar(content: Text("Failed to delete account: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final primaryTextColor = isDarkMode ? LuminaColors.textPrimaryDark : LuminaColors.textPrimary;
    final secondaryTextColor = isDarkMode ? LuminaColors.textSecDark : LuminaColors.textSecondary;
    final cardBgColor = isDarkMode ? LuminaColors.surfaceDark : LuminaColors.surface;

    return Scaffold(
      backgroundColor: isDarkMode ? LuminaColors.backgroundDark : LuminaColors.background,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LuminaSpacing.md),
        child: Column(
          children: [
            // 1. PROFILE SECTION CARD
            GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(LuminaSpacing.md),
              opacity: isDarkMode ? 0.15 : 0.45,
              borderRadius: BorderRadius.circular(LuminaRadius.card),
              border: Border.all(
                color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
                width: 0.8,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: profile.avatarUrl.isNotEmpty 
                        ? NetworkImage(profile.avatarUrl) 
                        : null,
                    backgroundColor: LuminaColors.accentAmber,
                    child: profile.avatarUrl.isEmpty 
                        ? Text(
                            profile.displayName.isNotEmpty ? profile.displayName[0].toUpperCase() : 'G',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: LuminaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName.isNotEmpty ? profile.displayName : "Guest User",
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email.isNotEmpty ? profile.email : "Guest Account",
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuminaSpacing.md),

            // 2. YOUR AI SETTING CARD
            GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(LuminaSpacing.md),
              opacity: isDarkMode ? 0.15 : 0.45,
              borderRadius: BorderRadius.circular(LuminaRadius.card),
              border: Border.all(
                color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
                width: 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Companion",
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuminaColors.accentAmber,
                    ),
                  ),
                  const SizedBox(height: LuminaSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Companion Name",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                      ),
                      _isEditingName
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  height: 36,
                                  child: TextField(
                                    controller: _nameController,
                                    autofocus: true,
                                    style: GoogleFonts.dmSans(fontSize: 14, color: primaryTextColor),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: (_) => _saveCompanionName(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                _isSavingName
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: LuminaColors.accentAmber),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.check, color: LuminaColors.accentGreen, size: 20),
                                        onPressed: _saveCompanionName,
                                      ),
                              ],
                            )
                          : Row(
                              children: [
                                Text(
                                  profile.aiName,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, size: 16, color: secondaryTextColor),
                                  onPressed: () {
                                    setState(() {
                                      _isEditingName = true;
                                    });
                                  },
                                ),
                              ],
                            ),
                    ],
                  ),
                  Divider(color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Personality Vibe",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                      ),
                      Text(
                        _getArchetypeVibe(profile.archetype),
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuminaSpacing.md),

            // 3. APP PREFERENCES CARD
            GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(LuminaSpacing.md),
              opacity: isDarkMode ? 0.15 : 0.45,
              borderRadius: BorderRadius.circular(LuminaRadius.card),
              border: Border.all(
                color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
                width: 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Preferences",
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuminaColors.accentAmber,
                    ),
                  ),
                  const SizedBox(height: LuminaSpacing.sm),
                  
                  // Theme Mode Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "App Theme",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                      ),
                      DropdownButton<ThemeMode>(
                        value: settings.themeMode,
                        dropdownColor: cardBgColor,
                        style: GoogleFonts.dmSans(color: primaryTextColor, fontSize: 14),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text("System Default"),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text("Light Mode"),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text("Dark Mode"),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            settingsNotifier.setThemeMode(mode);
                          }
                        },
                      ),
                    ],
                  ),
                  Divider(color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider, height: 16),
                  
                  // Autoplay TTS Switch Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Auto-play voice readouts",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                      ),
                      Switch(
                        value: settings.autoplayTts,
                        activeThumbColor: LuminaColors.accentAmber,
                        activeTrackColor: LuminaColors.accentAmber.withAlpha(128),
                        onChanged: (val) {
                          settingsNotifier.setAutoplayTts(val);
                        },
                      ),
                    ],
                  ),
                  Divider(color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider, height: 16),

                  // Ambient Soundscape Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ambient Soundscape",
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: primaryTextColor,
                        ),
                      ),
                      DropdownButton<String>(
                        value: settings.soundscape,
                        dropdownColor: cardBgColor,
                        style: GoogleFonts.dmSans(color: primaryTextColor, fontSize: 14),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'none', child: Text("None")),
                          DropdownMenuItem(value: 'rain', child: Text("Cozy Rain 🌧️")),
                          DropdownMenuItem(value: 'fireplace', child: Text("Fireplace 🔥")),
                          DropdownMenuItem(value: 'lofi', child: Text("Cozy Lo-fi 🎵")),
                        ],
                        onChanged: (track) {
                          if (track != null) {
                            settingsNotifier.setSoundscape(track);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuminaSpacing.md),

            // 4. CHAT ACTIONS CARD
            GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(LuminaSpacing.md),
              opacity: isDarkMode ? 0.15 : 0.45,
              borderRadius: BorderRadius.circular(LuminaRadius.card),
              border: Border.all(
                color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
                width: 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chat Operations",
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuminaColors.accentAmber,
                    ),
                  ),
                  const SizedBox(height: LuminaSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Clear Chat History",
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.delete_sweep_outlined, color: LuminaColors.accentRed),
                    onTap: _showClearHistoryDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuminaSpacing.md),

            // 5. ACCOUNT OPERATIONS CARD
            GlassContainer(
              width: double.infinity,
              padding: const EdgeInsets.all(LuminaSpacing.md),
              opacity: isDarkMode ? 0.15 : 0.45,
              borderRadius: BorderRadius.circular(LuminaRadius.card),
              border: Border.all(
                color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider,
                width: 0.8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Account",
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuminaColors.accentAmber,
                    ),
                  ),
                  const SizedBox(height: LuminaSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Sign Out",
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: primaryTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(Icons.logout, color: secondaryTextColor),
                    onTap: () async {
                      final router = GoRouter.of(context);
                      await ref.read(authProvider.notifier).signOut();
                      router.go('/login');
                    },
                  ),
                  Divider(color: isDarkMode ? LuminaColors.dividerDark : LuminaColors.divider, height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Delete My Account",
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: LuminaColors.accentRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.no_accounts_outlined, color: LuminaColors.accentRed),
                    onTap: _showDeleteAccountDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: LuminaSpacing.xl),

            // ABOUT DETAILS SECTION
            Text(
              "Lumina v1.0.0",
              style: GoogleFonts.dmSans(
                fontSize: LuminaTypography.sizeCaption,
                color: secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Someone to talk to. Always.",
              style: GoogleFonts.dmSans(
                fontSize: LuminaTypography.sizeCaption - 1,
                color: secondaryTextColor.withAlpha(180),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "made with love ❤️ from Asher",
              style: GoogleFonts.dmSans(
                fontSize: LuminaTypography.sizeCaption - 1,
                color: secondaryTextColor.withAlpha(180),
              ),
            ),
            const SizedBox(height: LuminaSpacing.xl),
          ],
        ),
      ),
    );
  }
}
