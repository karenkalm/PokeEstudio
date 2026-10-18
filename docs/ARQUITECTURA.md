# PokéStudio · Fase 1: diseño y arquitectura

> Proyecto de fans. No es una aplicación oficial de Pokémon ni está afiliada a
> Nintendo, Game Freak, Creatures o The Pokémon Company.

## 1. Resumen del producto

PokéStudio es una Pokédex personal para el celular: bonita, nostálgica y útil.
Combina cuatro cosas que normalmente viven en apps separadas:

| Pilar | Qué resuelve | Fase |
|---|---|---|
| **Pokédex** | Buscar, filtrar y consultar fichas completas con datos reales de PokéAPI | 2 ✅ |
| **Colección** | Llevar el registro personal (capturados, favoritos, shiny, objetivos) sin cuenta | 3 |
| **Centro táctico** | Equipos de 6, cobertura de tipos, evoluciones y localizaciones | 4 |
| **Juego** | Cartas holográficas, cries y minijuegos con récords locales | 5–6 |

Principio rector: **primero lo esencial, después lo avanzado**. Cada pantalla
muestra una acción principal clara y deja los detalles un toque más abajo.

## 2. Mapa de navegación

```
                ┌──────────────────── Barra inferior (5 secciones) ───────────────────┐
                │  Inicio     Pokédex      Mi equipo     Minijuegos     Colección     │
                └────┬───────────┬──────────────┬──────────────┬──────────────┬───────┘
                     │           │              │              │              │
 /inicio ────────────┤   /pokedex┤        /equipo (F4)  /minijuegos (F6) /coleccion (F3)
   ├─ buscador ──────┼──► aplica búsqueda y abre Pokédex
   ├─ destacados ────┼──► /pokemon/:id
   ├─ vistos ────────┼──► /pokemon/:id
   ├─ explorar tipo ─┼──► Pokédex con filtro de tipo
   ├─ explorar gen. ─┼──► Pokédex con filtro de generación
   └─ ⚙ ─────────────┼──► /ajustes
                     └─ tarjeta ──► /pokemon/:id ──◀ ▶ (especie anterior / siguiente)
```

* Las cinco secciones son ramas de un `StatefulShellRoute.indexedStack`, así que
  cada pestaña conserva su scroll, su búsqueda y sus filtros al cambiar de sección.
* La ficha (`/pokemon/:id`) y los ajustes (`/ajustes`) se abren a pantalla
  completa sobre la barra inferior; "atrás" devuelve exactamente a donde estabas.
* Las flechas ◀ ▶ de la ficha usan `replace`: cambian de especie sin apilar
  pantallas ni repetir la animación de entrada.

## 3. Arquitectura de información

**Inicio** — saludo, buscador con sugerencias instantáneas, contador de la
Pokédex Nacional, *Destacados de hoy* (carrusel con flechas retro), *Vistos
recientemente*, *Explorar por tipo* y *Explorar por generación*.

**Pokédex** — buscador → botón de filtros (con contador) → orden → número de
resultados → chips de filtros activos → cuadrícula de tarjetas.

**Ficha** — cabecera con número, flechas, ilustración en "pantalla" retro
(ilustración / pixel / animado), nombre, categoría y tipos → datos rápidos
(altura, peso, generación) → tres pestañas:

1. *Información*: descripción en español (con selector de versión), habilidades
   (toca para ver su efecto) y formas alternativas.
2. *Estadísticas*: seis barras animadas con valor numérico y total.
3. *Debilidades*: ×4, ×2, ×½, ×¼ y ×0 calculados con la tabla de tipos.

**Ajustes** — nombre de entrenador, estilo de tarjetas, reducir movimiento,
caché, historial, licencias y aviso de proyecto de fans.

## 4. Identidad visual

### Paleta

