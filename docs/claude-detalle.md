# Detalle histórico de PaleShell (versión completa de CLAUDE.md al 2026-11-06)

Guía de contexto para trabajar en este repo. Léela entera antes de tocar código: resume la
arquitectura, los comandos de uso diario, las trampas ya descubiertas y todo lo que se cambió
respecto a upstream.

## Contexto del usuario

- Responde **en español**. El usuario (Iago) usa este fork en su laptop personal.
- Sistema: CachyOS (Arch), kernel CachyOS, GPU AMD, zona horaria `America/Montevideo`.
- Hyprland **0.56** con configuración en **Lua** (`~/.config/hypr/*.lua`), no en `hyprland.conf`.
- Shell interactiva: fish. Las herramientas de Claude ejecutan zsh: cuidado con globs que no
  matchean (`zz_*` sin resultados da error) y usa comillas en `--include='*.qml'`.
- Gestor de archivos: Thunar (`thunar.desktop` es el predeterminado para carpetas). Tema de
  iconos: Papirus-Dark. Terminal: foot. Lanzador de menús: rofi/fuzzel.
- Se probó **Loaf** (gestor de archivos en Rust + Qt) como reemplazo de Thunar y el usuario lo
  descartó porque no le funcionaron varias cosas: se quitó todo. No reintroducir sin que lo pida.
- Prefiere que se le pregunte antes de tocar cosas fuera del repo (config de Hyprland, `sudo`).
  Cualquier comando con `sudo` lo ejecuta él: dale el comando en un bloque `bash`.

## Repositorio

- Ruta: `~/.config/quickshell/paleshell` (quickshell lo encuentra como config `paleshell`).
- Rama de trabajo: **`mis-cambios`**. `main` sigue a upstream.
- Remotos: `origin` = `git@github.com:IagoMaSp/shell.git` (fork), `upstream` =
  `https://github.com/caelestia-dots/shell.git`.
- No hagas commits ni push salvo que el usuario lo pida.
- `~/.config/quickshell/custom-shell` es un symlink a `~/dev/custom-shell`, otro proyecto aparte
  (se ejecuta con `qs -p ~/dev/custom-shell`). No forma parte de este repo.

## Comandos frecuentes

```bash
# Reiniciar la shell (NO recarga sola al guardar archivos)
qs kill -c paleshell; qs -c paleshell -n -d

# Logs de la instancia en ejecución (filtrando ruido conocido)
qs log -c paleshell | grep -E "WARN|ERROR" | grep -v "notifications\|textinput\|\.face"

# Recompilar el plugin C++ (tarda ~30 s). Necesario solo si cambias plugin/
cmake --build build

# Verificar convenciones QML (orden de secciones e imports). Debe dar "No violations found."
python3 scripts/qml-lint-conventions.py
python3 scripts/qml-lint-conventions.py --fix --file ruta/al/archivo.qml   # --fix solo arregla imports

# IPC: listar targets/funciones y llamarlas
qs -c paleshell ipc show
qs -c paleshell ipc call notch open media      # toggle/open <página>/close/pages
qs -c paleshell ipc call keybinds toggle

# Disparar un atajo global de la shell como lo haría Hyprland (sintaxis Lua obligatoria)
hyprctl dispatch 'hl.dsp.global("paleshell:keybinds")'

# Hyprland
hyprctl reload && hyprctl configerrors
hyprctl binds -j            # atajos cargados (con descripción)

# Esquema de colores
caelestia scheme set -n hollowknight -f vessel -m dark
caelestia scheme set -n dynamic        # volver a colores del fondo de pantalla
```

### El plugin compilado y `QML_IMPORT_PATH`

El paquete AUR `caelestia-shell` **ya no está instalado** (se quitó el 2026-10-27: su versión
2.5.0 sacó `M3Shapes` a `qt6-m3shapes-git`, que chocaba con la 2.2.0 y bloqueaba `paru -Syu`). No
reinstalarlo. Del sistema solo se usan:
- `qt6-m3shapes-git` (módulo QML `M3Shapes`, en `/usr/lib/qt6/qml/M3Shapes`).
- `caelestia-cli` (comando `caelestia`, esquemas).
- Sus antiguas dependencias (`quickshell-git`, fuentes, `libcava`, `libqalculate`, `aubio`...),
  marcadas como explícitas.

El plugin C++ (`Caelestia.*`) está compilado en `build/qml` y **no está instalado** en el sistema
(no ejecutes `sudo cmake --install`). Se usa mediante:

```lua
-- ~/.config/hypr/hyprland/env.lua
hl.env("QML_IMPORT_PATH", "/home/iago/.config/quickshell/paleshell/build/qml")
```

Hyprland lanza la shell al iniciar sesión con `qs -c paleshell -n -d` (`hyprland/execs.lua`),
heredando esa variable. Las terminales abiertas desde Hyprland
también la tienen. Si un `qs` falla con `module "Caelestia.I18n" is not installed`, falta la
variable: lanza con `QML_IMPORT_PATH=$PWD/build/qml qs -c paleshell -n -d`.
Si se borra `build/`, la shell no arranca hasta volver a compilar. Tras un `paru -Syu` que suba
Qt de versión (p. ej. 6.12 → 6.13), recompila con `cmake --build build` y reinicia la shell.

### Probar cambios sin tocar la shell del usuario

Patrón usado con éxito: crear un `zz_*.qml` temporal en la raíz del repo (para que resuelvan los
imports `qs.*`), lanzarlo como instancia separada y borrarlo después.

```bash
cat > zz_test.qml <<'EOF'
import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.notch.pages.calendar

ShellRoot {
    FloatingWindow {
        title: "Dash test"
        implicitWidth: 760
        implicitHeight: 440
        color: Colours.tPalette.m3surface
        contentItem.Config.screen: screen?.name ?? ""
        contentItem.Tokens.screen: screen?.name ?? ""
        Week { anchors.fill: parent; anchors.margins: 20 }
    }
}
EOF
QML_IMPORT_PATH=$PWD/build/qml timeout 14 qs -p $PWD/zz_test.qml > log.txt 2>&1 &
sleep 7
G=$(hyprctl clients -j | python3 -c "import json,sys
for c in json.load(sys.stdin):
    if c['title']=='Dash test': print('%d,%d %dx%d'%(c['at'][0],c['at'][1],c['size'][0],c['size'][1]))")
grim -g "$G" captura.png      # captura SOLO esa ventana
rm -f zz_test.qml
```

- **Nunca hagas `grim` de la pantalla completa**: captura lo que el usuario tenga abierto.
  Captura solo la geometría de la ventana de prueba.
- Para aislar datos (p. ej. un calendario khal de prueba), lanza con `XDG_CONFIG_HOME=<dir>`
  apuntando a una config falsa. Ojo: entonces la shell no ve el tema de iconos ni `shell.json`.
- Ventanas con fondo opaco (`color: Colours.palette.m3surface`) para no capturar lo de detrás.
- Los archivos temporales van al scratchpad de la sesión, no a `/tmp` ni al repo.

## Arquitectura

QML (Quickshell) + plugin C++ propio (módulos QML `Caelestia.*`).

```
shell.qml            Punto de entrada: ShellRoot que instancia módulos y daemons
modules/             Funcionalidades visibles (cada carpeta = módulo qs.modules.<nombre>)
  drawers/           Ventana principal por pantalla que aloja los paneles deslizables
  notch/             [fork] Isla superior (reemplaza al dashboard y al OSD): ver sección Notch
  calendar/          [fork] Ventana flotante de eventos del día + importador .ics
  keybinds/          [fork] Menú de atajos de teclado (Super + F3)
  launcher/ (Content del menú del dock) sidebar/ utilities/toasts/ notifications/ session/
  lock/ background/ areapicker/ nexus/ (ajustes)
services/            Singletons de datos (qs.services): Audio, Colours, Weather, Players...
  Events.qml         [fork] Eventos de calendario vía khal
components/          Componentes reutilizables (qs.components, .controls, .containers...)
utils/               Utilidades (Paths, Icons, Strings...) y scripts JS (fzf, fuzzysort)
daemons/             Lógica en segundo plano (Shortcuts, IdleMonitors, BatteryMonitor...)
assets/              Recursos y scripts de runtime (import-ics.py, schemes/, pam.d...)
scripts/             Herramientas de desarrollo (linter QML, traducciones, generador de esquema)
plugin/src/Caelestia/ Plugin C++: Config (config + tokens), I18n, Services, Components...
build/               Salida de CMake; build/qml es el plugin que usa la shell
```

### Conceptos clave

- **Singletons**: cualquier `.qml` con `pragma Singleton` dentro de una carpeta-módulo queda
  disponible por nombre al importar ese módulo (`import qs.services` → `Events`, `Colours`...).
  No hace falta `qmldir`.
- **Módulos nuevos**: crear `modules/<nombre>/` e instanciar en `shell.qml` (importar
  `qs.modules.<nombre>`).
- **Config de usuario** (`Config.*`, `GlobalConfig.*`): `~/.config/paleshell/shell.json`,
  definida en C++ (`plugin/src/Caelestia/Config/*config.hpp`). La shell avisa
  `Unknown option` si hay claves obsoletas.
- **Tokens** (`Tokens.*`): tamaños, espaciados, fuentes, curvas y duraciones de animación.
  Defaults en `plugin/src/Caelestia/Config/tokens.hpp`; overrides en
  `~/.config/paleshell/shell-tokens.json`. Ventanas propias deben fijar
  `contentItem.Config.screen` y `contentItem.Tokens.screen`.
