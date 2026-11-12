# CLAUDE.md — PaleShell (fork personal de Caelestia Shell)

Lo fundamental para trabajar en el repo. El detalle de cada función (cómo se hizo, por qué, pruebas)
está en `docs/claude-detalle.md`: búscalo ahí con `grep` cuando toques esa parte.

## Usuario y reglas

- Responde **en español**. Iago usa este fork en su laptop: CachyOS (Arch), GPU AMD,
  `America/Montevideo`, Hyprland **0.56 con config en Lua** (`~/.config/hypr/*.lua`).
- Shell interactiva fish; las herramientas de Claude usan zsh (globs sin match dan error: comillas en
  `--include='*.qml'`, `"${VAR:?}"` en `rm`).
- Thunar (archivos), foot (terminal), Zen (navegador), Obsidian (bóveda `~/Notas`), khal (calendario).
- Pregunta antes de tocar cosas fuera del repo (Hyprland, `~/.config/*`). `~/.config/hypr` y
  `~/.config/caelestia` son repos git locales (sin remoto): ahí nada de `*.bak`, cada cambio va en un
  commit propio con mensaje en español. En el resto, backup `*.bak-<motivo>`.
  Los comandos con `sudo` los ejecuta él: dáselos en un bloque `bash`.
- No hagas commits ni push salvo que lo pida (y solo se ofrecen al cerrar una etapa).
- **Descartado, no reintroducir sin que lo pida**: Loaf, página Water del notch, Sombra al cerrar ventanas, sync con Google
  Calendar (vdirsyncer), apuntes automáticos de clases (whisper + `claude -p`), efectos de "tinta del
  Vacío"/pulso en notificaciones, cabezas del Caballero en workspaces, logo de fastfetch
  (`"logo": null` a propósito), cambio automático isla↔dock por workspace vacío o borde.

## Repositorio

- `~/.config/quickshell/paleshell` (config de Quickshell `paleshell`). Rama de trabajo `mis-cambios`;
  `main` sigue a upstream. Remotos: `origin` = `IagoMaSp/shell`, `upstream` = `caelestia-dots/shell`.
- `~/.config/quickshell/custom-shell` es un symlink a otro proyecto (`~/dev/custom-shell`), no a este.

## Comandos

```bash
qs kill -c paleshell; qs -c paleshell -n -d          # reiniciar (no recarga sola de forma fiable)
qs log -c paleshell | grep -E "WARN|ERROR" | grep -v "notifications\|textinput\|\.face"
cmake --build build                                  # plugin C++ (~30 s), solo si cambias plugin/
python3 scripts/qml-lint-conventions.py              # debe dar "No violations found."
qs -c paleshell ipc show                             # targets IPC; p. ej. notch open <página>
hyprctl dispatch 'hl.dsp.global("paleshell:keybinds")'   # dispatch en Lua
hyprctl reload && hyprctl configerrors
```

- Desde las herramientas, lanzar la shell con `setsid -f qs -c paleshell -n -d` y comprobar con
  `qs list -c paleshell` (a veces no queda corriendo). Una instancia vieja puede recargar a medio
  editar y loguear errores falsos.
- CLI `paleshell <comando>` (`scripts/paleshell`, symlink en `~/.local/bin`): envoltorio de todos los
  IPC con `-h` (`paleshell mascot happy`, `season grimm`, `style pale`, `restart`, `ipc` crudo). Si
  agregas un `IpcHandler`, súmalo a la tabla `COMMANDS` del script.
- IPC útiles para probar: `notch play <animación>`, `notch mascotMenu`, `season set <grimm|winter|auto>`,
  `weather scene <sun|night|cloud|fog|rain|storm|snow|auto>`, `dock toggle`, `hallownest flavour <f>`, `hallownest style <s>`.

## Plugin C++ y `QML_IMPORT_PATH`

- Los módulos `Caelestia.*` están compilados en `build/qml` y **no instalados** (no `sudo cmake
  --install`). Se usan vía `hl.env("QML_IMPORT_PATH", ".../paleshell/build/qml")` en
  `~/.config/hypr/hyprland/env.lua`. Sin la variable: `module "Caelestia.I18n" is not installed`.