| Token | Color | Uso |
|---|---|---|
| `pokeRed` | `#E94B4B` | Acentos, iconos activos, decoración |
| `pokeRedDeep` | `#C73A3A` | Fondos de botón con texto blanco (contraste 5.1:1) |
| `coral` | `#FF7777` | Estados activos, barras bajas |
| `pikachuYellow` | `#FFD95A` | Destacados, indicador de pestaña |
| `creamYellow` | `#FFF0B3` | Superficies decorativas |
| `pokeBlue` | `#4B8FE8` | Elementos interactivos (decoración) |
| `pokeBlueDeep` | `#2F6FC4` | Texto/enlaces azules (contraste 5.0:1) |
| `skyBlue` | `#BBDFFF` | Tarjetas y fondos suaves |
| `grassGreen` / `mint` | `#8BCF9B` / `#D5F1D7` | Elementos naturales |
| `lavender` / `pastelPink` | `#C9B8F2` / `#F7C7D9` | Detalles cute |
| `warmCream` | `#FFF7E8` | Fondo principal |
| `retroBrown` / `retroBrownDark` | `#563B2B` / `#34251F` | Marcos, etiquetas retro |
| `ink` | `#29252A` | Texto (14.2:1 sobre crema) |
| `inkMuted` | `#6B5B50` | Texto secundario (6.1:1 sobre crema) |

Los colores clásicos son **acentos** sobre una base crema; nunca dominan una
pantalla completa. Los pares texto/fondo se calcularon con la fórmula WCAG y
todos superan 4.5:1.

### Colores por tipo

Cada tipo tiene un color `base` (insignias, barras), un `soft` pastel (fondo
de tarjetas) y un color de texto elegido automáticamente para superar 4.5:1.
Es una capa de personalización: la ficha tiñe su cabecera con el tipo
principal, pero la navegación, la barra y los botones mantienen la identidad
global.

### Tipografía

| Rol | Fuente | Dónde |
|---|---|---|
| Títulos | **Fredoka** (500–700), redondeada y amigable | Logotipo, títulos, nombres de Pokémon |
| Interfaz y párrafos | **Nunito** (400–800), sans serif clara | Todo el texto de lectura |
| Detalle retro | **Press Start 2P** | Solo números de Pokédex y etiquetas cortas |

Las tres son OFL, van empaquetadas (no se descargan en tiempo de ejecución) y
sus licencias aparecen en *Ajustes → Licencias*.

### Lenguaje de componentes

* Marco retro: borde marrón de 2 dp + filo interior claro (doble bisel).
* Radios: 10 / 16 / 22 / 28 dp. Espaciado en múltiplos de 4.
* Sombras discretas y cálidas (marrón al 12–18 %).
* Sprites pixel art escalados con `FilterQuality.none` para que se vean nítidos.
* Animaciones cortas (150–450 ms) y desactivables.

## 5. Sistema de componentes

| Componente | Responsabilidad |
|---|---|
| `PokemonCard` | Tarjeta de especie (número, sprite, nombre, tipos) con fondo por tipo |
| `PokemonTypeBadge` | Insignia de tipo con icono + texto (nunca solo color) |
| `PokemonSprite` / `AppNetworkImage` | Imagen con caché, marcador bonito si falta |
| `PokemonStatBar` | Barra animada con valor real sobre escala fija 0–255 |
| `PokemonSearchBar` | Buscador con limpieza rápida |
| `PokemonFilterSheet` | Hoja de filtros con vista previa del número de resultados |
| `RetroPanel` | Panel con marco retro reutilizable |
| `DexNumberTag` | Etiqueta pixel del número |
| `RetroArrowButton` | Flechas ◀ ▶ del lenguaje visual |
| `LoadingPokemonCard` | Esqueleto de carga |
| `ErrorRetryView` | Error comprensible + reintento |
| `CuteEmptyState` | Estado vacío con acción |
| `UpcomingFeatureView` | Pantalla honesta de "llega en la fase X" |
| *(F3–F6)* `EvolutionTree`, `TeamSlotCard`, `CoverageMatrix`, `HoloPokemonCard`, `GameActionButton` | |