- **Colores**: `Colours.palette.m3*` (Material 3) y `Colours.tPalette` (con transparencia).
  [fork] Tema fijo Hollow Knight: `Colours` ya NO lee `scheme.json`; carga
  `assets/schemes/hollowknight/<flavour>/dark.txt` según `Hallownest.flavour` (vessel,
  lifeblood, infection, greenpath), guardado en `~/.local/state/paleshell/hallownest.json`.
  Se cambia con `qs -c paleshell ipc call hallownest flavour <nombre>` o en Settings del notch;
  `Hallownest.setFlavour` también ejecuta `caelestia scheme set -n hollowknight -f <flavour>`
  para que GTK/Qt/terminal sigan el tema. El selector de esquemas de Nexus, `>scheme` del
  launcher y el modo claro solo afectan a las otras apps (la shell los ignora).
- **Animaciones**: `Anim { type: Anim.DefaultSpatial }` / `CAnim` para colores. Los tipos se
  mapean a curvas y duraciones de los tokens.
- **Atajos globales**: `CustomShortcut { name: "x" }` registra `paleshell:x`; en Hyprland se
  enlaza con `hl.dsp.global("paleshell:x")`.
- **IPC**: `IpcHandler { target: "x"; function f(): void {...} }` → `qs -c paleshell ipc call x f`.
- **Procesos externos**: `Process { command: [...]; stdout: StdioCollector { onStreamFinished: ... } }`.
  No cambies `command` mientras corre: encola y relanza en `onExited`.
- **Ventanas**: `StyledWindow` (layer-shell; `WlrLayershell.layer`/`keyboardFocus`) para
  overlays; `FloatingWindow` para ventanas normales (Hyprland las hace flotar por la regla de
  clase `org.quickshell`). Envolver en `LazyLoader` para crearlas bajo demanda.
- **Notificaciones internas**: `Toaster.toast(titulo, texto, icono)`.
- **Scripts de runtime**: ponerlos en `assets/` y referenciarlos con
  `Quickshell.shellPath("assets/x.py")`.

### Librería Hallownest (`components/hallownest/`, `import qs.components.hallownest`)

Componentes propios con la paleta fija `Hallownest` (`services/Hallownest.qml`: colores,
`serif` = Cinzel, `mono`, flavour). Úsalos en vez de los controles M3 de `components/controls`
al rediseñar módulos.

| Componente | Para qué |
|---|---|
| `HkButton` | Píldora: `icon`, `text`, `filled`, `tinted` + `accent`, `disabled`, `iconAfter` |
| `HkField` | Campo de texto en píldora (`leadingIcon`) |
| `HkSwitch` | Interruptor con rombo (`checked`, señal `toggled(checked)`) |
| `HkStepper` | − valor + (`value`, `from`, `to`, `stepSize`, `suffix`, señal `moved`) |
| `HkSlider` | Barra fina con punta de Aguijón (`value`, `colour`, señal `moved`) |
| `HkCheck` | Círculo de color que se rellena con check |
| `HkSelect` | Desplegable (`options` strings u objetos `{text}`, `currentIndex`, `activated`) |
| `HkCard` | Tarjeta oscura con borde; `ornate` añade filigrana |
| `HkSection` / `HkTitle` | Cabecera de sección / título en Cinzel |
| `Filigree` | Ornamento de esquinas inferiores (`radius`, `inset`) |
| `CharmNotches` | Muescas de amuleto con flechas (`notches`, `current`, `selected`, `stepped`) |
| `IslandShape` | Forma pegada al borde superior con fillets (`w`, `h`, `radius`, `leftFillet`, `rightFillet`) |
| `SoulVessel` / `SoulParticles` | Orbe con líquido / partículas de Alma |
| `HkSelection` | Resaltado de lista con punteros ornamentados (`radius`, `inset`, `colour`) |
| `HkRadio` | Opción con rombo que se rellena (`checked`, `text`, `accent`, señal `clicked`) |
| `HealthMask` | Máscara de vida: dibujo del usuario (`assets/hallownest/health-mask.svg`, recortado de `~/Pictures/InkScape/healthMask.svg`: PNG incrustado + calco vectorial); `filled`, `colour` (tinte), `glow` |
| `Mask` | Máscara de vida (silueta del Caballero con ojos): `filled`, `colour`, `glow`, `size` |

Etapa 3 (rediseño por módulos), hecho hasta ahora:
- Barra: workspaces como máscaras de vida del juego (`HealthMask`, forma de huevo con punta y
  ojos ovalados; en `Workspace.qml`, `shapeComponent`: activa blanca con brillo, ocupada acero,
  vacía apagada). El usuario rechazó las cabezas del Caballero ahí; indicador activo = píldora tenue con borde. Batería =
  mini `SoulVessel` (`ornate: false`; Lifeblood cargando, rojo ≤20 %). Apagado dentro de un
  rombo rojo Grimm.
- Popouts de la barra: cabeceras en Cinzel acero; dispositivos de audio con `HkRadio` (rombo),
  volumen con `HkSlider` Lifeblood, interruptores `HkSwitch`, "Open settings" como `HkButton`
  teñido; reescanear redes y selector de perfil de energía con píldoras tenues. `TrayMenu`,
  `ActiveWindow` y `WirelessPassword` solo heredan la paleta.
- Launcher: la selección es `HkSelection` (fondo tenue + punteros en rombo a los lados que
  laten, como en los menús del juego); los ítems dejan 16 px extra a cada lado para ellos. Nombre
  en blanco Alma, descripción gris, favoritas = rombo dorado. `SearchBar` (compartida con Nexus
  y el menú de atajos): fondo `card`, borde acero que pasa a Alma con foco. Estado vacío con
  título en Cinzel.
- Toasts de la shell (`utilities/toasts/ToastItem.qml`): fondo Vacío, icono en rombo y borde del
  color del tipo (info Alma, éxito Unn, aviso Oro, error Grimm), título en Cinzel.
- Dock de notificaciones del sidebar: cabecera y contador en Cinzel, grupos como tarjetas con
  borde, botón de limpiar `HkButton`; sin notificaciones muestra una `Mask` apagada y "All up to
  date!" en Cinzel (ya no usa `Config.paths.noNotifsPic`).
- Notificaciones emergentes (`notifications/Notification.qml`): fondo Vacío con borde acero;
  críticas con tinte y borde rojo Grimm. Título en Cinzel (rojo si es crítica), icono de app sobre
  círculo tenue, acciones como `HkButton` en un `RowLayout`. Las del dock usan la misma paleta.
- Menú de sesión (`session/Content.qml`): `SessionButton` propio (tarjeta 80 px con icono y
  etiqueta en Cinzel; enfocado o con hover se ilumina en su color: Logout Alma, Shutdown Grimm,
  Hibernate Lifeblood, Reboot Oro) y rombo indicador a la izquierda del enfocado. El hover da el
  foco; teclado (flechas, Tab, vim) igual que antes.
- Pantalla de bloqueo: reloj en Cinzel (horas Alma con brillo, minutos acero), fecha en Cinzel
  con rombo; sin foto de perfil (el usuario la quitó: espacio libre entre fecha y contraseña);
  contraseña con rombos de Alma por carácter y botón de enviar en rombo; CPU/RAM/disco como
  `SoulVessel` con texto contorneado y temperatura en píldora; clima con `WeatherIcon` del
  notch; tarjetas con borde; fetch rebautizado `hallownest.sh` (logo del sistema o máscara).
- Controles base (`components/controls/`, afectan a toda la shell y a Nexus): `StyledSwitch`
  con rombo, `ButtonBase` en píldora con borde y sin morph de
  formas, `StyledSlider` en blanco Alma sobre pista acero.
- Nexus: títulos de página y `SectionHeader` en Cinzel, `ConnectedRect` = `card`, menú lateral
  con tarjetas con borde y la sección activa resaltada en blanco tenue.
- Etapa 3 completa. Etapa 4 (independizarse de Caelestia: nombre, IPC, atajos, carpetas) pendiente.

## Convenciones de código

- Orden dentro de cada objeto QML: `id`, propiedades, señales, funciones, bindings, hijos,
  `component`s, con una línea en blanco entre secciones. Imports ordenados (`qs.services` antes
  que `qs.modules.*`). Verificar con `scripts/qml-lint-conventions.py`.
- `pragma ComponentBehavior: Bound` y `required property` en delegados; referenciar por `id`
  (`root.x`, `card.modelData`).
- Textos de UI con `Tr.tr("English text")` / `Tr.trCtx(...)`: la UI de la shell está en inglés
  (`LANG=en_US`). Los datos del usuario (descripciones de atajos, eventos) van en español.
- Fechas visibles: `Qt.locale().toString(date, "d MMMM yyyy")` (sale en español como el
  calendario). `Qt.formatDate` usa otra locale y mezcla idiomas.
- Indentación de 4 espacios (`.editorconfig`); JSON/YAML/nix con 2.
- Comentarios escasos y en inglés, como el resto del código.

### Trampas conocidas (ya costaron tiempo)

- **Tokens inexistentes**: `Tokens.spacing` y `Tokens.padding` NO tienen `normal`. Válidos:
  `extraSmall, small, medium, large, largeIncreased, extraLarge, extraLargeIncreased,
  extraExtraLarge`. Un token inexistente da `Unable to assign [undefined]`.
- **JS de Qt (V4)**: no hay `String.matchAll` ni `Array.flatMap`. Usa `exec` en bucle y
  `reduce/concat`.
- **`list<var>`**: las propiedades y parámetros `list<var>` no tienen todos los métodos de array.
  Usa `property var` / parámetros `var` para arrays JS.
- **Crash de Qt**: `maximumLineCount` con `NaN` (p. ej. dividir por `fontInfo.pixelSize` antes
  del layout) tumba quickshell con SIGSEGV en `QTextLine`. Usa valores enteros seguros.
- **`.arg()` encadenado**: `.arg("%1").arg(x)` vuelve a sustituir el `%1` insertado.
- **`hyprctl dispatch`** en Hyprland Lua requiere sintaxis Lua:
  `hyprctl dispatch 'hl.dsp.exec_cmd("...")'`.
