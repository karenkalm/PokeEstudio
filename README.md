# PokéStudio

**Pokédex, colección y centro táctico hecho por fans**, con Dart, Flutter y datos
reales de [PokéAPI](https://pokeapi.co). Estética retro y *cute*: tarjetas con
marco de doble bisel, sprites pixel art nítidos, fondos crema y acentos clásicos.

> Proyecto de fans sin fines comerciales. No está afiliado ni respaldado por
> Nintendo, Game Freak, Creatures o The Pokémon Company.

## Estado

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Diseño, arquitectura, paleta, tipografía, componentes | ✅ [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md) |
| 2 | Tema, navegación, Inicio, tarjetas, Pokédex, búsqueda, filtros, ficha, PokéAPI | ✅ |
| 3 | Colección, favoritos, capturas, registro shiny (Drift) | pendiente |
| 4 | Team Builder, cobertura, árbol evolutivo, localizaciones | pendiente |
| 5 | Cartas holográficas, cries, efectos retro | pendiente |
| 6 | Minijuegos | pendiente |

Las pestañas *Mi equipo*, *Minijuegos* y *Colección* ya existen en la barra,
pero muestran una pantalla que dice claramente en qué fase llegan; no simulan
funciones.

### Lo que hace hoy

* **Inicio**: saludo con tu nombre, buscador con sugerencias instantáneas,
  destacados del día (carrusel con flechas retro), vistos recientemente,
  explorar por tipo y por generación.
* **Pokédex** (1 025 especies): búsqueda por nombre en español o inglés,
  número (`25`, `#025`) o forma (`alola`), sin importar acentos. Filtros
  combinables: tipo 1/tipo 2 en cualquier posición o exacta, monotipo,
  generación, ataque/defensa/velocidad/total mínimos y formas alternativas, con
  vista previa del número de resultados. Ocho órdenes distintos.
* **Ficha**: ilustración oficial, sprite pixel y GIF animado; flechas ◀ ▶ (o
  deslizar) para ir a la especie vecina; categoría, altura, peso y generación;
  descripción en español con selector de versión; habilidades con su efecto;
  formas alternativas; estadísticas animadas; debilidades ×4 a ×0.
* **Ajustes**: nombre de entrenador, pixel art o ilustración en tarjetas,
  reducir movimiento, sonidos y volumen, vaciar caché, borrar historial y
  licencias.
* **Sonidos retro** originales al cambiar de sección, abrir fichas, usar las
  flechas, activar filtros y guardar (se apagan o ajustan en *Ajustes*).
* **Se adapta a cualquier pantalla**: celular, tablet y computadora. Desde
  840 px de ancho la barra inferior pasa a ser un riel lateral; el contenido
  se centra con un ancho máximo y la ficha se muestra en dos columnas. Con
  mouse se pueden arrastrar los carruseles, y en la ficha ← → cambian de
  especie y Esc la cierra.
* Funciona sin conexión para buscar y filtrar; las fichas ya vistas se leen
  de la caché.

## Requisitos

* **Flutter 3.38 o superior** (incluye Dart 3.10). Compruébalo con
  `flutter --version`.
* Android Studio (SDK de Android) o Xcode para iOS. Para la versión web basta
  con Chrome o Edge.

## Instalación

```bash
cd pokestudio

# 1. Genera las carpetas android/ e ios/ (no sobrescribe lib/, test/ ni pubspec.yaml)
flutter create . --project-name pokestudio --org mx.ucol --platforms=android,ios

# 2. Dependencias
flutter pub get

# 3. Validación
flutter analyze
flutter test

# 4. Ejecutar en un emulador o celular conectado
flutter run
```

### Paso obligatorio en Android (versión release)

`flutter create` solo concede acceso a internet en modo depuración. Para que
la APK final pueda llamar a PokéAPI, abre
`android/app/src/main/AndroidManifest.xml` y añade, justo antes de
`<application`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Opcional: en esa misma etiqueta `<application>` cambia
`android:label="pokestudio"` por `android:label="PokéStudio"`.

## Probar la versión web en tu computadora (Windows)

Haz doble clic en **`PokeStudio-dev.bat`**. La ventana prepara el proyecto,
compila la versión web y la sirve en <http://localhost:8642> (o en el siguiente
puerto libre, que la ventana indica). La primera vez
tarda unos minutos; déjala abierta mientras pruebas. El servidor
(`tool/dev_server.dart`) también acepta, solo desde tu propio equipo,
órdenes para recompilar, analizar y ejecutar las pruebas.

