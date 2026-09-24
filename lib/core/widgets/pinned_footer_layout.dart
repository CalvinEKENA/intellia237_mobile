import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Écran à action épinglée : le contenu garde sa taille réelle, l'action
/// principale reste toujours visible en bas.
///
/// Registre (QA appareil, 24/09/2026) : réduire l'écran entier pour qu'il
/// tienne sans défiler rendait le texte minuscule et flou. Le vrai besoin
/// était qu'aucun bouton ne soit caché : le bouton est donc posé hors du
/// contenu, au-dessus du clavier. Seul le contenu peut glisser, et seulement
/// si l'écran est vraiment trop court ; une ombre au-dessus du bouton le
/// signale alors.
class PinnedFooterLayout extends StatefulWidget {
  const PinnedFooterLayout({
    required this.bodyBuilder,
    this.footer,
    this.background = Colors.transparent,
    this.bodyKey,
    this.keyboardInset = 0,
    super.key,
  });

  /// Construit le contenu ; reçoit la hauteur disponible au-dessus du pied,
  /// pour que le contenu puisse la remplir (centrage, espaces flexibles).
  final Widget Function(BuildContext context, double viewportHeight)
  bodyBuilder;

  /// L'action principale, toujours visible.
  final Widget? footer;

  /// Couleur du pied, pour qu'il se détache du contenu qui glisse dessous.
  final Color background;

  final Key? bodyKey;

  /// Hauteur du clavier, lue au-dessus du `Scaffold` (qui la retire à son
  /// contenu). Quand il s'ouvre, le contenu glisse pour montrer le champ
  /// actif et, autant que possible, ce qui le suit (souvent le bouton).
  final double keyboardInset;

  static const footerKey = ValueKey('pinned-footer');

  @override
  State<PinnedFooterLayout> createState() => _PinnedFooterLayoutState();
}

class _PinnedFooterLayoutState extends State<PinnedFooterLayout> {
  final _scroll = ScrollController();
  bool _moreBelow = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_syncMoreBelow);
    if (widget.keyboardInset > 0) _revealBelowFocus();
  }

  @override
  void didUpdateWidget(PinnedFooterLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyboardInset > oldWidget.keyboardInset) _revealBelowFocus();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Relit la place restante sous le contenu, après la mise en page.
  void _syncMoreBelow() {
    if (!mounted || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (!position.hasContentDimensions) return;
    final more = position.extentAfter > 1;
    if (more != _moreBelow) setState(() => _moreBelow = more);
  }

  void _scheduleSync() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncMoreBelow());

  /// Fait remonter le champ actif vers le haut de la zone visible, sans
  /// jamais le cacher : ce qui le suit apparaît au-dessus du clavier.
  void _revealBelowFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final focused = FocusManager.instance.primaryFocus?.context;
      if (focused == null || !focused.mounted) return;
      final position = _scroll.position;
      if (Scrollable.maybeOf(focused)?.position != position) return;
      final box = focused.findRenderObject();
      if (box is! RenderBox || !box.attached) return;
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) return;
      final top = viewport.getOffsetToReveal(box, 0).offset - 16;
      final target = top.clamp(0.0, position.maxScrollExtent).toDouble();
      if (target > position.pixels + 1) position.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleSync();
    final body = LayoutBuilder(
      builder: (context, constraints) =>
          NotificationListener<ScrollMetricsNotification>(
            // Le contenu change de taille (étape, message, animation).
            onNotification: (notification) {
              if (notification.depth == 0) _scheduleSync();
              return false;
            },
            child: SingleChildScrollView(
              key: widget.bodyKey,
              controller: _scroll,
              physics: const ClampingScrollPhysics(),
              child: widget.bodyBuilder(context, constraints.maxHeight),
            ),
          ),
    );
    final footer = widget.footer;
    if (footer == null) return body;
    return Column(
      children: [
        Expanded(child: body),
        AnimatedContainer(
          key: PinnedFooterLayout.footerKey,
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.background,
            boxShadow: [
              if (_moreBelow)
                const BoxShadow(
                  color: Color(0x2E25233E),
                  blurRadius: 16,
                  offset: Offset(0, -8),
                ),
            ],
          ),
          child: footer,
        ),
      ],
    );
  }
}
