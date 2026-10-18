import 'package:flutter/material.dart';

import '../../app/theme/type_palette.dart';
import '../models/pokemon_type.dart';

enum BadgeSize { small, medium, large }

/// Insignia de tipo: color + icono + nombre en español.
///
/// Con [onTap] se vuelve un botón (por ejemplo, "explorar por tipo").
class PokemonTypeBadge extends StatelessWidget {
  const PokemonTypeBadge({
    super.key,
    required this.type,
    this.size = BadgeSize.medium,
    this.onTap,
    this.selected = false,
    this.trailing,
  });

  final PokemonType type;
  final BadgeSize size;
  final VoidCallback? onTap;
  final bool selected;

  /// Texto opcional al final (p. ej. "×4").
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = TypePalette.of(type);
    final (double fontSize, double iconSize, EdgeInsets padding) = switch (size) {
      BadgeSize.small => (11.0, 12.0, const EdgeInsets.symmetric(horizontal: 7, vertical: 3)),
      BadgeSize.medium => (13.0, 15.0, const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
      BadgeSize.large => (15.0, 18.0, const EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
    };
    final label = trailing == null ? type.spanishName : '${type.spanishName} $trailing';

    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(palette.icon, size: iconSize, color: palette.onBase),
          SizedBox(width: size == BadgeSize.small ? 3 : 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                height: 1.1,
                color: palette.onBase,
              ),
            ),
          ),
        ],
      ),
    );

    final shape = StadiumBorder(
      side: selected ? const BorderSide(color: Color(0xFF34251F), width: 2.5) : BorderSide.none,
    );

    if (onTap == null) {
      return Semantics(
        label: 'Tipo ${type.spanishName}${trailing == null ? '' : ', $trailing'}',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: ShapeDecoration(color: palette.base, shape: shape),
          child: content,
        ),
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: 'Tipo ${type.spanishName}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: palette.base,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );
  }
}