- **Bug del plugin**: si `shell-tokens.json` contiene `appearance.curves`, la shell reescribe el
  archivo dejando las curvas en `null`. Las curvas se cambian en `tokens.hpp` + recompilar; en el
  JSON solo poner duraciones (enteros funcionan).
- **Dos instancias**: lanzar `qs -p .` con la shell ya corriendo duplica la barra y da
  `Could not register notification server`. Usa `qs kill -c paleshell` antes o `-n`.
- **Iconos rotos** (cuadrados negro/magenta) en el `FileDialog` propio de la shell: no encuentra
  el tema de iconos de Qt. Por eso el importador usa zenity (selector GTK).
- `Failed to open VDPAU backend libvdpau_nvidia.so` es inofensivo (GPU AMD).

## PaleShell (etapa 4: independizarse de Caelestia)

- Nombre: **PaleShell**. Carpeta `~/.config/quickshell/paleshell` (config de Quickshell
  `paleshell`); se arranca con `qs -c paleshell -n -d`. La rama sigue siendo `mis-cambios` y el
  remoto de GitHub sigue siendo `IagoMaSp/shell` (renombrarlo quedó para más adelante).
- Carpetas propias (`utils/Paths.qml` + plugin C++ `Config/common.cpp`, `State/common.cpp`,
  `lyrics.cpp`, `imagecache.cpp`): `~/.config/paleshell` (`shell.json`, `shell-tokens.json`),
  `~/.local/state/paleshell`, `~/.cache/paleshell`, `$XDG_RUNTIME_DIR/paleshell`. Se copiaron los
  datos viejos de `caelestia`; los originales siguen ahí.
- Atajos globales `paleshell:*` (`CustomShortcut.appid`), namespaces de capas `paleshell-*`
  (`StyledWindow`, reglas de Hyprland y `Colours.reloadHyprRules`).
- Se sigue usando la CLI `caelestia` (fondos, grabación, capturas, portapapeles, emojis, tema de
  GTK/Qt/terminal). Lo que ella escribe se lee de `Paths.cliState` (`~/.local/state/caelestia`,
  p. ej. `wallpaper/path.txt`). `~/.config/caelestia/` sigue siendo de la CLI y de los dots de
  Hyprland (`hypr-vars.lua`, `hypr-user.lua`, `cli.json`). No uses `caelestia shell ...` (abre la
  config vieja): usa `qs -c paleshell ipc call ...`.
- El plugin C++ conserva sus módulos `Caelestia.*` y el namespace `caelestia::` (renombrarlo no
  aporta nada visible).
- Hyprland editado (backups `*.bak-paleshell`): `env.lua`, `execs.lua`, `keybinds.lua`,
  `rules.lua`, `utils/functions.lua`.
- Tras mover la carpeta hubo que reconfigurar CMake: `rm -rf build/CMakeCache.txt build/CMakeFiles
  && cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DINSTALL_QMLDIR=lib/qt6/qml`.

## Cambios del fork respecto a upstream

### Eliminado
- GIF de `kurukuru` en el menú de sesión (`modules/session/Content.qml`) y `bongocat` del
  dashboard. Los assets `.gif` siguen en `assets/` sin uso.
- **Dashboard** (`modules/dashboard/`) y **OSD lateral** (`modules/osd/`, borrado en la limpieza de 2026-11-12):
  sustituidos por el notch. Sus restos se quitaron de `modules/drawers/` (`Panels`, `Regions`,
  `Interactions`, `ContentWindow`). `ScreenState.dashboard/osd/dashboardTab/dashboardKeyboard`
  ya no existen. La entrada "Dashboard" de Nexus (`DashboardPanel`) también se borró.
- **Barra izquierda, panel de utilidades, launcher de `drawers` y `windowinfo`** (2026-11-22):
  borrados. Estaban apagados por `shell.json` y Home ya tenía sus propias tarjetas. También se
  quitaron Nix (`flake.nix`, `nix/`, `.envrc`), `.github` de upstream, el binario `extras/version`
  y la instalación de CMake en `/etc/xdg/quickshell/caelestia`. Se mantienen el plugin
  `Caelestia.*` y la CLI `caelestia` (emojis, esquemas, grabación, fondos).
- Página Water del notch: se descartó por decisión del usuario. No reintroducir sin que lo pida.
- Sincronización con Google Calendar (vdirsyncer): se implementó y se quitó por decisión del
  usuario. No reintroducir sin que lo pida.
- Apuntes automáticos de clases (grabación con `pw-record`, whisper.cpp y resumen con
  `claude -p`; servicio `Lectures`, tarjeta de utilidades, píldora de barra, atajo
  `Super + Shift + R`): se quitó porque consumía demasiado de la cuenta de Claude. No
  reintroducir sin que lo pida.

### Calendario y eventos (khal)
- Backend: **khal** (`~/.config/khal/config`, calendario `private` en
  `~/.local/share/khal/calendars/private`). Formatos de fecha `%d/%m/%Y`, hora `%H:%M`.
- `services/Events.qml`:
  - Deriva los formatos Qt de `khal printformats`.
  - Lista con `khal list` usando separadores de control (`\x1d` día, `\x1e` registro,
    `\x1f` campo), porque la salida `--json` de khal no indica el día de los eventos multi-día.
  - `loadRange(key, start, end)` / `loadMonth(y, m, key)`: cada vista pide su rango
    (`calendar`, `week`, `window`) y se carga la unión.
  - `add()` usa `khal new` con `--repeat weekly --until`. **khal corta el `UNTIL` a las 00:00
    del día dado**, así que se suma 1 día para que la fecha límite sea inclusiva.
  - `remove(uid)` borra el `.ics` vía script Python (`khal.settings.get_config`); borra todas
    las repeticiones.
  - `importFile(path)` ejecuta `assets/import-ics.py`.
  - Recarga cada 15 min.
- `assets/import-ics.py`:
  - Recorta basura tras `END:VCALENDAR`.
  - Reemplaza TZIDs estilo Windows (`(UTC-03:00) Montevideo`, con reglas DST obsoletas que
    adelantaban todo 1 hora) por la zona IANA y elimina ese VTIMEZONE.
  - Importa con `khal import --batch` (si se reimporta, actualiza por UID) y borra los restos
    `<uid>.ics<8 chars>` que khal 0.14 deja al actualizar.
  - Probado con el horario de la Universidad de Montevideo (`~/Downloads/2026_sem2_*.ics`).
- `modules/calendar/`:
  - `EventsWindow` (singleton; ventana flotante del día).
  - `DayEvents` (lista de eventos + formulario: todo el día, semanal + "hasta", lugar, notas).
  - `ScheduleImporter` (singleton; zenity `--file-selection` con fallback al `FileDialog`).
- `modules/notch/pages/calendar/MonthGrid.qml` (antes `dash/Calendar.qml`): puntos de color en
  días con eventos; clic en un día abre `EventsWindow`. Mes en `ScreenState.calendarDate`.
- `modules/notch/pages/calendar/Week.qml`: vista semanal (lunes a domingo según la locale):
  - Rejilla de horas, 8–20 por defecto; se amplía si hay eventos fuera de ese rango.
  - Bloques por evento, con carriles para los que se solapan.
  - Franja de eventos de todo el día.
  - Línea de la hora actual.
  - Navegación por semanas y botón de importar `.ics`.
- `modules/notch/pages/Calendar.qml`: mes a la izquierda, semana a la derecha.
- Fuera del repo: `~/.local/bin/caelestia-add-event` (rofi + `khal new`, atajo
  `Super + Ctrl + E`).
- **Editar eventos**: lápiz en cada tarjeta de `DayEvents` → el mismo `EventForm` con `event`
  precargado, en el lugar de la tarjeta. `Events.update(uid, data)` ejecuta
  `assets/edit-event.py`, que modifica el `.ics` en su sitio con `icalendar` (conserva UID,
  zona horaria, `BYDAY`, alarmas, excepciones; sube `SEQUENCE`). En series los cambios aplican
  a todas las repeticiones y se mantiene el día de inicio; `COUNT` se conserva salvo que se
  toque "Until"; `UNTIL` inclusivo (23:59:59 local en UTC). Reimportar el `.ics` de la facultad
  pisa las ediciones de esos eventos (mismo UID).
- Ideas pendientes: borrar de una vez todo lo importado de un archivo.

### Notch (isla superior, estilo Nusa)
- `modules/notch/`: `Notch.qml` (una `NotchWindow` por pantalla + `IpcHandler` `notch`:
  `toggle`, `open <página>`, `close`, `pages`), `NotchWindow.qml`, `Collapsed.qml` (reloj +
  cuenta del pomodoro + indicador de música), `PageDots.qml`, `NotchPages.qml` (lista de
  páginas), `NotchPage.qml` (base), `mascot/Knight.qml`, `pages/`.
- Ventana layer-shell anclada arriba, tamaño fijo, `mask` = solo la píldora (+ píldora de
  letras). Forma: `Shape` pegada al borde superior con esquinas cóncavas (`fillet`) y solo las de
  abajo redondeadas. Escala con `NotchSettings.scale` (transform del contenido).
- Estados de la píldora colapsada, por prioridad: alerta To-Do (`alertShown`, no se expande al
  hover para poder pulsar los botones) > OSD (`osdShown`) > mascota (`mascotShown`) > reloj.
  `minimal` = línea fina. Se expande con hover (80 ms de entrada, 250 ms de salida), con
  `ScreenState.notch` (atajo `paleshell:notch`, fija abierto hasta `Esc`/clic fuera), al
  arrastrar algo encima y mientras se arrastra desde el Shelf. En pantalla completa
  (`fullscreenHidden`) solo se ve con el atajo (no se expande por hover) o con alertas, OSD y
  notificaciones; reloj, mascota e isla de letras siguen ocultos. La capa pasa a `Overlay` para
  quedar encima de la ventana.