- El AUR `caelestia-shell` ya no está (no reinstalar). Del sistema se usan `qt6-m3shapes-git`,
  `caelestia-cli` (comando `caelestia`: esquemas, fondos, grabación, emojis) y `quickshell-git`.
- Si se borra `build/` o sube Qt de versión: `cmake --build build` (reconfigurar:
  `cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DINSTALL_QMLDIR=lib/qt6/qml`).

## Probar sin tocar la shell del usuario

- `zz_*.qml` temporal en la raíz del repo (así resuelven los `qs.*`), lanzado con
  `QML_IMPORT_PATH=$PWD/build/qml timeout 15 qs -p $PWD/zz_x.qml`, y borrarlo después.
- Capturar con `item.grabToImage(r => r.saveToFile(...))` sobre un `Rectangle` (no la raíz de la
  ventana). `grabToImage` recorta a los límites del item y no sirve para efectos con `layer`.
- **Nunca `grim` de la pantalla completa**: solo la geometría de la ventana de prueba o una franja del
  notch. Para el notch con una ventana a pantalla completa: copia temporal `ZzNotchWindow.qml` con
  `hasFullscreen: false`.
- Datos aislados: `XDG_STATE_HOME`/`XDG_CONFIG_HOME` en el scratchpad, `dbus-run-session` para D-Bus,
  `pw-play --volume 0 -P '{ application.name = "X" }' silencio.wav` para streams de audio.
- Archivos temporales en el scratchpad de la sesión, no en `/tmp` ni en el repo.

## Arquitectura

```
shell.qml       ShellRoot que instancia módulos y daemons
modules/        notch/ (isla superior: páginas, mascota, menú de animaciones), dock/ (dock + menú de
                apps con el launcher), launcher/, lock/, notifications/, overview/, emoji/, keybinds/,
                calendar/, session/, nexus/ (ajustes), bar/ (apagada; Home reutiliza sus popouts)…
services/       Singletons (qs.services): Audio, Hallownest, NotchSettings, Season, Weather, Shelf…
components/     Reutilizables; components/hallownest/ = librería visual propia
daemons/        Shortcuts, IdleMonitors, BatteryMonitor…
assets/         Recursos y scripts de runtime (Quickshell.shellPath("assets/x.py"))
scripts/        Herramientas de desarrollo (linter, generadores de esquema/iconos/cursores)
plugin/         Plugin C++ (Config, Tokens, I18n, Services…); build/qml es lo que usa la shell
docs/           claude-detalle.md (detalle histórico)
```

- **Singletons**: un `.qml` con `pragma Singleton` en una carpeta-módulo queda disponible al importarla.
- **Config** `Config.*`/`GlobalConfig.*`: `~/.config/paleshell/shell.json` (definida en C++). **Tokens**
  `Tokens.*`: defaults en `tokens.hpp`, overrides en `shell-tokens.json` (solo duraciones). Ventanas
  propias fijan `contentItem.Config.screen` y `contentItem.Tokens.screen`.
- **Estado** en `~/.local/state/paleshell/` (notch en `notch/`), caché en `~/.cache/paleshell/`. Lo
  que escribe la CLI de caelestia se lee de `Paths.cliState` (`~/.local/state/caelestia`).
- **Atajos**: `CustomShortcut { name: "x" }` → `paleshell:x`; en Hyprland `hl.dsp.global("paleshell:x")`
  con `create_bind(keys, acción, flags, "Sección|Descripción")` en `keybinds.lua` (sin descripción no
  sale en el menú de atajos).
- **IPC**: `IpcHandler { target: "x"; function f(): void {} }` → `qs -c paleshell ipc call x f`.
- **Procesos**: `Process` + `StdioCollector`; no cambies `command` mientras corre.
  `Quickshell.execDetached({command, workingDirectory})` falla aquí: usa `sh -c 'cd "$1" && …'`.
- **Ventanas**: `StyledWindow` (layer-shell, `WlrLayershell.*`) para overlays, `FloatingWindow` para
  ventanas normales, dentro de `LazyLoader`. Toasts: `Toaster.toast(título, texto, icono)`.
- Quickshell solo empaqueta QML alcanzable estáticamente: páginas del notch como
  `Component { Pages.X {} }`, no `Loader { source: url }`.

