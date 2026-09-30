import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Écran fixe : le contenu tient toujours en entier dans la place disponible,
/// sans défilement.
///
/// Registre (QA appareil, 23/09/2026) : l'onboarding et l'authentification ne
/// défilent plus. Le contenu est posé à la largeur de l'écran et remplit au
/// moins sa hauteur (comme avant, pour les `Spacer` et les centrages). S'il
/// dépasse — grand texte, petit écran, clavier ouvert — il est réduit juste
/// assez pour tenir, centré. Le bouton qui apparaît après une réponse est
/// donc visible d'un coup, sans geste.
///
/// Une seule mise en page par image, toujours à la même largeur : une
/// seconde passe à une autre largeur relançait sans fin les animations de
/// taille du contenu.
class FitViewport extends SingleChildRenderObjectWidget {
  const FitViewport({required Widget super.child, super.key});

  @override
  RenderFitViewport createRenderObject(BuildContext context) =>
      RenderFitViewport();
}

class RenderFitViewport extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  double _scale = 1;

  /// Réduction appliquée à la dernière mise en page (1 : taille réelle).
  double get scale => _scale;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    size = constraints.biggest;
    final child = this.child;
    if (child == null) return;
    if (!width.isFinite || !height.isFinite || height <= 0) {
      child.layout(constraints, parentUsesSize: true);
      _scale = 1;
      return;
    }

    child.layout(
      BoxConstraints(minWidth: width, maxWidth: width, minHeight: height),
      parentUsesSize: true,
    );
    final natural = child.size.height;
    if (natural <= height + 0.5) {
      _scale = 1;
      return;
    }

    _scale = height / natural;
  }

  Offset get _childOffset {
    final child = this.child;
    if (child == null) return Offset.zero;
    final painted = child.size.width * _scale;
    return Offset(math.max(0, (size.width - painted) / 2), 0);
  }

  Matrix4 get _transform {
    final offset = _childOffset;
    return Matrix4.translationValues(offset.dx, offset.dy, 0)
      ..multiply(Matrix4.diagonal3Values(_scale, _scale, 1));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    if (_scale == 1) {
      context.paintChild(child, offset);
      return;
    }
    context.pushTransform(needsCompositing, offset, _transform, (
      context,
      offset,
    ) {
      context.paintChild(child, offset);
    });
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintTransform(
      transform: _scale == 1 ? null : _transform,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_scale != 1) transform.multiply(_transform);
  }

  @override
  double computeMinIntrinsicHeight(double width) => 0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child?.getMaxIntrinsicHeight(width) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;
}