- Páginas (`NotchPages.pages`, las que recorren flechas/rueda/muescas): Home, Media, Calendar,
  Weather, Focus. Herramientas (`NotchPages.tools`, fuera de las muescas, con "←" a Home):
  Clipboard, Shelf, AI, Performance, Settings. `ScreenState.notchPage` indexa `NotchPages.all`;
  `NotchPages.find(id)` para abrir por id (IPC `notch open <id>` acepta ambas). `goTo(i)` asigna el
  índice tal cual (sirve para herramientas); solo `step` da la vuelta entre las 5 páginas. Antes
  `goTo` hacía módulo y arrastrar un archivo abría Media en vez de Shelf.
  - `pages/Home.qml`: centro de control (Wi-Fi, Bluetooth, batería/perfil, volumen, mini
    reproductor, botones de herramientas, tray y apagado). El chevron de cada fila muestra en el
    sitio el popout de la barra (`Popouts.Network`/`WirelessPassword`/`Bluetooth`/`AudioPopout`/
    `Battery`) con un `PopoutState` local; "Open settings" abre Nexus. Pensado para quitar la barra.
  - `pages/Focus.qml`: `Pomodoro` encima de `Todo` (ya no son páginas sueltas).
- Navegación: cabecera arriba (título de página en Cinzel a la izquierda, muescas de amuleto
  en rombo al centro con flechas < >, fecha + hora a la derecha), rueda, flechas del teclado.
  El usuario prefiere la navegación arriba (no abajo como Nusa).
- Estilo Hollow Knight con colores **fijos** (no siguen el esquema): `services/Hallownest.qml`
  (Negro Vacío, Acero de Aguijón, Alma, Lifeblood, Infección, colores de amuletos; `serif` =
  Cinzel cargada con `FontLoader` desde `assets/fonts/cinzel/`, OFL). Fondo `void_`, borde
  acero al 15 %, sombra amplia que pasa a brillo Lifeblood con música o pomodoro activos,
  filigrana en las esquinas inferiores al expandir (`component Filigree`).
- Rediseño estilo Nusa + Hollow Knight hecho en 4 fases (A contenedor/cabecera, B colapsado +
  caras, C Media + isla de letras, D productividad + alertas). Water sigue descartado.
  Iconos del clima (`pages/weather/WeatherIcon.qml`) dibujados con `Shape` en un lienzo de
  48 unidades (trazo fino Alma + brillo): orbe con rayos, luna creciente con estrellas en
  rombo, nube oscura con contorno, gotas Lifeblood, copos en rombo Cristal, rayo que destella,
  niebla y viento ondulantes. Un solo `t` en bucle mueve todo; `ambient` (icono principal)
  anima siempre y los del pronóstico solo con hover. Los iconos sin dibujo caen al glifo.
  **Escena del clima** (2026-11-06, `pages/weather/WeatherScene.qml`): tarjeta animada detrás de la fila
  principal de Weather según `mainIcon.kind` (+ `night` por el icono): sol = Greenpath (rayos y hojas
  que caen), noche = estrellas en rombo y luciérnagas, nubes = bandas de niebla con blur, niebla = Fog
  Canyon (bruma rosa y uomas), lluvia/tormenta = City of Tears (silueta de torres generada con un
  pseudoaleatorio fijo `rand()`, ventanas encendidas, lluvia y relámpagos), nieve = Crystal Peak
  (cristales y nieve). Un solo `t` de 60 s mueve todo (`phase(seed, speed)`); un degradado oscuro a
  los lados mantiene legible el texto. Probar escenas: `qs -c paleshell ipc call weather scene <sun|night|cloud|fog|rain|storm|snow|auto>`
  (`Weather.previewScene`, no se guarda; solo cambia el fondo, no el icono ni los datos).
  Todas las páginas usan la paleta fija `Hallownest` (no `Colours`). Settings usa filas propias
  (`SettingRow`, interruptor con rombo, contador −/+) en vez de los de Nexus.
- Pomodoro: `SoulVessel` que se vacía (naranja Infección en foco, Lifeblood en descanso), hora
  grande en Cinzel, botones reset/play/selector de modo/saltar.
- To-Do: dos columnas (tarjeta con `X/Y` en Cinzel, barra, Add task, Clear done + lista de
  píldoras con círculo de color). Colores = amuletos (`grimm`, `gold`, `unn`, `crystal`, `steel`).
- Shelf: dos columnas (contador grande + Remove/Clear, tarjetas `card` con miniatura/icono,
  nombre y tamaño). `Shelf` guarda `size` (`du -sb`) junto al MIME; `sizeStr()` lo formatea.
- Alertas ricas (`richOsd`, 64 px): Bluetooth (círculo Lifeblood con `headphones` si el
  `icon` del dispositivo es de audio, nombre y "Connected · 70%") y cargador ("Soul Restoring",
  porcentaje en Cinzel y pila dibujada). Al enchufar: destello radial blanco (`benchFlash`).
  El resto de avisos usa la vista simple con la paleta.
- Forma: `IslandShape.qml` (fondo `void_`, borde acero, `leftFillet`/`rightFillet` separados).
  La usan el notch y la isla de letras.
- Media (estilo Nusa): carátula 56 px, título/artista, volumen al pasar el ratón, `NailSlider`
  (barra fina con punta de Aguijón y guarda, también para volumen), píldora "Lyrics" y
  controles con play redondo blanco.
- Isla de letras (sustituye a la píldora bajo el notch): segunda `IslandShape` a 10 px a la
  derecha (el fillet de los lados enfrentados baja a 4 px para que la brecha llegue limpia al
  borde superior). Cerrado: línea actual (`islandShown` = letras activas + reproduciendo +
  hay letras); clic abre Media. Abierto en Media: 4 líneas centradas (`StrictlyEnforceRange`),
  actual en blanco negrita con niebla radial (`highlight`), el resto al 35 %; clic = seek.
- Para probar Media sin tocar el bus del usuario: `dbus-run-session` con el MPRIS falso y una
  copia temporal `ZzNotchWindow.qml` con `hasFullscreen: false` si hay una ventana a pantalla
  completa (si no, el notch está oculto y no se expande).
- Colapsado (`Collapsed.qml`): hora en JetBrains Mono, pomodoro naranja Infección (foco) /
  Lifeblood (descanso) y `MiniEqualizer` (4 barras reales de Cava vía `ServiceRef` solo mientras
  suena, con brillo y `SoulParticles` subiendo). `mascot/SoulParticles.qml` es reutilizable.
- **Trampa**: Quickshell solo empaqueta los QML alcanzables estáticamente. Las páginas se
  declaran como `Component { Pages.X {...} }` en `NotchWindow` (`pageComponents`); un `Loader`
  con `source:` por URL no encuentra los componentes de subcarpetas. Tras mover un archivo con
  `mv` (mtime viejo) puede hacer falta `touch`.
- Servicios (`services/`), estado en `~/.local/state/paleshell/notch/`:
  - `NotchSettings`: `config.json`; página **Settings** del notch, cambios en caliente.
  - `NotchMedia`: reproductor activo, letras (singleton C++ `Lyrics`, backend lrclib) y refresco
    de posición por contador `positionUsers` (solo con página Media o píldora de letras).
  - `NotchOsd`: avisos efímeros (volumen, mic, brillo, Caps Lock, layout, cargador, Wi-Fi,
    Bluetooth), con toggle cada uno. Ignora eventos los primeros 3 s. Si el aviso del cargador
    está activo, `BatteryMonitor` no muestra su toast.
  - `Shelf`: `shelf.json`, solo rutas `file://` y textos; MIME con `file --mime-type`. Arrastrar
    fuera = copia y quita del shelf; soltar sobre el propio notch cancela.
  - `Pomodoro`: `pomodoro.json`; sonido `pw-play complete.oga`; aviso por `NotchOsd`.
  - `Todos`: `todos.json`; hora límite `HH:MM` (si ya pasó, mañana); `Timer` single-shot a la
    próxima; alerta *Time's up!* con Snooze (`snoozeMinutes`), sonido `alarm-clock-elapsed.oga`.
    Las tareas hechas de días anteriores se borran al cargar.
- Mascota (`mascot/Knight.qml`): formas tomadas de `~/Downloads/hollow.svg` (dibujo del usuario
  en Inkscape; trazados `PathSvg` en coordenadas del SVG). Ojos = hueco: borde gris + elipse negra,
  tapados por un anillo color cabeza (relleno par-impar) para que el negro no se salga del borde.
  Expresiones `open`/`happy` (^)/`dizzy` (espirales que giran). Respira con squash & stretch,
  parpadea, acciones aleatorias (mirar a los lados, inclinar, saltito, feliz, mareado), bosteza al
  dormirse, se balancea con música. Es más alta que la píldora: los cuernos asoman sobre el borde.
- Aparece por inactividad (`IdleMonitor`, `mascotDelay`/`dozeDelay`) y en visitas aleatorias
  (`mascotRandom`, cada 1–3 min durante 12–30 s, se despide con un saltito). `ipc call notch
  mascot` fuerza una visita. Ojos siguen al ratón (`mascotTracking`) solo mientras se mueve
  (`cursorMoving`, 2 s): `j/cursorpos` por el socket de Hyprland (`Socket` de Quickshell, sin
  procesos) cada 60 ms con la mascota visible. Quieto, mira a los lados al azar (`idleX/idleY`).
- Colores de la mascota fijos (cabeza `#daebeb`, borde `#4d4d4d` del SVG) y mezclados con
  `soulness` (Alma: blanca brillante con partículas) y `voidness` (Vacío: negra con ojos
  blancos). Dormido = ojos cerrados en arco (`closed` cuando `lid` < 0.5) y tres "z" en Cinzel.
  Aburrido (`stare`) = párpado gris (`lidShade`). Enfadado = `sadTilt` negativo + símbolo de ira
  rojo (`anger`). Nervioso (`shocked`) = pupilas pequeñas, gotas de sudor y líneas de temblor;
  también al despertarlo de golpe mientras duerme. Reacciones: cargador y fin de foco → `soul`,
  fin de descanso y Snooze de un To-Do → `angry`, Wi-Fi perdido → `shocked`; `void` aparece
  al azar.