Todos son widgets internos de Flutter; la app no crea widgets de pantalla de
inicio del sistema operativo.

## 6. Arquitectura de software

```
Presentación (widgets)  ──watch──►  Estado (Riverpod providers / notifiers)
                                          │
                                          ▼
                              Repositorios (PokemonRepository, PokedexIndexRepository)
                                          │
                     ┌────────────────────┼────────────────────┐
                     ▼                    ▼                    ▼
              PokeApiClient          JsonCache            Activo empaquetado
     (http, reintentos, dedupe)  (memoria LRU + disco)   (índice de la Pokédex)
```

* **Ningún widget hace peticiones HTTP**. Todo pasa por repositorios.
* `PokeApiClient`: deduplica peticiones en curso, reintenta errores transitorios
  (timeout, 5xx, sin conexión) con espera creciente, no reintenta 404, decodifica
  UTF-8 explícitamente y procesa JSON grandes fuera del hilo de la interfaz.
* `JsonCache`: caché en memoria + disco con vigencia de 30 días (los datos de
  PokéAPI casi nunca cambian). Si la red falla y hay copia vieja, se usa la copia.
* Reductores: antes de guardar se eliminan campos enormes que no se usan
  (`moves`, `game_indices`, `sprites.versions`…), así la caché ocupa poco.
* Riverpod 3 con reintento automático desactivado (los reintentos viven en la
  capa HTTP) y `autoDispose` + `keepAlive` temporal para las fichas.

### El índice empaquetado

PokéAPI no ofrece un endpoint que devuelva, en una sola petición, nombres en
español, tipos, generación y estadísticas de todas las especies. Pedirlo en
vivo serían ~2 050 peticiones en el primer arranque. La solución:

* `tool/generate_pokedex_index.py` genera `assets/data/pokedex_index.json`
  (≈240 KB, 1 025 especies) **a partir de datos reales de PokéAPI**.
* La app busca y filtra sobre ese índice al instante y sin conexión.
* Al abrirse, comprueba `GET /pokemon-species?limit=1`: si PokéAPI tiene más
  especies que el índice, descarga solo las nuevas y las guarda en caché.
* Las fichas siempre se piden en vivo (con caché).

Hallazgos al generar el índice (datos del 17/10/2026):

* 1 025 especies, todas con nombre en español. 21 se llaman distinto que en
  inglés (p. ej. *Type: Null → Código Cero*, *Great Tusk → Colmilargo*), por eso
  la búsqueda indexa ambos idiomas.
