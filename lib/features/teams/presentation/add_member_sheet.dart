import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile_summary.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/validators.dart';
import '../data/team_repository.dart';

/// Busca un usuario registrado por correo y lo añade al equipo.
///
/// Solo el creador del equipo puede abrir esta hoja.
class AddMemberSheet extends ConsumerStatefulWidget {
  const AddMemberSheet({
    super.key,
    required this.teamId,
    required this.ownerId,
  });

  final String teamId;
  final String ownerId;

  static Future<bool?> show(
    BuildContext context, {
    required String teamId,
    required String ownerId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AddMemberSheet(teamId: teamId, ownerId: ownerId),
    );
  }

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  ProfileSummary? _found;
  bool _searching = false;
  bool _adding = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _searching = true;
      _searched = false;
      _found = null;
      _error = null;
    });

    try {
      final profile = await ref
          .read(teamRepositoryProvider)
          .findProfileByEmail(_emailController.text);

      if (!mounted) return;
      setState(() {
        _searching = false;
        _searched = true;
        _found = profile;
        if (profile == null) {
          _error = 'No hay ningún usuario registrado con ese correo.';
        } else if (profile.id == widget.ownerId) {
          _error = 'Ese usuario es el creador del equipo.';
          _found = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  Future<void> _add() async {
    final profile = _found;
    if (profile == null) return;

    setState(() {
      _adding = true;
      _error = null;
    });

    try {
      await ref
          .read(teamRepositoryProvider)
          .addMember(teamId: widget.teamId, userId: profile.id);
      ref.invalidate(teamMembersProvider(widget.teamId));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _adding = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _searching || _adding;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Añadir integrante',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Debe tener una cuenta registrada en CiegoVolley.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.search,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Correo del integrante',
                prefixIcon: const Icon(Icons.alternate_email),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: busy ? null : _search,
                  icon: const Icon(Icons.search),
                ),
              ),
              validator: Validators.email,
              onFieldSubmitted: (_) {
                if (!busy) _search();
              },
            ),
            if (_searching) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_found != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(_initials(_found!.displayName)),
                  ),
                  title: Text(
                    _found!.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(_found!.email),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _adding ? null : _add,
                icon: _adding
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Añadir al equipo'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            if (_searched && _found == null && _error == null) ...[
              const SizedBox(height: 12),
              Text(
                'Sin resultados.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}
