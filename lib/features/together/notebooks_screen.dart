import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/format.dart';
import '../../core/l10n.dart';
import '../../data/models.dart';
import '../../data/session.dart';
import '../../design/design.dart';
import '../compose/compose_screen.dart' show pickPerson;

/// Notebooks you share with one person, written in turn.
class NotebooksScreen extends StatefulWidget {
  const NotebooksScreen({super.key});

  @override
  State<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends State<NotebooksScreen> {
  final _session = Session.instance;
  late Stream<List<SharedNotebook>> _notebooks = _session.notebooks.mine(
    _session.uid,
  );

  void _retry() =>
      setState(() => _notebooks = _session.notebooks.mine(_session.uid));

  Future<void> _start() async {
    if (_session.circle.isEmpty) {
      showToast(context, 'Add people to your circle first.'.tr, error: true);
      return;
    }
    final friend = await pickPerson(
      context,
      title: 'Who do you want to write with?'.tr,
    );
    if (friend == null || !mounted) return;
    final title = await showNwuSheet<String>(
      context,
      builder: (_) => _NameSheet(friend: friend),
    );
    if (title == null || !mounted) return;
    try {
      final id = await _session.notebooks.create(
        author: _session.me,
        other: friend,
        title: title,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => NotebookScreen(notebookId: id),
        ),
      );
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBar(
        title: 'Shared notebooks'.tr,
        actions: [
          CircleIconButton(
            icon: CupertinoIcons.add,
            size: 40,
            semanticLabel: 'New notebook'.tr,
            onPressed: _start,
          ),
        ],
      ),
      body: StreamBuilder<List<SharedNotebook>>(
        stream: _notebooks,
        builder: (context, snap) {
          if (snap.hasError) return ErrorState(onRetry: _retry);
          if (!snap.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final notebooks = snap.data!;
          if (notebooks.isEmpty) {
            return EmptyState(
              emoji: '📖',
              title: 'A notebook for two'.tr,
              message:
                  'Take turns writing pages with a friend, your partner or your mum. You can only write when it’s your turn.'
                      .tr,
              actionLabel: 'New notebook'.tr,
              onAction: _start,
            );
          }
          return ListView(
            padding: EdgeInsets.fromLTRB(
              Space.gutter,
              Space.sm,
              Space.gutter,
              MediaQuery.of(context).padding.bottom + Space.xxl,
            ),
            children: [
              for (final (i, notebook) in notebooks.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.sm),
                  child: _NotebookTile(
                    notebook: notebook,
                  ).animate(delay: (i * 40).ms).fadeIn().slideY(begin: 0.05),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Who the other person in [notebook] is, with their live name and photo.
AppUser _partner(SharedNotebook notebook) {
  final session = Session.instance;
  final id = notebook.otherId(session.uid);
  return session.userOr(id, name: notebook.memberNames[id] ?? '');
}

class _NotebookTile extends StatelessWidget {
  const _NotebookTile({required this.notebook});

  final SharedNotebook notebook;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    final partner = _partner(notebook);
    final myTurn = notebook.isMyTurn(session.uid);
    final status = notebook.entryCount == 0
        ? (myTurn ? 'Write the first page ✍️' : 'Waiting for {name}')
        : (myTurn ? 'Your turn ✍️' : 'Waiting for {name}');
    return Pressable(
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => NotebookScreen(notebookId: notebook.id),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(Space.md),
        decoration: BoxDecoration(
          color: myTurn ? c.accentSoft : c.raised,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: myTurn
              ? null
              : Border.all(color: c.line.withValues(alpha: 0.7)),
        ),
        child: Row(
          children: [
            Avatar(url: partner.image, name: partner.username, size: 48),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContentText(notebook.title, style: context.text.headline),
                  const SizedBox(height: 2),
                  Text(
                    '${partner.username} · ${(notebook.entryCount == 1 ? '1 page' : '{n} pages').tr.replaceAll('{n}', '${notebook.entryCount}')}',
                    style: context.text.caption,
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    status.tr.replaceAll('{name}', partner.firstName),
                    style: context.text.label.copyWith(
                      color: myTurn ? c.accent : c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Names a new notebook.
class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.friend});

  final AppUser friend;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _title = TextEditingController(text: 'Our notebook'.tr);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.md,
        Space.gutter,
        Space.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(
                url: widget.friend.image,
                name: widget.friend.username,
                size: 40,
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Text(
                  'A notebook with {name}'.tr.replaceAll(
                    '{name}',
                    widget.friend.firstName,
                  ),
                  style: context.text.title,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.md),
          NwuField(
            controller: _title,
            hint: 'Name your notebook'.tr,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: Space.sm),
          ListenableBuilder(
            listenable: _title,
            builder: (context, _) => NwuButton(
              label: 'Create notebook'.tr,
              tone: ButtonTone.accent,
              onPressed: _title.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, _title.text.trim()),
            ),
          ),
        ],
      ),
    );
  }
}

/// One notebook: pages so far, and a box to write yours when it is your
/// turn.
class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key, required this.notebookId});

  final String notebookId;

  @override
  State<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends State<NotebookScreen> {
  static const _maxLength = 1000;

  final _session = Session.instance;
  final _text = TextEditingController();
  late final Stream<SharedNotebook?> _notebook = _session.notebooks.watch(
    widget.notebookId,
  );
  late Stream<List<NotebookEntry>> _entries = _session.notebooks.entries(
    widget.notebookId,
  );
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _add(SharedNotebook notebook) async {
    final text = _text.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _session.notebooks.addEntry(
        notebook: notebook,
        author: _session.me,
        text: text,
      );
      HapticFeedback.mediumImpact();
      _text.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(SharedNotebook notebook) async {
    final ok = await confirm(
      context,
      title: 'Delete this notebook?'.tr,
      message: 'All its pages will be deleted for both of you.'.tr,
      confirmLabel: 'Delete'.tr,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await _session.notebooks.delete(notebook);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showToast(context, 'Something went wrong'.tr, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SharedNotebook?>(
      stream: _notebook,
      builder: (context, snap) {
        final notebook = snap.data;
        return Scaffold(
          appBar: TopBar(
            title: notebook?.title ?? '',
            actions: [
              if (notebook != null)
                CircleIconButton(
                  icon: CupertinoIcons.trash,
                  size: 40,
                  semanticLabel: 'Delete notebook'.tr,
                  onPressed: () => _delete(notebook),
                ),
            ],
          ),
          body: snap.hasError
              ? ErrorState(onRetry: () => setState(() {}))
              : notebook == null
              ? (snap.connectionState == ConnectionState.waiting
                    ? const Center(child: CupertinoActivityIndicator())
                    : EmptyState(
                        emoji: '🕊️',
                        title: 'This notebook is gone'.tr,
                        message: 'One of you may have deleted it.'.tr,
                      ))
              : Column(
                  children: [
                    Expanded(
                      child: _Pages(
                        entries: _entries,
                        onRetry: () => setState(
                          () => _entries = _session.notebooks.entries(
                            widget.notebookId,
                          ),
                        ),
                      ),
                    ),
                    _Footer(
                      notebook: notebook,
                      controller: _text,
                      maxLength: _maxLength,
                      saving: _saving,
                      onAdd: () => _add(notebook),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _Pages extends StatelessWidget {
  const _Pages({required this.entries, required this.onRetry});

  final Stream<List<NotebookEntry>> entries;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    return StreamBuilder<List<NotebookEntry>>(
      stream: entries,
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(onRetry: onRetry);
        if (!snap.hasData) {
          return const Center(child: CupertinoActivityIndicator());
        }
        final pages = snap.data!;
        if (pages.isEmpty) {
          return EmptyState(
            emoji: '📖',
            title: 'An empty notebook'.tr,
            message: 'The first page is waiting to be written.'.tr,
          );
        }
        // Newest at the bottom, and the list starts scrolled there.
        final newestFirst = pages.reversed.toList();
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.sm,
            Space.gutter,
            Space.sm,
          ),
          itemCount: newestFirst.length,
          itemBuilder: (context, i) {
            final page = newestFirst[i];
            final mine = page.ownerId == session.uid;
            return Align(
              alignment: mine
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              child: Container(
                margin: const EdgeInsets.only(bottom: Space.sm),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.82,
                ),
                padding: const EdgeInsets.all(Space.md),
                decoration: BoxDecoration(
                  color: mine ? c.accentSoft : c.raised,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: mine
                      ? null
                      : Border.all(color: c.line.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${mine ? 'You'.tr : session.userOr(page.ownerId, name: page.ownerName).firstName} · ${fullDate(page.time)}',
                      style: context.text.caption.copyWith(color: c.inkSoft),
                    ),
                    const SizedBox(height: Space.xs),
                    ContentText(
                      page.text,
                      style: context.text.noteBody.copyWith(fontSize: 17),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.notebook,
    required this.controller,
    required this.maxLength,
    required this.saving,
    required this.onAdd,
  });

  final SharedNotebook notebook;
  final TextEditingController controller;
  final int maxLength;
  final bool saving;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = Session.instance;
    final bottom = MediaQuery.of(context).padding.bottom + Space.sm;
    if (!notebook.isMyTurn(session.uid)) {
      final partner = _partner(notebook);
      return Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          Space.gutter,
          Space.md,
          Space.gutter,
          bottom,
        ),
        decoration: BoxDecoration(
          color: c.raised,
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Text(
          'Waiting for {name} to write their page ✍️'.tr.replaceAll(
            '{name}',
            partner.firstName,
          ),
          textAlign: TextAlign.center,
          style: context.text.label.copyWith(color: c.inkSoft),
        ),
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(
        Space.gutter,
        Space.sm,
        Space.gutter,
        bottom,
      ),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NwuField(
            controller: controller,
            hint: 'It’s your turn. Write your page…'.tr,
            maxLines: 4,
            maxLength: maxLength,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: Space.xs),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => NwuButton(
              label: 'Add my page'.tr,
              tone: ButtonTone.accent,
              loading: saving,
              onPressed: controller.text.trim().isEmpty ? null : onAdd,
            ),
          ),
        ],
      ),
    );
  }
}