## Estilo Hollow Knight

- Paleta `Hallownest` (`services/Hallownest.qml`: `void_`, `card`, `steel`, `soul`, `lifeblood`,
  `infection`, `grimm`, `gold`, `unn`, `crystal`, `serif` = Cinzel, `mono`). La UI propia usa esto, no
  `Colours`. Fuente única de colores: `assets/styles.json` = style (`hallownest`, `pale`, `beezone`,
  `void`, `grimm`: base, charms) × flavour (`vessel`, `lifeblood`, `infection`, `greenpath`: accent,
  steel, tertiary, error, success). Ambos viven en `~/.local/state/paleshell/hallownest.json`;
  `Hallownest.setTheme/setStyle/setFlavour` también aplica `caelestia scheme set -n hollowknight -f
  <schemeFlavour>` y los scripts de tema de `assets/` (`<script> <style> <flavour>`, leen el JSON con
  `assets/hkstyle.py`: iconos YAMIS, Zen, Obsidian, Thunar, zathura/btop). `Colours` carga
  `assets/schemes/hollowknight/<schemeFlavour>/dark.txt` (`<flavour>` en hallownest,
  `<style>-<flavour>` en el resto); tras editar el JSON: `python3 scripts/gen-hollowknight-scheme.py`.
  `pale` es claro (`"light": true` → `light.txt`, `caelestia -m light`, Obsidian moonstone): cada nivel
  `void_` → `shell` → `card` → `button` se aleja del fondo, así que en claro `void_` es el más claro y
  el acento es oscuro. Hover con `Hallownest.raise(c, k)`, nunca `Qt.lighter`. `void` es blanco y negro
  (`"mono": true`: la terminal conserva los colores de hallownest).
- Librería `components/hallownest/` (úsala en vez de los controles M3): `HkButton`, `HkField`,
  `HkSwitch`, `HkStepper`, `HkSlider`, `HkCheck`, `HkSelect`, `HkCard` (`ornate`), `HkRow`,
  `HkSection`/`HkTitle`, `HkSelection`, `HkToggle`, `HkRadio`, `Filigree`, `CharmNotches`,
  `IslandShape`, `SoulVessel`, `SoulParticles`, `HealthMask`, `Mask`.
- Animaciones sin rebote (curvas `expressive*` en `tokens.hpp`): `Anim { type: Anim.DefaultSpatial }`.
- Los dibujos del usuario (Inkscape) se pegan como `PathSvg` en coordenadas del SVG: mascota
  (`~/Downloads/hollow.svg`), Hollow Knight (`~/Pictures/InkScape/HK.svg`), máscara de vida, iconos.

## Mapa de funciones (dónde está cada cosa)

- **Notch** (`modules/notch/`): `NotchWindow` por pantalla. Páginas Home, Media, Calendar, Weather,
  Focus + herramientas Clipboard, Shelf, AI, Performance (`NotchPages`; `goTo(i)` sin módulo,
  `step` da la vuelta). Prioridad colapsado: alerta To-Do > alerta de agente > OSD > mascota > reloj.
  Ajustes del notch = `NotchSettings` (`notch/config.json`), editados desde Nexus.
- **Mascota** (`mascot/Knight.qml`): reacciones (`reactionNames`) y gestos (`actionNames`), easter egg
  del Hollow Knight (`bossAnim`/`rageAnim`, 3 %), borde claro en modo Vacío. Menú `Super + F8`
  (`MascotMenu.qml`); una llamada a propósito sale también en modo dock (`summoned`). Selector en
  Nexus → Notch (`NotchSettings.mascotKind`: knight/grimm/hornet; knight pasa a Grimm en temporada
  Grimm). Misma interfaz, `NotchWindow` usa `root.mascot`. `mascot/Grimm.qml` (`grimm.svg`): `boss` =
  Nightmare King, gestos `bow`, `teleport`. `mascot/Hornet.qml` (`hornet.svg`): `boss` = máscara de
  forma final, gesto `dash` (izquierda y derecha); se va con un dash.
