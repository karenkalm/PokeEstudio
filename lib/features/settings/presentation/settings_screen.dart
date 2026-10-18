import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/providers.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/feedback_views.dart';
import '../../../shared/widgets/pokestudio_logo.dart';
import '../../../shared/widgets/retro_widgets.dart';
import '../../home/application/home_providers.dart';
import '../application/settings_controller.dart';

/// Espacio ocupado por la caché de datos (se recalcula al invalidarlo).
final cacheUsageProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(jsonCacheProvider).diskUsageBytes(),
  name: 'cacheUsageProvider',
);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name = TextEditingController(text: ref.read(settingsProvider).trainerName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    await ref.read(settingsProvider.notifier).setTrainerName(_name.text);
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    showAppSnackBar(context, 'Nombre de entrenador guardado');
  }

  Future<void> _clearCache() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Vaciar la caché?',
      message:
          'Se borrarán los datos e imágenes descargados de PokéAPI. Se volverán a descargar cuando los necesites. Tus ajustes no se modifican.',
      confirmLabel: 'Vaciar',
    );
    if (!confirmed) return;
    await ref.read(jsonCacheProvider).clear();
    await DefaultCacheManager().emptyCache();
    ref.invalidate(cacheUsageProvider);
    if (mounted) showAppSnackBar(context, 'Caché vaciada');
  }

  Future<void> _clearHistory() async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Borrar historial?',
      message: 'Se quitará la lista de Pokémon vistos recientemente.',
      confirmLabel: 'Borrar',
    );
    if (!confirmed) return;
    await ref.read(recentlyViewedProvider.notifier).clear();
    if (mounted) showAppSnackBar(context, 'Historial borrado');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final usage = ref.watch(cacheUsageProvider);
    final hasHistory = ref.watch(recentlyViewedProvider).isNotEmpty;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxl),
        children: <Widget>[
          _SettingsSection(
            title: 'Entrenador',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _name,
                  maxLength: SettingsController.maxNameLength,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveName(),
                  decoration: const InputDecoration(
                    labelText: 'Tu nombre para el saludo',
                    hintText: 'Por ejemplo: Rojo',
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: _saveName, child: const Text('Guardar')),
                ),
              ],
            ),
          ),
          _SettingsSection(
            title: 'Apariencia',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Imagen en las tarjetas', style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<CardArtStyle>(
                  segments: <ButtonSegment<CardArtStyle>>[
                    for (final style in CardArtStyle.values)
                      ButtonSegment<CardArtStyle>(value: style, label: Text(style.label)),
                  ],
                  selected: <CardArtStyle>{settings.cardArtStyle},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      ref.read(settingsProvider.notifier).setCardArtStyle(selection.first),
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reducir movimiento'),
                  subtitle: const Text('Desactiva animaciones decorativas. También respetamos la opción del sistema.'),
                  value: settings.reduceMotion,
                  onChanged: (value) => ref.read(settingsProvider.notifier).setReduceMotion(value),
                ),
              ],
            ),
          ),
          _SettingsSection(
            title: 'Datos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  usage.when(
                    data: (bytes) => 'Datos de PokéAPI guardados: ${Formatters.bytes(bytes)}',
                    loading: () => 'Calculando espacio…',
                    error: (error, stackTrace) => 'No se pudo calcular el espacio usado.',
                  ),
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Guardamos lo que consultas para que cargue rápido, funcione sin conexión y no saturar PokéAPI.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _clearCache,
                      icon: const Icon(Icons.cleaning_services_rounded),
                      label: const Text('Vaciar caché'),
                    ),
                    OutlinedButton.icon(
                      onPressed: hasHistory ? _clearHistory : null,
                      icon: const Icon(Icons.history_rounded),
                      label: const Text('Borrar historial'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _SettingsSection(
            title: 'Acerca de',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const PokestudioLogo(markSize: 32),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'PokéStudio es un proyecto de fans sin fines comerciales. No está afiliado ni respaldado por '
                  'Nintendo, Game Freak, Creatures o The Pokémon Company. Pokémon y los nombres de los personajes '
                  'son marcas de sus respectivos propietarios.',
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Datos, sprites e ilustraciones provienen de PokéAPI (pokeapi.co) y su repositorio de sprites.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: () => showLicensePage(
                    context: context,
                    applicationName: 'PokéStudio',
                    applicationVersion: '0.2.0 · Fase 2',
                  ),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Licencias de código abierto'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: RetroPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.retroBrown)),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}
