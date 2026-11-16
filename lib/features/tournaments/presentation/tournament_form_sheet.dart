import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/error_messages.dart';
import '../../../core/utils/validators.dart';
import '../data/tournament_repository.dart';
import '../domain/tournament.dart';

/// Qué ocurrió al cerrar la hoja de torneo.
enum TournamentFormResult { saved, deleted }

/// Hoja para crear o editar un torneo.
///
/// Solo el administrador llega aquí; el RLS de `tournaments` lo garantiza
/// también en el servidor.
class TournamentFormSheet extends ConsumerStatefulWidget {
  const TournamentFormSheet({super.key, this.tournament});

  final Tournament? tournament;

  static Future<TournamentFormResult?> showCreate(BuildContext context) {
    return showModalBottomSheet<TournamentFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const TournamentFormSheet(),
    );
  }

  static Future<TournamentFormResult?> showEdit(
    BuildContext context,
    Tournament tournament,
  ) {
    return showModalBottomSheet<TournamentFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => TournamentFormSheet(tournament: tournament),
    );
  }

  @override
  ConsumerState<TournamentFormSheet> createState() =>
      _TournamentFormSheetState();
}

class _TournamentFormSheetState extends ConsumerState<TournamentFormSheet> {
  static const _statuses = {
    'draft': 'Borrador',
    'published': 'Publicado',
    'finished': 'Finalizado',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;

  late String _status;
  DateTime? _startsOn;
  DateTime? _endsOn;

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.tournament != null;

  @override
  void initState() {
    super.initState();
    final tournament = widget.tournament;
    _nameController = TextEditingController(text: tournament?.name ?? '');
    _venueController = TextEditingController(text: tournament?.venue ?? '');
    _status = _statuses.containsKey(tournament?.status)
        ? tournament!.status
        : 'draft';
    _startsOn = tournament?.startsOn;
    _endsOn = tournament?.endsOn;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = (start ? _startsOn : _endsOn) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: start ? 'Fecha de inicio' : 'Fecha de fin',
    );

    if (picked == null) return;
    setState(() {
      if (start) {
        _startsOn = picked;
      } else {
        _endsOn = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startsOn != null && _endsOn != null && _endsOn!.isBefore(_startsOn!)) {
      setState(
        () => _error = 'La fecha de fin no puede ser anterior al inicio.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repository = ref.read(tournamentRepositoryProvider);

    try {
      final tournament = widget.tournament;
      if (tournament == null) {
        await repository.createTournament(
          name: _nameController.text,
          venue: _venueController.text,
          startsOn: _startsOn,
          endsOn: _endsOn,
          status: _status,
        );
      } else {
        await repository.updateTournament(
          id: tournament.id,
          name: _nameController.text,
          venue: _venueController.text,
          startsOn: _startsOn,
          endsOn: _endsOn,
          status: _status,
        );
      }

      ref.invalidate(tournamentsProvider);
      if (mounted) Navigator.of(context).pop(TournamentFormResult.saved);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  Future<void> _delete() async {
    final tournament = widget.tournament;
    if (tournament == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar torneo?'),
        content: Text(
          'Se borrará «${tournament.name}» y las inscripciones de los equipos. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(tournamentRepositoryProvider)
          .deleteTournament(tournament.id);
      ref.invalidate(tournamentsProvider);
      if (mounted) Navigator.of(context).pop(TournamentFormResult.deleted);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM y', 'es');

    return SingleChildScrollView(
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
              _isEditing ? 'Editar torneo' : 'Nuevo torneo',
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
                labelText: 'Nombre del torneo',
                prefixIcon: Icon(Icons.emoji_events_outlined),
              ),
              validator: (value) =>
                  Validators.requiredText(value, field: 'El nombre'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _venueController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Sede (opcional)',
                hintText: 'Ciego de Ávila',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Inicio',
              value: _startsOn == null ? null : dateFormat.format(_startsOn!),
              onPick: _saving ? null : () => _pickDate(start: true),
              onClear: _saving || _startsOn == null
                  ? null
                  : () => setState(() => _startsOn = null),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Fin',
              value: _endsOn == null ? null : dateFormat.format(_endsOn!),
              onPick: _saving ? null : () => _pickDate(start: false),
              onClear: _saving || _endsOn == null
                  ? null
                  : () => setState(() => _endsOn = null),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Estado',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: [
                for (final entry in _statuses.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _status = value ?? _status),
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
                  : Text(_isEditing ? 'Guardar cambios' : 'Crear torneo'),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saving ? null : _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar torneo'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          suffixIcon: onClear == null
              ? null
              : IconButton(
                  tooltip: 'Quitar fecha',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Text(value ?? 'Sin fecha'),
      ),
    );
  }
}
