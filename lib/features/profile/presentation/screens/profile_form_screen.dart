import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/profile.dart';
import '../providers/profile_providers.dart';
import '../widgets/business_card_preview.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  final Profile? existingProfile;

  const ProfileFormScreen({super.key, this.existingProfile});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _jobTitle;
  late final TextEditingController _company;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _linkedin;
  String? _logoIcon;
  bool _whatsappEdited = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProfile;
    _fullName = TextEditingController(text: p?.fullName ?? '');
    _jobTitle = TextEditingController(text: p?.jobTitle ?? '');
    _company = TextEditingController(text: p?.company ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _whatsapp = TextEditingController(text: p?.whatsapp ?? p?.phone ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _website = TextEditingController(text: p?.website ?? '');
    _linkedin = TextEditingController(text: p?.linkedin ?? '');
    _logoIcon = p?.logoIcon;
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _jobTitle,
      _company,
      _phone,
      _whatsapp,
      _email,
      _website,
      _linkedin,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(profileRepositoryProvider);
    final existing = widget.existingProfile;
    final now = DateTime.now();

    final profile = Profile(
      id: existing?.id ?? '',
      fullName: _fullName.text.trim(),
      jobTitle: _jobTitle.text.trim(),
      company: _company.text.trim(),
      phone: _phone.text.trim(),
      whatsapp: _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
      email: _email.text.trim(),
      website: _website.text.trim().isEmpty ? null : _website.text.trim(),
      linkedin: _linkedin.text.trim().isEmpty ? null : _linkedin.text.trim(),
      logoIcon: _logoIcon,
      templateId: existing?.templateId ?? 0,
      accentColor: existing?.accentColor ?? '#3B6E91',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (existing == null) {
      await repo.createProfile(profile);
    } else {
      await repo.updateProfile(profile);
    }

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProfile == null
              ? 'Créer mon profil'
              : 'Modifier le profil',
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _field(_fullName, 'Nom complet', required: true),
              _field(_jobTitle, 'Poste', required: true),
              _field(_company, 'Entreprise', required: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                child: Text(
                  'Icône du logo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                'Choisissez le symbole de votre carte.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  for (final entry in profileLogoIcons.entries)
                    _LogoIconChoice(
                      name: entry.key,
                      icon: entry.value,
                      selected: _logoIcon == entry.key,
                      accent: profileAccentColor(
                        widget.existingProfile?.accentColor ?? '#3B6E91',
                      ),
                      onTap: () => setState(() => _logoIcon = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                _phone,
                'Téléphone',
                required: true,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  if (!_whatsappEdited) _whatsapp.text = value;
                },
              ),
              _field(
                _whatsapp,
                'WhatsApp (optionnel)',
                keyboardType: TextInputType.phone,
                helperText:
                    'Prérempli avec le téléphone, modifiable séparément.',
                onChanged: (_) => _whatsappEdited = true,
              ),
              _field(
                _email,
                'Email',
                required: true,
                keyboardType: TextInputType.emailAddress,
              ),
              _field(
                _website,
                'Site web (optionnel)',
                keyboardType: TextInputType.url,
                maxLines: 2,
              ),
              _field(
                _linkedin,
                'LinkedIn (optionnel)',
                keyboardType: TextInputType.url,
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Enregistrer')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => (value == null || value.trim().isEmpty)
                  ? 'Champ obligatoire'
                  : null
            : null,
      ),
    );
  }
}

class _LogoIconChoice extends StatelessWidget {
  const _LogoIconChoice({
    required this.name,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: name,
      child: Semantics(
        label: 'Icône $name',
        selected: selected,
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.16) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? accent : Theme.of(context).dividerColor,
                width: selected ? 2 : 1,
              ),
            ),
            child: Icon(icon, color: selected ? accent : null),
          ),
        ),
      ),
    );
  }
}