- Caras extra de `~/Downloads/HollowGuide.svg`: decepcionado (`droop`: párpado plano por `clip`),
  llorando (`sadTilt` + `tears` + `stream`/`drip`), infectado (expresión `infected`, ojos naranjas
  que laten). Acciones aleatorias nuevas: `sigh`, `stare`.
- **Easter egg del Hollow Knight** (2026-11-06): cabeza del jefe dibujada por el usuario
  (`~/Pictures/InkScape/HK.svg`, trazados pegados en `Knight.qml` en coordenadas de página, escalados
  ×0.95 sobre la base del Caballero, más grande que él a propósito; mientras dura `bossShown` la píldora
  del notch pasa de 46 a 72 px para que quepa. **Trampa**: con `layer.enabled` (brillo de Alma o borde del
  Vacío) el efecto solo dibuja dentro del item, así que `body` se extiende hacia arriba `headroom` (45) y
  desplaza su contenido; `layer.sourceRect` no alcanza; ojos = `component HollowEye` con la matriz del SVG). `boss`
  (0–1) hace el fundido entre las dos cabezas y `bossInfection` muestra las grietas y los ojos
  naranjas con borde rojo. `bossAnim`: el Vacío ennegrece al Caballero (`voidness`, temblor,
  agachado), cambia de forma estirándose, aparece el Hollow Knight, se queda 7 s y vuelve igual.
  Si pasas el ratón por encima (`wake()`) se infecta (`rageAnim`), vuelve a ser el Caballero y se
  va. Sale con un 3 % de probabilidad en cada acción aleatoria y en las sorpresas de `ipc call notch
  mascot`; prueba: `qs -c paleshell ipc call notch react boss`. Mientras dura, `react()` ignora otras
  reacciones.
- **Menú de animaciones** (`Super + F8`, atajo `paleshell:mascot`): `modules/notch/MascotMenu.qml`, overlay
  como el de emojis con una cuadrícula de 3 columnas (Random en dorado primero + las 10 reacciones y 6
  acciones de `Knight.reactionNames`/`actionNames`). Elegir pone `ScreenState.mascotPick` (vacío = al azar)
  y suma `mascotCalls`; `NotchWindow` llama a `knight.play(pick)` o `surprise()`. IPC: `notch mascotMenu`,
  `notch play <nombre>` (sin depender de `mascotReactions`, a diferencia de `react`) y `notch mascot` (al
  azar). Descripción del atajo en `keybinds.lua` (backup `.bak-mascotmenu`).
  **Trampa**: el foco va con `focus: true` declarativo en la cuadrícula (`forceActiveFocus()` en
  `Component.onCompleted` corre antes de que la ventana esté activa y no sirve), y un `GridView` con
  `interactive: false` apaga también las flechas: hace falta `keyNavigationEnabled: true`.
  Una llamada a propósito (`mascotCalls`: menú, `notch play`, `notch mascot`) en modo dock marca
  `NotchWindow.summoned`: `mascotAllowed` deja de exigir `!dockShown` y `fullscreenHidden` no oculta la
  píldora mientras dure esa visita; se borra al irse la mascota (`mascotShown` = false). Las visitas al azar
  y por inactividad siguen sin salir en modo dock. Con pantalla completa sigue sin aparecer.
- En modo Vacío (`voidness` > `soulness`) el cuerpo lleva un borde claro: el mismo `MultiEffect` del
  brillo de Alma pero ajustado (`shadowBlur` 0.15, `blurMax` 5), para que no se pierda en el fondo del
  notch. Las dos mitades de la cabeza del Hollow Knight llevan un trazo del mismo color y una tira de
  relleno donde se juntan (si no, el antialiasing deja una línea).
- Reacciones: `services/Mascot.qml` deja una reacción pendiente (`pending`, caduca a 60 s) y la
  `NotchWindow` de la pantalla enfocada la reproduce (`knight.react`) cuando puede mostrar la
  mascota, después del OSD. Disparadores: avisos de `NotchOsd` (cargador, Wi-Fi, Bluetooth,
  pomodoro), batería ≤15 % (llora) y ≤5 % (infectado), cambio de canción (cada 3 min como
  máximo) y todas las tareas hechas. Toggle `mascotReactions`. Prueba:
  `qs -c paleshell ipc call notch react <happy|vibe|sad|cry|infected>`.
- `NotchOsd` pone siempre `utilities.toasts.capsLockChanged = false`: Caps Lock solo se avisa en
  el notch (toggle `osdCapsLock`).
- Batería baja: `BatteryMonitor` usa los `warnLevels` de `shell.json` y, con `osdBattery`, llama a
  `NotchOsd.showBattery(title, message, icon, value, critical)` en vez del toast (también el
  aviso de hibernación). Vista rica en el notch (título, mensaje naranja, pila roja) 6 s, 9 s si
  es crítica.
- Para probar sin tocar los datos del usuario: `XDG_STATE_HOME=<scratch>` (copiar
  `scheme.json` dentro) y un `zz_*.qml` que cree `NotchWindow` y capture
  `win.contentItem.children[0].grabToImage(...)`. Para probar Media sin reproductor: un servicio
  MPRIS falso con `gi.repository.Gio`.

### Menú de atajos (Super + F3)
- `modules/keybinds/Keybinds.qml`:
  - Overlay en la pantalla enfocada.
  - `CustomShortcut` `paleshell:keybinds`.
  - `IpcHandler` `keybinds.toggle`.
- `KeybindsContent.qml`:
  - Lee `hyprctl binds -j` y muestra solo los binds con descripción, agrupados por sección.
  - Buscador que ignora tildes.
  - Colapsa `Super + 1…0` y las flechas.
  - `Esc`/clic fuera para cerrar.
- Las descripciones viven en `~/.config/hypr/hyprland/keybinds.lua`: `create_bind(keys, action,
  flags, "Sección|Descripción")` (4.º argumento; usar `nil` como `flags` si no hay). Un atajo sin
  descripción no aparece en el menú. Hyprland 0.56 acepta `description` en las opciones de
  `hl.bind`. Backup: `keybinds.lua.bak-descripciones`.

### Página AI del notch
- `modules/notch/pages/Ai.qml` (página **AI**, icono `smart_toy`). Selector de proveedor: **Claude Code** (`claude`) y **Antigravity** (`agy`,
  en `~/.local/bin`; sin app de escritorio instalada).
  - Botones Terminal, App (solo si existe `claude-desktop`/`antigravity`) y Continue.
  - Chips de carpeta (home + cwd de sesiones recientes, sin worktrees) y "Other..." con zenity.
  - Campo de prompt (`claude "<texto>"` / `agy -i "<texto>"`).
  - Sesiones recientes; clic → `claude --resume <id>` / `agy --conversation <id>` en su cwd.
- `services/AiAgents.qml`: proveedores, detección de binarios/versiones y lanzadores. El
  proveedor elegido se guarda en `~/.local/state/paleshell/ai-provider`.
- `assets/ai-sessions.py <claude|antigravity>`: Claude lee `~/.claude/projects/*/*.jsonl` (solo
  cabeza y cola: pesan decenas de MB); Antigravity lee
  `~/.gemini/antigravity-cli/conversation_summaries.db` (sqlite).
- **Sesiones en vivo y aprobaciones (estilo coucou)**: hooks de Claude Code →
  `assets/agent-hook.py` (relay; manda cada evento como una línea JSON a
  `$XDG_RUNTIME_DIR/paleshell/agents.sock`) → `services/AgentSessions.qml` (`SocketServer`).
  - Regla del relay: nunca bloquear al agente. Sin socket sale al instante sin salida; solo
    `PermissionRequest` espera respuesta (110 s) y sin clic no imprime nada (Claude pregunta en la
    terminal). Las respuestas se validan (id + etiquetas de `AskUserQuestion`).
  - "Always" = allow + `updatedPermissions` con las `permission_suggestions` del evento.
  - La shell cierra la conexión tras leer cada evento normal (así no ensucia el log con
    `PeerClosedError`). Una aprobación se retira si se cierra su conexión (respondida en la
    terminal), con `PostToolUse`/`Stop`/nuevo prompt de esa sesión, o con "Terminal" (`skip`).
  - `assets/agent-hooks.py status|install|uninstall [settings.json]`: añade/quita solo las
    entradas cuyo comando contiene `agent-hook.py`, con backup `settings.json.bak-paleshell-*`.
    Botón en Settings → AI agents y en la página AI. Probar con una copia pasando la ruta.
  - Página AI: tarjeta de aprobación (`modules/notch/AgentApproval.qml`, Allow/Always/Deny o
    chips de opciones), "Live sessions" (máx. 3; clic = enfocar la ventana de la terminal por los
    pids ancestros que manda el relay) y a la derecha el lanzador y las recientes.
  - Notch colapsado: rombo + "Claude" mientras trabaja; alerta dorada `agentAlertShown`
    (Deny/Allow, o "Answer" que abre la página AI) con prioridad tras la del To-Do; brillo dorado.
    Toggles `agentAlerts` y `agentOsd` (aviso al terminar). Mascota: `shocked` al pedir permiso,
    `happy` al terminar.
  - Probar sin Claude: `echo '{"hook_event_name":"PermissionRequest","session_id":"s",...}' |
    python3 -I assets/agent-hook.py` contra una instancia `zz_*.qml`.
- **Trampa**: `Quickshell.execDetached({command, workingDirectory})` falla aquí
  (`Could not convert argument 0 ... ProcessContext`) y no lanza nada. Para el cwd se usa
  `sh -c 'cd "$1" && shift && exec "$@"'`.
