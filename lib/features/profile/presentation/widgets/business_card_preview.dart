import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/profile.dart';

const profileLogoIcons = <String, IconData>{
  'building': Icons.business_outlined,
  'briefcase': Icons.work_outline,
  'star': Icons.star_outline,
  'shield': Icons.shield_outlined,
  'rocket': Icons.rocket_launch_outlined,
  'bulb': Icons.lightbulb_outline,
  'world': Icons.public,
  'chart-line': Icons.show_chart,
  'handshake': Icons.handshake_outlined,
  'diamond': Icons.diamond_outlined,
};

Color profileAccentColor(String value) {
  final hex = value.trim().replaceFirst('#', '');
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return const Color(0xFF3B6E91);
  return Color(hex.length == 6 ? 0xFF000000 | parsed : parsed);
}

class BusinessCardPreview extends StatelessWidget {
  const BusinessCardPreview({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final accent = profileAccentColor(profile.accentColor);
    final darkenedAccent = Color.lerp(accent, Colors.black, 0.28)!;
    final background = _contrastRatio(darkenedAccent, Colors.white) >= 4.5
        ? darkenedAccent
        : const Color(0xFF0F1B2D);
    final logoTint = _contrastRatio(accent, Colors.white) >= 3
        ? accent
        : darkenedAccent;
    final secondary = Colors.white.withValues(alpha: 0.76);
    final logo = profile.logoIcon == null
        ? Icons.badge_outlined
        : profileLogoIcons[profile.logoIcon!] ?? Icons.badge_outlined;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: background.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  shape: BoxShape.circle,
                ),
                child: Icon(logo, color: logoTint, size: 29),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          profile.jobTitle,
                          profile.company,
                        ].where((value) => value.trim().isNotEmpty).join(' · '),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: secondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_hasContactDetails) ...[
            const SizedBox(height: 18),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 14),
            if (_hasText(profile.phone))
              _ContactLine(
                icon: Icons.phone_outlined,
                label: profile.phone,
                color: secondary,
              ),
            if (_hasText(profile.email))
              _ContactLine(
                icon: Icons.mail_outline,
                label: profile.email,
                color: secondary,
              ),
            if (_hasText(profile.linkedin))
              _ContactLine(
                icon: FontAwesomeIcons.linkedin,
                label: profile.linkedin!,
                color: secondary,
              ),
            if (_hasText(profile.whatsapp))
              _ContactLine(
                icon: FontAwesomeIcons.whatsapp,
                label: profile.whatsapp!,
                color: secondary,
                onTap: () => _openWhatsApp(context, profile.whatsapp!),
              ),
            if (_hasText(profile.website))
              _ContactLine(
                icon: Icons.language,
                label: profile.website!,
                color: secondary,
              ),
          ],
        ],
      ),
    );
  }

  bool get _hasContactDetails =>
      _hasText(profile.phone) ||
      _hasText(profile.email) ||
      _hasText(profile.linkedin) ||
      _hasText(profile.whatsapp) ||
      _hasText(profile.website);

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;

  Future<void> _openWhatsApp(BuildContext context, String number) async {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri.https('wa.me', '/$digits');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir WhatsApp.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir WhatsApp.')),
        );
      }
    }
  }

  static double _contrastRatio(Color a, Color b) {
    final first = a.computeLuminance();
    final second = b.computeLuminance();
    final lighter = first > second ? first : second;
    final darker = first > second ? second : first;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