- **Notificaciones en el notch** (`NotifView.qml`): diálogo de NPC con tipeo por `Timer`.
- **Home**: centro de control con popouts de la barra en el sitio y mezclador por app
  (`pages/home/Mixer.qml`, streams `PwNodeType.AudioOutStream`).
- **Weather**: escena animada por clima (`pages/weather/WeatherScene.qml`).
- **Temporadas** (`services/Season.qml`): brasas Grimm en octubre, nieve en diciembre.
- **Ajustes** (`modules/nexus/`, IPC `nexus open` o botón Settings de Home; sin atajo): menú propio.
  Páginas en `PageRegistry` (lista) y `PageCompRegistry` (componentes, mismo orden): Style,
  Animations, Notch, Overlays, AI agents, Apps, Network, Bluetooth, Audio, Services, Language &
  region, About. Filas en `nexus/common` (`ToggleRow`, `StepperRow` → `HkStepper`, `SelectRow` →
  `HkSelect`, `NotchToggle`/`NotchStepper` ligadas a una clave de `NotchSettings`). Interruptores de
  animaciones en Animations (`mascot`, `animBench`, `animWeather`, `animSeasons`, `animTyping`, `animGoo`).
  Los controles de `components/controls` usan `Hallownest.*`, no `Colours.palette`.
- **Dock** (`modules/dock/`): `Dock.mode` manual (`Super + F1`), asomar por los bordes, menú de apps =
  launcher (el panel de `drawers` está apagado), animación de gotas (`GooWindow`). Espacio reservado
  para notch/dock en `drawers/Exclusions.qml` (constantes fijas).
- **Launcher**: calculadora directa, web/`@sitio`, `/archivos` (fd), `>tr` (translate-shell), apps ya
  abiertas se enfocan, OCR (`assets/ocr.sh`, `Super + F9`).
- **Calendario** (khal): `services/Events.qml` (`loadRange`, `add`, `update`, `remove`, importar .ics
  con `assets/import-ics.py`), vistas en `pages/calendar/`. khal corta `UNTIL` a las 00:00: se suma 1 día.
- **Bloqueo** (`modules/lock/`): próxima clase, almas de Undertale, juegos en `Arcade.qml` (Dino, Tetris,
  Pac-Man, Buscaminas, Snake, Sudoku; flechas vía `gameKey`, los números no llegan: el Sudoku usa teclado en pantalla).
  Descanso en el banco (`BenchRest.qml`): `IdleMonitors` pone `Lock.resting` 8 s antes del timeout de
  `lock` (viñeta + rayos + motas en una capa Overlay sin entrada; cualquier actividad lo cancela) y
  `LockSurface` abre siempre con destello de Alma y deja los rayos al 50 %. `Bench.qml`: dibujo del
  usuario `assets/hallownest/bench.svg` (capas banco/cuerpo/cabeza/ojos); `scripts/hallownest-bench.py`
  las renderiza a PNG ×4 en `bench/` (rsvg respeta sus desenfoques): rehacer tras editar el SVG.
  Abajo al centro; respira, parpadea, los ojos siguen al ratón (`HoverHandler` en `LockSurface`), alza
  la cabeza al escribir, niega lento al fallar y se queda quieto al desbloquear. También sale en el oscurecido.
- **AI** (`pages/Ai.qml`): abre las consolas del asistente (`hyprctl dispatch 'require("utils.functions").toggle("claude")'`),
  límites de Claude y Antigravity (`services/AiUsage.qml` → `assets/ai-usage.py <claude|agy>`: OAuth
  `api/oauth/usage` de Anthropic y `retrieveUserQuotaSummary` de Google con el token del keyring; caché 5 min),
  sesiones en vivo y aprobaciones vía hooks
  (`assets/agent-hook.py` → socket `$XDG_RUNTIME_DIR/paleshell/agents.sock`; el relay nunca bloquea).
- **Asistente** (`Super + A` Claude Code, `Super + Shift + A` Antigravity): consola desplegable =
  espacios especiales `special:claude`/`special:agy` (toggles en `~/.config/caelestia/cli.json`,
  geometría en `rules.lua`, `dim_special` en `decoration.lua`). `assets/assistant.sh <cli>` lo lanza
  en `~/.local/share/paleshell/assistant` (CLAUDE.md/AGENTS.md → `assets/assistant/CLAUDE.md`).
  La skill `assets/assistant/skills/paleshell` está enlazada en `~/.claude/skills` y
  `~/.gemini/config/skills`: actualízala si cambian la CLI `paleshell` o los atajos.