- Teclado: la ventana del notch es `OnDemand` mientras está expandida; al enfocar el campo de
  prompt se fija abierto (`ScreenState.notch = true`).
- Para capturar pruebas sin tocar la pantalla del usuario: `item.grabToImage(r =>
  r.saveToFile(...))` desde el `zz_*.qml`, en vez de `grim`.

### Funciones rápidas (portapapeles, emojis, clase, capturas, privacidad)
- Página **Clipboard** del notch (`pages/Clipboard.qml` + `services/Clipboard.qml`): historial de
  `cliphist` (60 últimos), miniaturas decodificadas en `~/.cache/paleshell/clipboard/`, buscador,
  fijar textos (`~/.local/state/paleshell/clipboard-pins.json`), borrar y vaciar. `Super + V` abre
  esta página.
- Selector de emojis propio (`modules/emoji/`, atajo `paleshell:emoji`: `Super + .` y la tecla de
  emojis del teclado, que manda `Super+Ctrl+Shift+AltGr+Espacio`). Datos de `caelestia emoji`;
  recientes en `emoji-recent.json`. Solo copia (no hay `wtype`).
- Próxima clase en el notch colapsado (`Collapsed.qml`): evento de khal de hoy que empieza en
  `nextEventLead` min (20); desaparece al empezar (el usuario no la quiere durante la clase).
  Toggle `nextEvent` en Settings.
- Capturas (`services/Screenshots.qml`): región (`Picker.qml`, ya no abre swappy) y pantalla
  completa (`paleshell:screenshotFull`, tecla Print) se guardan en `~/Pictures/Screenshots`, se
  copian y se añaden al Shelf.
- `services/Privacy.qml`: micrófono (streams `AudioInStream` de PipeWire, ignora cava/quickshell) y
  cámara (`fuser /dev/video*` cada 3 s); iconos rojos en el notch colapsado.

### Dock inferior
- `modules/dock/` (`Dock.qml` = una `DockWindow` por pantalla, capa `paleshell-dock`, sin zona
  exclusiva) + `services/Dock.qml` (fijadas en `~/.local/state/paleshell/dock.json`, por defecto
  zen/foot/thunar; `entries` = fijadas + abiertas agrupadas por desktop entry o clase).
- Modo manual: `Dock.mode` (false = isla arriba, true = dock abajo, guardado en `dock.json`), atajo
  `paleshell:dock` (`Super + F1`) e IPC `dock toggle`. El usuario no quiere que cambie solo al ir a
  un workspace vacío ni al pasar el ratón por el borde (cambiar de modo). En modo isla, llevar el
  ratón al borde inferior (`peekZone`, 3 px) asoma el dock sin gotas (`peeking`, sin cambiar
  `Dock.mode`) para abrir el menú; se esconde 600 ms después de salir si el menú está cerrado.
  Igual arriba: en modo dock, el borde superior (`peekZone` de `NotchWindow`, `canPeek`) expande el
  notch; `peekCheck` lo cierra a los 600 ms si su `hoverHandler` no llegó a ver el cursor. Un archivo
  arrastrado a esa franja abre el Shelf (`DropArea` de `peekZone`; `dragCheck` suelta `dragHovered` si
  no pasa al `notchDrop`). Con pantalla completa no se ven ni dock ni
  gotas (decisión del usuario; la capa Top queda encima de la pantalla completa, así que
  `gooRunning` exige `!hasFullscreen`).
  Espacio reservado (2026-11-06): `drawers/Exclusions.qml` suma al marco la píldora base del notch
  (34 px × escala − 5, para que el hueco con la ventana sea 5 px en vez de los 10 de `gaps_out`; 0 con `minimal`) arriba en modo isla y la fila del dock (60 px) abajo en modo dock,
  así las ventanas no quedan tapadas. Constantes fijas a propósito: las alertas/OSD más altas del
  notch no mueven las ventanas. Si cambian `collapsedHeight` o `dockHeight`, actualizarlas ahí.
  Isla y dock se excluyen: mientras se ve el dock (`ScreenState.dockShown`) el notch colapsado se
  oculta como en pantalla completa (alertas, OSD, notificaciones y el atajo siguen funcionando).
- Iconos: línea bajo las abiertas (ancha si tiene el foco), número si hay varias ventanas. Clic =
  abrir / enfocar / ciclar ventanas; central = nueva instancia; derecho = fijar o quitar. Hover sobre
  una app abierta → miniaturas `ScreencopyView` encima. Botón de cuadrícula → cajón de apps (crece la
  isla hacia arriba); arrastrar desde el cajón o dentro del dock fija/reordena en vivo (`dragIndex` → `dockIds`; los iconos se mueven por `x`, no se reordena el modelo para no destruir el que se arrastra; `Dock.pin(id, i)` cuenta `i` sin `id`). Miniaturas desde 1 ventana.
- **El launcher vive en el menú de aplicaciones del dock** (el panel de `drawers` está apagado con
  `launcher.enabled: false` en `shell.json`, backup `shell.json.bak-launcher`). El menú sigue a
  `screenState.launcher`, así que el atajo `Super` y todos los ítems del launcher (que se cierran con
  `screenState.launcher = false`) funcionan igual. Sin texto: cuadrícula de apps (arrastrar para
  fijar); al escribir: `Launcher.Content` (apps, calculadora, web, `@sitio`, `/archivos`, `>`
  comandos, temas, fondos) con la búsqueda abajo, junto al dock. `Content` expone `query`,
  `listShown`, `searchHeight` y `appGrid`: sin texto, las flechas mueven la selección de la cuadrícula
  (borde Alma) y Enter abre la app (`launch()` del delegado); al abrir el menú no hay nada seleccionado. La cuadrícula oculta las mismas apps que el launcher
  (`launcher.hiddenApps`). `>wallpaper` es un carrusel a todo el menú (`WallpaperList` +
  `WallpaperItem` reescritos para el menú: actual al 64 % del ancho, vecinos más chicos y
  translúcidos vía `PathAttribute` `itemScale`/`itemOpacity`; ya no calcula huecos de la barra). En modo isla el menú sube
  solo (sin la fila del dock y sin gotas) y el notch sigue arriba. `ContentWindow` ya no pide el
  teclado por `launcher` si el panel está apagado. **Trampa**: `HyprlandFocusGrab` activado en el
  mismo instante en que aparece la zona de entrada se suelta solo; va con `grabDelay` de 150 ms.
- Animación de gotas (`GooWindow.qml`, capa `paleshell-goo` a pantalla completa, sin entrada,
  siempre mapeada; solo dibuja mientras `running`). `DockWindow.progress` (0 = isla arriba,
  1 = dock) se anima 2,2 s al cambiar `wanted` (más rápido le pareció brusco); el dock solo se ve con `progress === 1` y
  `dockShown` = `wanted || progress > 0`, así notch y dock nunca coinciden. Progreso lineal: el
  12 % inicial/final encoge o hace crecer las formas (el notch publica su tamaño real en
  `ScreenState.notchWidth/Height/Radius`; el dock pasa `islandWidth/Height` sin fillets) y el resto
  es el viaje de las gotas por el marco con in-out quad (al usuario le molestaba que los extremos
  fueran lentos y el viaje rápido, y que las formas finales fueran más grandes).
  Metaballs sin shader propio: formas blancas (incluido el marco) → `ShaderEffectSource` →
  `MultiEffect` blur → `ShaderEffectSource` → máscara con `maskThresholdMin: 0.5` sobre un relleno
  `void_`. **Trampa**: no usar `layer.enabled` en elementos con `visible: false` como fuente de
  contenido que se mueve: Qt no repinta y la animación sale congelada (se veía solo la primera vez).
  Las fuentes van visibles tras `ShaderEffectSource { hideSource: true; live: true }`, y lo que se
  oculta en reposo son las formas, nunca la cadena del efecto. `settle` (duración + 250 ms) las deja visibles
  mientras aparece el notch/dock. `Config.border` se lee vía `blobs.Config` (en la raíz de la
  ventana no hay pantalla). `grabToImage` no sirve para verificarlo (renderiza aparte y
  esconde este fallo): medir en pantalla con una copia `Zz*` de color magenta y `grim` de una franja
  que excluya el marco (p. ej. `1870,100 35x880` a mitad de animación), contando solo píxeles
  magenta sin mirar la imagen.

### Funciones del 2026-11-06
- **Apps abiertas** (launcher y cuadrícula del dock): `Dock.openGroup(id)` devuelve el grupo con
  ventanas; `AppItem.open()` y el `launch()` de la cuadrícula lo enfocan (`Dock.activate`) en vez de
  abrir otra instancia. La descripción pasa a "Open · switch to its window" en Lifeblood.
- **Traductor** `>tr <texto>` (acción "Translate"): estado `tr` en `AppList` (`translateQuery`),
  `items/TranslateItem.qml` con `trans -b -no-ansi :es+en` (debounce 400 ms; usa la línea en inglés
  si la española repite el texto). Enter copia. Requiere `translate-shell`.
- **OCR**: `assets/ocr.sh` (slurp → `grim -s 2` → `tesseract -l spa+eng` → `wl-copy` + `notify-send`).
  Acción "Copy text from screen" y atajo global `paleshell:ocr` (`Super + F9`).
  Requiere `tesseract-data-spa`/`-eng` (sin ellos avisa).
- **Próxima clase en el bloqueo**: `lock/center/NextClass.qml` bajo la fecha: siguiente evento con
  hora de hoy (`Events.loadRange("lock", …)`); se oculta si no queda ninguno.
- **Grabar pantalla** desde Home del notch (servicio `Recorder` existente → `caelestia record`):
  botón pantalla completa (`videocam`) y región (`crop_free`, cierra el notch para `slurp`); grabando,
  un solo botón rojo con el tiempo (`Recorder.elapsedText()`) para parar. Notch colapsado: punto rojo
  + tiempo. Home pasó a 660 px de ancho para que entre la fila.
