import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile_summary.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/widgets/user_avatar.dart';
import '../data/team_repository.dart';

/// Selector de usuarios registrados para añadir a un equipo.
///
/// Se busca por nombre mientras se escribe y se elige una persona de la lista.
/// Solo el creador del equipo puede abrir esta hoja.
class AddMemberSheet extends ConsumerStatefulWidget {
  const AddMemberSheet({
    super.key,
    required this.teamId,
    required this.excludeUserIds,
  });

  final String teamId;

  /// Creador y personas que ya están en el equipo: no aparecen en el selector.
  final Set<String> excludeUserIds;

  static Future<bool?> show(
    BuildContext context, {
    required String teamId,
    required Set<String> excludeUserIds,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          AddMemberSheet(teamId: teamId, excludeUserIds: excludeUserIds),
    );
  }

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  static const _debounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  List<ProfileSummary> _results = const [];
  ProfileSummary? _selected;
  bool _searching = false;
  bool _adding = false;
  String? _error;

  /// Descarta respuestas que llegan tarde (búsquedas que ya no importan).
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged() {
    final term = _controller.text.trim();

    if (term == _selected?.displayName) return;

    setState(() => _selected = null);
    _timer?.cancel();

    if (term.length < 2) {
      _requestId++;
      setState(() {
        _results = const [];
        _searching = false;
        _error = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });
    _timer = Timer(_debounce, () => _search(term));
  }

  Future<void> _search(String term) async {
    final requestId = ++_requestId;

    try {
      final results = await ref
          .read(teamRepositoryProvider)
          .searchProfiles(term, excludeUserIds: widget.excludeUserIds);

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = const [];
        _searching = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  Future<void> _add() async {
    final profile = _selected;
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
    final term = _controller.text.trim();

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
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
            'Busca por nombre entre los usuarios registrados en CiegoVolley.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Nombre del integrante',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: term.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      onPressed: () {
                        _controller.clear();
                        _focusNode.requestFocus();
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 260, child: _buildResults(theme, term)),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _selected == null || _adding ? null : _add,
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
      ),
    );
  }

  Widget _buildResults(ThemeData theme, String term) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (term.length < 2) {
      return _Hint(
        icon: Icons.keyboard_outlined,
        text: 'Escribe al menos dos letras del nombre.',
      );
    }

    if (_results.isEmpty) {
      return _Hint(
        icon: Icons.person_search_outlined,
        text: 'No hay usuarios que coincidan con «$term».',
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final profile = _results[index];
        final selected = profile.id == _selected?.id;

        return Card(
          margin: EdgeInsets.zero,
          color: selected ? theme.colorScheme.primaryContainer : null,
          child: ListTile(
            selected: selected,
            leading: UserAvatar(
              name: profile.displayName,
              avatarUrl: profile.avatarUrl,
              radius: 20,
              backgroundColor: selected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.secondaryContainer,
              foregroundColor: selected
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.onSecondaryContainer,
            ),
            title: Text(
              profile.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(profile.email),
            trailing: selected
                ? const Icon(Icons.check_circle, size: 20)
                : null,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _selected = profile);
            },
          ),
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