- Otros: overview `Super + Tab`, emojis, portapapeles (cliphist), capturas al Shelf, grabación,
  KDE Connect (archivos recibidos al Shelf), cursor y tema de iconos propios, SDDM en `assets/sddm/`.

## Convenciones

- Orden en cada objeto QML: `id`, propiedades, señales, funciones, bindings, hijos, `component`s, con
  línea en blanco entre secciones; imports ordenados. Lo verifica el linter.
- `pragma ComponentBehavior: Bound`, `required property` en delegados y referencias por `id`.
- Textos de UI en inglés con `Tr.tr(...)`; datos del usuario (atajos, eventos) en español. Textos
  marcados con `mark()` en C++ se muestran con `Tr.trMarked`.
- Fechas visibles con `Qt.locale().toString(date, "d MMMM yyyy")`.
- 4 espacios (JSON/YAML con 2). Comentarios escasos y en inglés.

## Trampas conocidas

- `Tokens.spacing`/`Tokens.padding` no tienen `normal` (válidos: `extraSmall` … `extraExtraLarge`).
- JS V4: sin `String.matchAll` ni `Array.flatMap`. `list<var>` no tiene todos los métodos: usa `var`.
- `maximumLineCount` con `NaN` tumba quickshell (SIGSEGV). `.arg()` encadenado re-sustituye `%1`.
- Propiedades FINAL de Item (p. ej. `bottom`) no se pueden redeclarar; `palette` choca con la de Item.
- `MaterialIcon`: tamaño con `fontStyle`, nunca `font.pointSize` (pierde la fuente de iconos).
- Con `layer.enabled` el efecto solo dibuja dentro del item (extiende el item, `sourceRect` no basta).
  No uses `layer.enabled` en fuentes `visible: false` que se mueven (se congela).
- Animaciones de Qt avanzan por cuadros: para algo que debe terminar sí o sí (tipeo), `Timer`.
- Foco de teclado en overlays: `focus: true` declarativo; `GridView` con `interactive: false` necesita
  `keyNavigationEnabled: true`.
- `HyprlandFocusGrab` activado en el mismo instante que la zona de entrada se suelta: va con retardo.
- Si `shell-tokens.json` tiene `appearance.curves`, la shell lo reescribe con `null`.
- Dos instancias (`qs -p .` con la shell corriendo) duplican todo: `qs kill` antes o `-n`.
- `Failed to open VDPAU backend libvdpau_nvidia.so` es inofensivo.

## Fuera del repo

| Archivo | Para qué |
|---|---|
| `~/.config/hypr/hyprland/env.lua` | `QML_IMPORT_PATH`, cursor |
| `~/.config/hypr/hyprland/execs.lua` | Autoarranque (`qs -c paleshell -n -d`, `kdeconnectd`) |
| `~/.config/hypr/hyprland/keybinds.lua` | Atajos con descripción. Fila F (sin / con Super): F1 notch / isla↔dock, F2 overview / espacio especial, F3 portapapeles / menú de atajos, F4 pantalla completa / maximizar, F5 lupa / color picker, F6 atrás / adelante, F8 emojis / menú de la mascota, F9 captura de región / OCR, F10 play / siguiente, F11 silenciar / mic, F12 e Insert volumen / brillo |
| `~/.config/hypr/variables.lua` | Apps y teclas por defecto, `cursorTheme` |
| `~/.config/paleshell/shell.json` | Config (barra apagada con `bar.excludedScreens`, `launcher.enabled: false`) |
| `~/.config/caelestia/cli.json` | Tema de iconos (`YAMIS-Hallownest`) que aplica la CLI |
| `/usr/lib/python3.14/site-packages/caelestia/data/schemes/hollowknight` | Symlink a `assets/schemes/hollowknight` (rehacer si cambia Python) |

En Hyprland, `MOD5` es AltGr (128); Super 64, Ctrl 4, Alt 8, Shift 1.
