import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/validators.dart';
import '../data/team_repository.dart';
import '../domain/team.dart';

/// Hoja para crear o editar un equipo.
///
/// Solo el creador llega aquí en modo edición; el RLS de `teams` lo garantiza
/// también en el servidor.
class TeamFormSheet extends ConsumerStatefulWidget {
  const TeamFormSheet({super.key, this.team});

  final Team? team;

  static Future<bool?> showCreate(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const TeamFormSheet(),
    );
  }

  static Future<bool?> showEdit(BuildContext context, Team team) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TeamFormSheet(team: team),
    );
  }

  @override
  ConsumerState<TeamFormSheet> createState() => _TeamFormSheetState();
}

class _TeamFormSheetState extends ConsumerState<TeamFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _seasonController;

  late String _category;
  bool _saving = false;
  String? _error;

  static const _categories = [
    'Senior',
    'Juvenil',
    'Cadete',
    'Infantil',
    'Alevín',
  ];

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    final team = widget.team;
    _nameController = TextEditingController(text: team?.name ?? '');
    _seasonController = TextEditingController(text: team?.season ?? '');
    _category = _categories.contains(team?.category)
        ? team!.category
        : _categories.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final repository = ref.read(teamRepositoryProvider);

    try {
      final team = widget.team;
      if (team == null) {
        await repository.createTeam(
          name: _nameController.text,
          category: _category,
          season: _seasonController.text,
        );
      } else {
        await repository.updateTeam(
          id: team.id,
          name: _nameController.text,
          category: _category,
          season: _seasonController.text,
        );
        ref.invalidate(teamProvider(team.id));
      }

      ref.invalidate(teamsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyErrorMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              _isEditing ? 'Editar equipo' : 'Nuevo equipo',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofocus: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Nombre del equipo',
                prefixIcon: Icon(Icons.groups_outlined),
              ),
              validator: (value) =>
                  Validators.requiredText(value, field: 'El nombre'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _seasonController,
              decoration: const InputDecoration(
                labelText: 'Temporada (opcional)',
                hintText: '2026',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Guardar cambios' : 'Guardar equipo'),
            ),
          ],
        ),
      ),
    );
  }
}
