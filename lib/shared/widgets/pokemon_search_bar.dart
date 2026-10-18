import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/audio/sound_service.dart';

/// Campo de búsqueda con icono y botón para limpiar.
class PokemonSearchBar extends StatelessWidget {
  const PokemonSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.hintText = 'Busca por nombre o número',
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCleared;
  final String hintText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          enableSuggestions: false,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.retroBrown),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      playSound(context, SoundEffect.back);
                      controller.clear();
                      onChanged?.call('');
                      onCleared?.call();
                    },
                  ),
          ),
        );
      },
    );
  }
}