* 127 especies (de la #899 en adelante) **no tienen descripción ni categoría en
  español** en PokéAPI. La app muestra el texto en inglés y lo indica.
* Todas las formas por defecto tienen sprite, sprite shiny e ilustración oficial.

## 7. Estructura de carpetas

```
lib/
├── main.dart                 arranque: preferencias, caché, licencias, ProviderScope
├── app/                      app.dart, router.dart, app_shell.dart, layout/, theme/
├── core/                     audio/, network/, cache/, errors/, storage/, utils/
├── shared/                   models/, domain/ (tabla de tipos), repositories/, widgets/
└── features/
    ├── home/                 application/ (destacados, vistos) + presentation/
    ├── pokedex/              domain/ (filtro, motor de búsqueda) + application/ + presentation/
    ├── pokemon_detail/       domain/ (textos) + application/ + presentation/
    ├── settings/             application/ + presentation/
    ├── team_builder/         (F4) hoy: pantalla "próximamente"
    ├── collection/           (F3) hoy: pantalla "próximamente"
    └── mini_games/           (F6) hoy: pantalla "próximamente"
```

`evolution/`, `shiny_lab/` y `habitats/` se crean en sus fases; no se dejan
carpetas vacías.

## 8. Dependencias

Verificadas el 17/10/2026 contra las etiquetas publicadas de cada paquete.
Requieren **Flutter 3.38 o superior (Dart 3.10)**; se eligieron las series
compatibles con esa versión para que el proyecto compile en equipos que aún no
actualizan Flutter.

| Paquete | Versión | Motivo |
|---|---|---|
| `flutter_riverpod` | ^3.3.2 | Gestión de estado (obligatoria). Sin generación de código. |
| `go_router` | ^17.5.0 | Navegación con `StatefulShellRoute` (obligatoria). |
| `http` | ^1.5.0 | Cliente HTTP único (oficial de Dart, liviano, `MockClient` para pruebas). |
| `shared_preferences` | ^2.5.4 | Preferencias sencillas e historial de vistos. |
| `path_provider` | ^2.1.5 | Carpeta para la caché en disco (no se usa en web). |
| `cached_network_image` | ^3.4.1 | Caché de sprites e ilustraciones en Android/iOS. En web se usa `Image.network`, porque su versión web perdía las texturas al cambiar de pestaña. |
| `flutter_cache_manager` | ^3.4.1 | Vaciar la caché de imágenes desde Ajustes. |
| `audioplayers` | ^6.7.1 | Efectos de sonido de la interfaz (modo de baja latencia). |
| `flutter_lints` (dev) | ^6.0.0 | Reglas de análisis. |

### Pantallas de todos los tamaños

| Ancho | Navegación | Contenido |
|---|---|---|
| < 600 dp (celular) | Barra inferior | Una columna, márgenes de 20 dp |
| 600–839 dp (tablet vertical) | Barra inferior | Carrusel con tarjetas de ~430 dp, ficha en una columna de 760 dp |
| ≥ 840 dp (tablet horizontal, computadora) | Riel lateral con logo y Ajustes | Contenido centrado (máx. 1200 dp); ficha en dos columnas desde 900 dp |

Las medidas viven en `lib/app/layout/responsive.dart`. Cada pantalla mide el
espacio real con `LayoutBuilder` (no el ancho de la ventana), así el riel
lateral no descuadra los márgenes.

### Sonidos

`lib/core/audio/sound_service.dart` define ocho efectos (`tap`, `select`,
`open`, `back`, `arrow`, `toggle`, `success`, `error`), archivos WAV
originales en `assets/sounds/`. Siempre acompañan a un cambio visual; nunca son
la única señal. Se apagan o ajustan en *Ajustes → Sonido* y las pruebas usan
`SilentSoundService`.

**Fase 3** añadirá `drift`, `drift_flutter`, `build_runner` y `drift_dev`
(SQLite) para colección, equipos y récords. **Fase 5** reutilizará `audioplayers`
para los gritos; ojo: los cries de PokéAPI son `.ogg`, que iOS no reproduce de forma
nativa, así que esa fase incluye una estrategia de conversión o *fallback*.

## 9. Accesibilidad

* Etiquetas semánticas en tarjetas, insignias, barras y botones de icono.
* Tipos con icono + texto; barras con número; nada depende solo del color.
* Áreas táctiles ≥ 48 dp. Texto escalable (las tarjetas recalculan su alto).
* "Reducir movimiento" propio + respeto a la preferencia del sistema.
* Errores en lenguaje claro: "Sin conexión", "PokéAPI tardó demasiado"…

## 10. Hoja de ruta

| Fase | Estado |
|---|---|
| 1 · Diseño y arquitectura | ✅ este documento |
| 2 · App base: tema, navegación, inicio, tarjetas, Pokédex, búsqueda, filtros, ficha | ✅ código entregado |
| 3 · Colección, favoritos, capturas, registro shiny, Drift | pendiente |
| 4 · Team Builder, cobertura, árbol evolutivo, localizaciones | pendiente |
| 5 · Cartas holográficas, cries, efectos retro | pendiente |
| 6 · Minijuegos | pendiente |
| 7 · Validación final | pendiente |