- **KDE Connect**: `kdeconnectd` en `execs.lua` (backup `.bak-kdeconnect`; Hyprland no lee el
  autostart XDG). Las notificaciones del celular entran por el servidor de notificaciones normal.
  `Shelf` escucha `org.kde.kdeconnect.device.share.shareReceived` con `dbus-monitor` y añade los
  archivos recibidos. `ufw` está activo: hay que abrir 1714–1764 TCP/UDP. Emparejar con
  `kdeconnect-app`.
- **Zathura y btop**: `assets/apps-theme.py <flavour>` (lo ejecuta `setFlavour`):
  `~/.config/zathura/hallownest-colors` (incluido desde `zathurarc`, con `recolor` = páginas oscuras,
  Ctrl+R) y `btop/themes/hallownest.theme` (`color_theme` en `btop.conf`; caelestia sigue generando
  `caelestia.theme` aparte). Backups `*.bak-hallownest`. Zathura ya era el visor PDF predeterminado.
  fastfetch NO se toca: el usuario tiene `"logo": null` a propósito (se probó la máscara y la quitó).

### Temporadas y mezclador (2026-11-06)
- **Temporadas** (`services/Season.qml`): `current` = `grimm` en octubre, `winter` en diciembre, vacío el resto.
  IPC `season set <grimm|winter|none|auto>` (no se guarda; `auto` vuelve al calendario) y `season get`.
  En `NotchWindow`, detrás de la forma (solo se ve lo que sobresale de la píldora): Grimm = brasas rojas
  (`SoulParticles` color `grimm`) + brillo rojo del notch cuando no hay otro (música/pomodoro/agente);
  invierno = nieve (`SoulParticles` con `rotation: 180`, así caen). Ocultos con pantalla completa o
  `minimal`. La mascota tiene ojos rojo oscuro en Grimm (`Knight.eyeColour`). La capucha de Grimm quedó
  pendiente de un dibujo del usuario.
- **Mezclador por app**: botón `tune` en la fila de volumen de Home → detalle `mixer`
  (`pages/home/Mixer.qml`): una fila por stream de reproducción (`Audio.streams` filtrado por
  `PwNodeType.AudioOutStream`, así no salen Cava ni el micrófono) con icono, app + `media.name`
  (p. ej. la pestaña), silenciar, `HkSlider` (rueda ±5 %) y porcentaje.
- Probado con streams falsos: `pw-play --volume 0 -P '{ application.name = "X" }' silencio.wav`.
- **Notificaciones como diálogo de NPC** (`modules/notch/NotifView.qml`, las que salen en el notch):
  ornamento arriba (líneas que se desvanecen + rombo relleno), "hablante" = nombre de la app (o
  "PaleShell" en los toasts) en Cinzel con su icono, texto centrado de hasta 2 líneas que se escribe
  letra a letra, acciones como `HkButton` y ornamento abajo con la flecha de "continuar" que rebota al
  terminar de escribirse. La altura de la píldora sigue a `notifView.implicitHeight`. **Trampas**: el
  tipeo va con un `Timer` (una `NumberAnimation` se quedaba a medias porque las animaciones solo avanzan
  cuando el compositor pide cuadros al notch); `bottom` es propiedad FINAL de Item y no se puede
  redeclarar (tumbó la shell); en `MaterialIcon` usar `fontStyle`, no `font.pointSize` (pierde la
  fuente de iconos y sale el nombre en texto). Las notificaciones fuera del notch
  (`notifsInNotch` apagado, `modules/notifications/`) siguen con su diseño anterior.
- `NotifView` (toasts en el notch) pasa título y mensaje por `Tr.trMarked`: los textos marcados con
  `mark()` en C++ traen un marcador invisible que salía como cuadradito.

### Overview de workspaces (Super + Tab)
- `modules/overview/` (`Overview.qml` = overlay como el de emojis, atajo `paleshell:overview`,
  IPC `overview toggle`). `OverviewContent.qml`: rejilla de 5 columnas (mínimo 5 workspaces,
  crece en filas hasta el mayor ocupado), miniaturas en vivo con `ScreencopyView` de
  `HyprlandToplevel.wayland`, posiciones de `lastIpcObject.at/size` relativas al monitor.
- Clic en ventana = enfocar; clic en tarjeta = ir; arrastrar ventana = mover sin seguir
  (`hl.dsp.window.move({..., follow = false})`); clic central = cerrar. Teclado: flechas, Tab,
  Enter, números, Esc.

### SDDM, Zen, Obsidian y Thunar a juego
- Tema de SDDM en `assets/sddm/hallownest/` (Qt6, `SddmComponents`): reloj Cinzel, contraseña
  con rombos, selector de sesión y botones de energía. Fondo = copia de `hollowMate.jpg`; colores
  fijos en `theme.conf` (no sigue el flavour: instalarlo requiere root). Probar sin root:
  `sddm-greeter-qt6 --test-mode --theme assets/sddm/hallownest`. Instalación (usuario):
  copiar a `/usr/share/sddm/themes/hallownest` y `/etc/sddm.conf.d/theme.conf` con
  `[Theme] Current=hallownest`. Tras editarlo hay que volver a copiarlo.
- Zen: `assets/zen/userChrome.css` (fuente; no editar la copia del perfil) y
  `assets/zen-theme.py <flavour>`, que lo copia a cada perfil de `~/.config/zen/profiles.ini`,
  escribe `chrome/hallownest-colors.css` y activa `toolkit.legacyUserProfileCustomizations.stylesheets`
  en `user.js`. `Hallownest.setFlavour` lo ejecuta; Zen necesita reiniciarse para verlo.
- Obsidian: `assets/obsidian/hallownest.css` (fuente) y `assets/obsidian-theme.py <flavour>`, que
  lo instala como snippet `hallownest.css` en cada bóveda de `~/.config/obsidian/obsidian.json`
  (Cinzel incrustada en base64), activa el snippet y el modo oscuro en `appearance.json`.
  `Hallownest.setFlavour` lo ejecuta; Obsidian recarga snippets en caliente. Bóveda: `~/Notas`.
  Ojo: `obsidian --version` abre la app.
- Thunar: `assets/thunar/hallownest.css` (fuente) y `assets/thunar-theme.py <flavour>`, que
  escribe `~/.config/gtk-3.0/thunar.css` (lo importa el `gtk.css` de caelestia; solo afecta a
  `.thunar`) y los punteros en rombo `hallownest/pointer-*.svg`. Debe ir **después** de
  `caelestia scheme set`, que pisa `thunar.css`: `setFlavour` lo encadena y también se ejecuta al
  arrancar la shell. GTK3 solo lee el CSS al iniciar: `thunar -q` para verlo. Cinzel en barra
  lateral, pestañas y botones de ruta; GTK3 no acepta `background-position` de 4 valores.
  Probar aislado: `XDG_CONFIG_HOME=<scratch>` con copia de `gtk.css` y
  `xfce4/xfconf/.../thunar.xml`, y `dbus-run-session -- thunar`. Los menús contextuales no
  llevan la clase `.thunar` (siguen el tema global).

### Calculadora directa en el launcher
- `modules/launcher/AppList.qml`: `isMath(text)` detecta cuentas sin `>calc ` (operadores entre
  números, `10 km to mi`, `15% of 200`, `5!`, `√2`, `sqrt(16)`, o texto que empieza con `=`) y
  pasa al estado `calc`. `calcExpression` es la expresión (con o sin prefijo).
- `items/CalcItem.qml` usa `list.calcExpression` y evalúa también al crearse. `Content.qml`:
  Enter en estado `calc` copia el resultado.
- Casos que NO deben disparar: `7-zip`, `2048`, `3 in 1 printer`.

### Búsqueda web en el launcher
- `AppList.qml`: estado `web` si el texto no coincide con ninguna app (y no es cuenta ni empieza
  por `@`), o con el comando `>web <texto>`. `webQuery` es el texto sin prefijo.
- `items/WebItem.qml`: "Search …" / "Open …" (si parece URL: `dominio.tld`, `http(s)://`,
  `localhost`). `Content.qml`: Enter en estado `web` lo abre; **Shift+Enter** busca en la web
  aunque haya apps que coincidan.
- `services/WebSearch.qml`: `zen-browser --new-tab <url>` (abre pestaña en la instancia abierta o
  arranca el navegador; Hyprland lo enfoca por `focus_on_activate`). Buscador: Google.
- La acción "Web search" se añade desde `services/Actions.qml` (no está en los defaults C++).
- Búsqueda por sitio: `@yt gatos`, `@reddit …` o `@<nombre sin espacios> …` usan los motores
  de búsqueda propios de Zen. `assets/zen-engines.py` los lee del `search.json.mozlz4` del
  perfil por defecto (descompresor LZ4 propio, sin dependencias) y `WebSearch.siteSearch()` los
  matchea; se recargan al entrar en estado `web`. Los filtros de una letra (`@i`, `@c`...) del
  buscador de apps siguen funcionando porque solo se activa con un alias conocido.

### Búsqueda de archivos en el launcher
- Prefijo `/` (`/factura pdf`) → estado `files` en `AppList.qml`, antes que la web. Servicio
  `modules/launcher/services/FileSearch.qml`: `fd` en vivo sobre `$HOME` con la palabra más
  larga (`--fixed-strings`, `--no-ignore-vcs`, sin ocultos ni `node_modules`/`venv`/...), y el
  resto de palabras se filtra sobre el nombre; prioriza nombres que empiezan por la primera
  palabra y rutas cortas (30 resultados). Icono por extensión (`iconFor`).
- `items/FileItem.qml`: Enter abre con `xdg-open`; Shift+Enter abre la carpeta que lo contiene.
- No se usa `plocate`: su índice no incluye `/home` (subvolumen btrfs + `PRUNE_BIND_MOUNTS`).

