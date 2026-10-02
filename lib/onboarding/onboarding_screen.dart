import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final List<Map<String, dynamic>> _vibes = [
    {
      'title': 'Y2K Cyber',
      'icon': Icons.bolt_rounded,
      'color': const Color(0xFF00E5FF),
      'description': 'Metallic finishes, futuristic retros & baggy fits',
    },
    {
      'title': 'Vintage 90s',
      'icon': Icons.radio_rounded,
      'color': const Color(0xFFFF9100),
      'description': 'Oversized tees, denim jackets & retro nostalgia',
    },
    {
      'title': 'Streetwear',
      'icon': Icons.skateboarding_rounded,
      'color': const Color(0xFFFF1744),
      'description': 'Heavyweight hoodies, hype sneakers & graphic prints',
    },
    {
      'title': 'Minimalist',
      'icon': Icons.interests_rounded,
      'color': const Color(0xFF7C4DFF),
      'description': 'Clean silhouettes, neutral tones & premium essentials',
    },
    {
      'title': 'Cottagecore',
      'icon': Icons.spa_rounded,
      'color': const Color(0xFF00E676),
      'description': 'Florals, knitwear, linen pieces & earthy vibes',
    },
    {
      'title': 'Techwear',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFF651FFF),
      'description': 'Utility pockets, waterproof gear & stealth aesthetics',
    },
    {
      'title': 'Dark Academia',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF8D6E63),
      'description': 'Tweed blazers, plaid skirts, vintage knits & oxfords',
    },
    {
      'title': 'Grunge',
      'icon': Icons.electric_bolt_rounded,
      'color': const Color(0xFF78909C),
      'description': 'Distressed denim, flannel layers & rebellious attitude',
    },
  ];

  final Set<String> _selectedVibes = {'Y2K Cyber', 'Streetwear'};
  bool _isLoading = false;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePreferencesAndProceed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final client = _supabase;
      final user = client?.auth.currentUser;

      if (client != null && user != null) {
        // Save selected preferences into Supabase user_preferences table
        await client.from('user_preferences').upsert({
          'user_id': user.id,
          'preferred_vibes': _selectedVibes.toList(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/feed');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Fallback navigation even if saving fails locally
      Navigator.pushReplacementNamed(context, '/feed');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF7F00FF);
    final accentColor = const Color(0xFFE100FF);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Step & Skip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.2),
                          accentColor.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Step 1 of 2 • ${_selectedVibes.length} Selected',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () =>
                              Navigator.pushReplacementNamed(context, '/feed'),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title and Subtitle
              Text(
                'Choose Your Vibe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select the aesthetics you love most. Our AI will curate your marketplace feed accordingly.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 20),

              // Vibe Selection Grid
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.15,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _vibes.length,
                  itemBuilder: (context, index) {
                    final vibe = _vibes[index];
                    final isSelected = _selectedVibes.contains(vibe['title']);
                    final Color vibeColor = vibe['color'] as Color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            if (_selectedVibes.length > 1) {
                              _selectedVibes.remove(vibe['title']);
                            }
                          } else {
                            _selectedVibes.add(vibe['title'] as String);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? (isSelected
                                    ? primaryColor.withValues(alpha: 0.18)
                                    : const Color(0xFF1E1E1E))
                              : (isSelected
                                    ? primaryColor.withValues(alpha: 0.08)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : (isDark ? Colors.white10 : Colors.black12),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: vibeColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    vibe['icon'] as IconData,
                                    color: vibeColor,
                                    size: 20,
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vibe['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vibe['description'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Continue / Explore Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePreferencesAndProceed,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, accentColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Explore Drops',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