## Publicar en GitHub Pages

El flujo `.github/workflows/deploy.yml` compila la versión web y la publica
cada vez que se sube algo a `main`. En el repositorio, *Settings → Pages →
Source* debe estar en **GitHub Actions**. La carpeta `web/` incluye el ícono,
el título y la pantalla de carga de PokéStudio (los íconos se generan con
`python tool/generate_web_icons.py`).

## Compilar

```bash
flutter build apk --release          # APK para instalar directamente
flutter build appbundle --release    # para Google Play
flutter build ios --release          # requiere macOS y Xcode
```

## Verificación

Además de `flutter analyze` y `flutter test`, el código se revisó contra el
código fuente real de Flutter 3.38, Riverpod 3.3, go_router 17,
`cached_network_image` 3.4 y `audioplayers` 6.7 (constructores, argumentos con
nombre, `const`, imports), y contra respuestas reales de PokéAPI.

En la web las imágenes se cargan con `Image.network` de Flutter: la versión
web de `cached_network_image` perdía las texturas al cambiar de pestaña y
dejaba cuadros negros.

## Pruebas incluidas

| Archivo | Qué comprueba |
|---|---|
| `test/type_chart_test.dart` | Tabla de tipos: casos simples, doble tipo (×4, ×¼, inmunidades) |
| `test/pokedex_query_test.dart` | Índice real, búsqueda (español/inglés/número/forma), filtros combinados, orden |
| `test/models_test.dart` | Modelos con JSON real de PokéAPI, textos en español y su ausencia |
| `test/api_client_test.dart` | Caché, deduplicación, reintentos, 404, sin conexión, UTF-8, caché en disco |
| `test/preferences_test.dart` | Persistencia de ajustes e historial, destacados deterministas |
| `test/widget_test.dart` | Navegación de las 5 pestañas, riel lateral en computadora, tablet sin desbordes, búsqueda, ficha completa con datos reales |

Los fixtures de `test/fixtures/` son respuestas reales de PokéAPI recortadas.

## Datos

* `assets/data/pokedex_index.json` es una instantánea de PokéAPI (≈240 KB) que
  permite buscar y filtrar al instante. Se generó el 17/10/2026 con
  `tool/generate_pokedex_index.py`. Al abrir la app, si PokéAPI publica
  especies nuevas, se descargan solo esas.
* `lib/shared/domain/type_chart_data.dart` se genera con
  `tool/generate_type_chart.py` desde `/type/{id}`.

Para regenerarlos (solo hace falta con una generación nueva):

```bash
python3 tool/generate_pokedex_index.py       # usa la API en vivo, ~2 050 peticiones pausadas
python3 tool/generate_type_chart.py
```

Hallazgos de los datos: 127 especies (de la #899 en adelante) no tienen
descripción ni categoría en español en PokéAPI; la app muestra el texto en
inglés y lo indica en lugar de inventar una traducción.

## Arquitectura

```
lib/
├── app/        tema, router (GoRouter), barra inferior / riel lateral y medidas adaptables
├── core/       red (PokeApiClient), caché JSON, sonidos, errores, utilidades
├── shared/     modelos, tabla de tipos, repositorios y componentes reutilizables
└── features/   home · pokedex · pokemon_detail · settings · (team_builder, collection, mini_games)
```

Presentación → providers (Riverpod 3) → repositorios → `PokeApiClient` /
caché / índice local. Ningún widget hace peticiones HTTP. Detalles y
decisiones en [`docs/ARQUITECTURA.md`](docs/ARQUITECTURA.md).

## Créditos y licencias

* Datos, sprites, ilustraciones y gritos: [PokéAPI](https://pokeapi.co) y
  [PokeAPI/sprites](https://github.com/PokeAPI/sprites).
* Fuentes: Fredoka, Nunito y Press Start 2P (SIL Open Font License), incluidas
  en `assets/fonts/` y visibles en *Ajustes → Licencias*.
* Efectos de sonido: originales, sintetizados con `tool/generate_sounds.py`.
* Pokémon y sus nombres son marcas de sus respectivos propietarios. Revisa sus
  condiciones antes de distribuir la app públicamente.