### Iconos de apps (tema Hallownest)
- `assets/icons/Hallownest/` es un tema de iconos (`index.theme`, `Inherits=Papirus-Dark,hicolor`)
  enlazado en `~/.local/share/icons/Hallownest`. El usuario dibuja los iconos en Inkscape poco a poco
  (todas las apps salvo juegos) con `plantilla.svg` (128 px: capa Base = amuleto relleno Tarjeta `#14161c`, no Vacío, para que no se pierda en el
  fondo, con anillo acero y 4 rombos; capa Simbolo; capa Ayudas oculta con la zona segura de radio
  44; muestras con la paleta). La cuadrícula del menú muestra los iconos a 48 px y los guarda en `apps/scalable/<nombre del Icon=>.svg`. Lo que falta sale de Papirus.
- `python3 scripts/hallownest-icons.py` regenera `PENDIENTES.md` (lista con el nombre de archivo de
  cada app, marcando las hechas; excluye `Categories=Game` y entradas `NoDisplay`).
- Activado el 2026-11-05: `"theme": {"iconTheme": "Hallownest"}` en `~/.config/caelestia/cli.json`
  (backup `cli.json.bak-iconos`; la CLI reescribe el tema de GTK y Qt en cada `scheme set`, así que no
  sirve cambiarlo a mano). `ipc call hallownest flavour <actual>` no reaplica si el flavour no
  cambia: usar `caelestia scheme set ...` + `assets/thunar-theme.py`. La shell (Qt) lee el tema al
  arrancar: reiniciarla para ver iconos nuevos.

### Iconos YAMIS teñidos por flavour
- Tema activo (2026-11-05): **YAMIS-Hallownest** (`"iconTheme"` en `~/.config/caelestia/cli.json`,
  backup `cli.json.bak-yamis`; antes era `Hallownest`). Original sin tocar: YAMIS-Cosmic (GPL, de
  `~/Downloads/yamis-cosmic.zip`) en `~/.local/share/icons/YAMIS-Cosmic`.
- `assets/icon-theme.py <flavour>` genera `~/.local/share/icons/YAMIS-Hallownest` cambiando el color
  de texto `#d8dee9` por el acento Alma del flavour y `#3b4252` por acero oscurecido. **Trampa**: Qt
  no aplica el `color` de la hoja `.ColorScheme-Text`, así que `currentColor` se escribe en cada
  elemento. Marca `.flavour` para no regenerar si no cambia (bórrala para forzar). Lo ejecutan
  `Hallownest.setFlavour` (antes de `caelestia scheme set`) y el arranque de la shell. Apps abiertas
  (y la shell) deben reiniciarse para ver el color nuevo.

### Cursor Hollow Knight
- Set de Windows de Newty (rw-designer, dominio público) en `assets/cursors/hollow-knight/`
  (`.cur` 32 px de 32 bpp y dos `.ani`). `python3 scripts/hallownest-cursors.py` lo convierte sin
  dependencias a Xcursor en `~/.local/share/icons/HollowKnight` (tamaños 24–96 por vecino más
  cercano, alias de nombres X/CSS como symlinks, `Inherits=OutLier-v2`).
- Activado con `cursorTheme = "HollowKnight"` en `~/.config/hypr/variables.lua` (backup
  `.bak-cursor`; antes `OutLier-v2`).
- Vectores: `--templates` crea en `assets/cursors/hollow-knight/svg/` una plantilla de Inkscape por
  cursor (y por cuadro de `progress`/`wait`: `<nombre>-<n>.svg`), lienzo 32×32 con capa Referencia (el
  pixel art, bloqueada), capa Cursor vacía y capa Ayudas con el hotspot. Si todos los cuadros de un
  cursor tienen dibujo, se usa el SVG (hyprcursor lo escala; Xcursor se renderiza con `rsvg-convert` +
  `magick`); una plantilla sin tocar sigue usando el pixel art. Tras editar: volver a ejecutar el script
  y `hyprctl setcursor HollowKnight 48`.
- `--vectorize` (hecho el 2026-11-05: los 23 SVG ya están trazados) rellena las plantillas con la
  capa Cursor vacía: agrupa los píxeles opacos en ≤4 tonos (k-means 1D), traza capas apiladas de
  oscuro a claro con `potrace` sobre una ampliación 8× suavizada (`magick -filter Catrom`, así los
  trazos de 1 px no se vuelven manchas) y rehace el halo semitransparente como `feDropShadow` (sombra
  negra o brillo blanco según su color). No pisa SVG editados; para retrazar uno, vacía su capa
  Cursor o bórralo y usa `--templates` + `--vectorize`. Hyprland (`enable_hyprcursor`) no tomaba el Xcursor: el script
  también genera `hyprcursors/` + `manifest.hl` con `hyprcursor-util --create` (`define_override` = alias), que usan `env.lua` y `execs.lua` (`hyprctl setcursor`,
  `gsettings`). Las apps ya abiertas pueden seguir con el cursor viejo hasta reiniciarlas.

### Tema Hollow Knight
- Esquema en `assets/schemes/hollowknight/<flavour>/dark.txt`, generado por
  `scripts/gen-hollowknight-scheme.py`: editar colores ahí y regenerar.
  - Base: negro vacío `#0b0b0e`, superficies carbón, texto hueso `#e9e6df`.
  - Flavours: `vessel` (blanco/gris), `lifeblood` (celeste), `infection` (naranja),
    `greenpath` (verde).
  - Solo modo oscuro.
- La CLI solo lee esquemas de `/usr/lib/python3.14/site-packages/caelestia/data/schemes/`.
  Instalación (la hace el usuario, una vez):
  `sudo ln -s ~/.config/quickshell/paleshell/assets/schemes/hollowknight
  /usr/lib/python3.14/site-packages/caelestia/data/schemes/hollowknight`. Si cambia la versión
  de Python, hay que rehacer el enlace. Ahí también hay restos de un intento viejo
  (`my-themes/`).
- Animaciones estilo "dash" sin rebote: curvas `expressive*` en `tokens.hpp` (comentadas como
  Hollow Knight) y duraciones en `~/.config/paleshell/shell-tokens.json`.
- Se probaron efectos propios (disolución en "tinta del Vacío" al abrir paneles con un shader y
  pulso celeste en notificaciones) y el usuario los descartó: no reintroducir sin que lo pida.

### Pantalla de bloqueo: almas y juegos
- `modules/lock/Fetch.qml`: la fila de colores de terminal se cambió por las 7 almas de
  Undertale (pixel art, Determinación roja en el centro).
- `PixelArt.qml`: dibuja pixel art a partir de filas de strings (`#` = celda llena) con un `Shape`.
- Sin notificaciones, `NotifDock` muestra `Arcade.qml`: selector (abajo a la derecha) entre
  `DinoGame`, `TetrisGame`, `PacmanGame` y `MinesweeperGame`. El último juego elegido se guarda en
  `~/.local/state/paleshell/lock-game`; récords en `dino-hi`, `tetris-hi`, `pacman-hi` y
  `minesweeper-best` (misma carpeta).
- Teclado: el foco siempre vuelve al campo de contraseña. `PasswordInput` intercepta las flechas
  (la contraseña no las usa) y emite `LockSurface.gameKey(key, pressed, isRepeat)`. La barra
  espaciadora no se usa porque puede ser parte de la contraseña.
- Cada juego expone `keyPressed(key, isRepeat)` / `keyReleased(key)` y solo corre (FrameAnimation
  o Timer) mientras está visible.

### Configuración migrada
- `~/.config/paleshell/shell.json`: `bar.status` → `bar.statusIcons` (lista con `id`/`enabled`),
  `services.useTwelveHourClock` → `services.clockFormat: "TwentyFourHour"`. Backup en
  `shell.json.bak`.

## Archivos relevantes fuera del repo

| Archivo | Para qué |
|---|---|
| `~/.config/hypr/hyprland.lua` | Carga los módulos de `hyprland/` (`env`, `execs`, `keybinds`...) |
| `~/.config/hypr/hyprland/env.lua` | `QML_IMPORT_PATH` del plugin compilado |
| `~/.config/hypr/hyprland/execs.lua` | Autoarranque (`qs -c paleshell -n -d`) |
| `~/.config/hypr/hyprland/keybinds.lua` | Atajos + descripciones del menú (brillo también con Super + teclas de volumen; backup `.bak-brillo`). Fila F del K380s con Fn Lock (sin Super / con Super): F1 notch / isla ↔ dock, F2 overview / ventana ↔ espacio especial, F3 portapapeles / menú de atajos, F4 pantalla completa / maximizar, F5 lupa (`cursor.zoom_factor` 1↔2) / color picker, F6 atrás / adelante (`send_shortcut` Alt+←/→), F8 emojis / mascota, F9 captura de región / OCR (pantalla completa solo con Print; backup `.bak-ocr`), F10 play-pausa / siguiente (Super+Shift anterior), F11 silenciar / micrófono, F12 e Insert volumen −/+ / brillo; backups `.bak-fkeys`, `.bak-dock` |
| `~/.config/hypr/variables.lua` | Teclas por defecto (`kb*`), apps (`terminal`, `browser`...) |
| `~/.config/hypr/hyprland/rules.lua` | Reglas de ventana (quickshell/zenity flotan) |
| `~/.config/paleshell/shell.json` | Config de la shell |
| `~/.config/paleshell/shell-tokens.json` | Overrides de tokens (solo duraciones) |
| `~/.local/state/caelestia/scheme.json` | Esquema de colores activo (lo escribe la CLI) |
| `~/.config/khal/config` | Config de khal |
| `/usr/lib/python3.14/site-packages/caelestia/` | CLI de caelestia (esquemas, `shell.py`) |

En Hyprland, `MOD5` es AltGr (modmask 128); Super es 64, Ctrl 4, Alt 8, Shift 1.
