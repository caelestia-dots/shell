# AGENTS.md — Referencia del fork

Punto de referencia para cualquier agente/IDE/modelo que entre sin contexto. Si cambias algo respecto
a este fichero, **actualízalo en el mismo commit**. Detalle de uso en [FEATURES.md](./FEATURES.md),
cambio a cambio en [CHANGELOG.md](./CHANGELOG.md), instalación/config upstream en [README.md](./README.md).

---

## 1. Qué es

- Fork de **caelestia-dots/shell** (shell Quickshell/QML para **Hyprland**, config en **Lua**).
- Repo GitHub: **iMacnucintosh/hyprland-shell**. Remote `origin` = tu fork; `upstream` = caelestia-dots/shell (las actualizaciones de base se hacen **mergeando upstream** y pasando PR a `main`).
- El código que **corre** es este checkout: `~/.config/quickshell/caelestia` (no el paquete AUR de `/etc/xdg`). El plugin C++ de config se compila **desde la raíz del repo** e instala en `~/.local` (sin sudo); `shell.qml` lo carga vía pragma `QT_ADDITIONAL_PACKAGES_PREFIX_PATH` — ver "Plugin C++ (build user-local)" en FEATURES.md.
- Runtime de la shell: `~/.config/caelestia/` (`shell.json`, `keybinds.json`, `cli.json`, `templates/`).
- Estado persistente: `~/.local/state/caelestia/` (`timers.json`, `hydration.json`, `light-apps.json`, `nonsteam-sessions.json`, `steam-activity.json`, `sequences.txt`, `theme/kitty.conf`).
- Generados por el fork en Hyprland (todos via `require(...)` desde `hyprland.lua`): `caelestia-binds.lua`, `caelestia-activity-rules.lua`, `caelestia-monitors.lua`.

## 2. Entorno del usuario (Manu)

- Arch Linux + **Hyprland 0.57**, sobremesa (sin batería), monitor MSI 1440p @ **144 Hz** por HDMI (`HDMI-A-1`).
- Login: **greetd + tuigreet** (autologin a `start-hyprland`; plasmalogin instalado pero disabled). Cursor **Adwaita** en GTK/Qt/Hyprland.
- Locale `es_ES.UTF-8`; **todo lo nuevo va con i18n**: cadenas vía `Tr.tr` / `Tr.trN` / `Tr.trCtx` → `es.po` → recompilar el plugin I18n e instalarlo en `~/.local`.
- Apps por defecto: **kitty** (terminal), **thunar** (explorador, `Super+E`, sirve `FileManager1` vía override D-Bus), **VLC** (vídeo), tema de iconos **Papirus(-Dark)**.
- Qt platform theme: **qt6ct** (`~/.config/qt6ct`, paleta + Papirus los empuja `caelestia-quiet` en cada esquema). Plasma en proceso de aislamiento (fase 1 hecha; fase 2 = desinstalar).
- VPN del trabajo: openfortivpn (credenciales **solo** en `~/.config/openfortivpn/config`, jamás en el repo).
- Steam: API key **solo en config local** (nunca commitearla; grep del diff antes de push). Perfil/logros públicos.
- OpenCode TUI: plugin sidebar file-tree es un **fork local** en `~/.config/opencode/plugins/opencode-file-tree` (colores git en el árbol; rebuild con `bun run build`, no npm; verificación en su `test.md`). El tema del TUI (`caelestia` + gemela `caelestia-alt` para el hot-reload por flip de nombre) lo genera `scripts/generate-opencode-theme.py` y lo engancha `caelestia-quiet.py`.

## 3. Convenciones de trabajo

- Tras cualquier cambio de QML/script: **reiniciar la shell** (`caelestia shell -r`, en background `-r -d`) y verificar que carga sin errores.
- Cualquier `sh -c`/`bash -c` que lleve contenido de usuario va **por argv (`"$1"`)**: `JSON.stringify` es quoting de JS, no de shell (lección: inyección en Clipboard). Contraseñas/secretos nunca a fichero: en RAM con `sudo -S -v` por paso (ver `scripts/run-system-update.sh`).
- Estilo **Material You estricto**: tokens, `MaterialShape`, blur/transparencia; los detalles visuales (padding, tamaños, sombras, centrados) se afinan con el usuario tras cada versión — espera feedback visual.
- Commits: **conventional commits** (`feat:` / `fix:` / `docs:`), a nombre del usuario. **NUNCA** dejar trailer `Co-authored-by: Cursor/agent`.
- Commits **locales por defecto**: el agente commitea a menudo, en commits agrupados, ordenados y bien explicados, pero **NO pushea a `origin`** — el usuario indica cuándo hacer push.
- `main` está **protegida** (toda escritura exige PR). Flujo: rama `feature/*` o `docs/*` + PR (vía `gh`, HTTPS), y merge de la PR. El push directo a `main` lo rechazan las rules del repo (GH013).
- `.gitignore` cubre `__pycache__/` y `.cursor-tmp/`.
- Opciones nuevas: nodo en config (GlobalConfig) si hace falta rebuild del plugin, exposición en Nexus, y **documentación en FEATURES.md**.

## 4. Mapa del código

### Servicios (`services/`, singletons QML)
| Servicio | Qué hace |
| --- | --- |
| `Activities` | Core del fork: pills en la barra, look por activity, apply atómico vía `scripts/apply-activity-style.py` (wallpaper + un solo `scheme set`; el modo de la activity gana a `smartScheme`; verify + reintentos). El apply es **serial**: lanzar en paralelo = carrera light/dark |
| `Colours` | Paleta, modo light/dark, `lightApps` (portal `prefer-light`; theming GTK off con light apps sin que pierda el CSS del esquema) |
| `Steam` | ~1040 líneas (deuda técnica). Web API + logros + no-Steam (VDF/Millennium) + sesiones (`reaper`). Al refrescar **conserva el juego seleccionado** |
| `Updates` | Poll 30 min (Arch/AUR/Flatpak); update: password popup → `sudo -S -v` + askpass síncrono → proceso en bg. Nunca `yay --sudoloop` (bloquea con faillock); en bg pasará `--sudoflags=-n` |
| `Clipboard` | cliphist + `wl-clipboard`; paste con foco restaurado (~220 ms) + `send_shortcut` / `wtype` |
| `MadisonVpn` | Status exige ping a intranet (no basta `ppp0`); teardown/heal tras suspender; popout OTP + settings |
| `Displays` | `hyprctl monitors -j`; VRR **por conector** (Nunca/Automático/Siempre) → `caelestia-monitors.lua` + `hyprctl reload` (sin reload VRR off no llega al CRTC) |
| `Hydration` / `Timers` | Complementos on/off; al off limpian estado/procesos y ocultan su UI |
| `Keybinds` | Grabación de teclas con submap vacío de Hyprland (inhibe binds), soporte F13–F35, diálogo de conflicto → `caelestia-binds.lua` |
| `Hypr` | Bridge de eventos de Hyprland; conectar directos cuando el `rawEvent` no se re-emite |

### UI
- `modules/nexus/pages/`: `DisplayPage`, `UpdatesPage`(+`UpdatesSettings`), `ComplementsPage`, `ShellPage` (activities + look), `KeybindsPage`, `LanguageAndRegion` (tiempo/ubicación)…
- Barra/popouts en `modules/bar/`; panel Juegos en `modules/dashboard/games/`.
- Trampas QML de este codebase: `PageBase` admite **un solo hijo**; no existe `IconButton.Standard`; `HoverHandler` usa `hovered` (no `containsMouse`); para drop de arrastres no fiarse de `DropArea` con reparent al drag-layer — detectar el target bajo el cursor; `ClipRect` no recorta por `radius` sin máscara; un `Process` con stdin heredado cuelga (usar `DEVNULL`); QML no permite anotaciones de tipo en parámetros con valor por defecto; `Row` no acepta asignar `implicitHeight`.

### Scripts (`scripts/`)
- `apply-activity-style.py` — apply de look completo en un solo proceso (~0,38 s).
- `caelestia-quiet.py` — aplica tema sin volcar secuencias OSC a los PTYs; recarga Kitty, sync Papirus/kdeglobals, GTK/colors.css.
- `sync-light-apps-cli.py` — reescrituras de `cli.json` **deben conservar** el postHook de Kitty.
- `steam-nonsteam.py` — VDF + IDs ocultos + sesiones Millennium + caché de historial.
- `steam-activity.py` — poll de procesos `reaper` (sesiones reales) + delta de `playtime_forever` como respaldo.
- `check-system-updates.py` / `run-system-update.sh` — chequeo (stdin `DEVNULL` + timeout) y update.
- `record.sh` / `record-start.sh` — grabación desacoplada del panel; `CAELESTIA_RECORDINGS_DIR`.

## 5. Features del fork (resumen)

1. **Activities** — Principal (no eliminable; las demás heredan su look), Juegos, Trabajo. Look por activity: wallpaper + esquema + modo + transparencia + light apps. Apps ancladas por desktop (reglas regex **RE2** con `(?i)`, sin `silent` para que el foco siga la ventana, reintento ~700 ms). Overview `Super+Tab` con drag & drop de ventanas (pins no arrastran). Atajos `Super+Ctrl+←/→` y toggle "saltar entre actividades".
2. **Pantalla** — modo/escala/VRR por monitor con política Nunca/Automático/Siempre.
3. **Juegos (Steam)** — complemento opt-in: stats en shapes M3, hero con portada, carrusel por `lastPlayed`, logros (rareza + bloqueados, descripción siempre visible), heatmap mensual navegable, juegos no Steam + Millennium + sesiones reales Steam.
4. **Updates** — página Nexus + icono/badge en la barra (solo si hay paquetes) + popout; password popup → update en bg con logs en vivo en Nexus.
5. **Clipboard** — popout estilo Caelestia (`m3surface` + blur), favoritos, búsqueda, previews de imágenes/rutas, pegar en la ventana enfocada.
6. **Madison VPN** — icono en status, dropdown al hover, OTP integrado, settings (host/puerto/user/pass), heal tras sleep.
7. **Complementos** — VPN, Timers, Hidratación (+ Juegos) con icono por fila y limpieza al desactivar. Hidratación: depósito con waves en el dashboard (el calendario del popout del reloj sigue), meta 3000 ml, presets +20/+83/+250/+500, recordatorio con acciones.
8. **Varios** — timers del reloj persistentes, grabación estable + chip REC, capturas sin notificación, clic en notificación → enfoca/abre la app en su workspace, launcher con edición de `.desktop` (hover inferior para abrirlo, se cierra al salir el puntero), tray/status con pastilla al hover unificada, recoloreado forzado a claro de tray sin contraste (Steam/Cursor), Keep-awake (café) activado por defecto, **layout compacto** (ex game mode: solo barra izquierda, gaps/rounding/border 0, sin tocar animaciones/blur/wobble), i18n ES completo, docs README/FEATURES/CHANGELOG.

## 6. Trampas / aprendizajes

- `cmake --install` **sobrescribe `shell.qml`**: revisar `git status` tras cada install y restaurar. (Con `ENABLE_MODULES=plugin` no pasa; la trampa solo aplica al módulo `shell`.)
- Regex de reglas Hyprland = **RE2** (`(?i)`, `\.`, patrones Lua `%%` no).
- Tras cambiar monitor/VRR: siempre `hyprctl reload`.
- El CLI volcaba secuencias OSC a todos los `/dev/pts`; el fork lo parchea vía `scripts/caelestia-quiet.py` — no quitar el wrapper.
- `Requests.get` ya lleva transfer timeout de 15 s (plugin C++, `~/.local`) — no quitarlo al tocar `requests.cpp`; sin él un hang deja `pending` > 0 para siempre.
- La caché HTTP/schema/logros de `Steam.qml` es solo en memoria (ver pendientes).
- `hyprctl` reporta un booleano de VRR: la **política** vive en el Lua, no la pises con el estado.

### Aislamiento de Plasma (aprendizajes fase 1)

- `QT_QPA_PLATFORMTHEME` tiene **3 fuentes** (pragma de `shell.qml`, `hyprland.lua`, `environment.d`): las tres a la vez o nada; el env de Hyprland y `environment.d` solo normalizan al relogin, el pragma al restart de la shell.
- `_sync_qt6ct` escribe el esquema con **22 roles** (orden del enum `QPalette::ColorRole` de Qt ≥6.6, `Accent` al final — qt6ct mapea índice→rol literal). Escritura atómica temp+rename: el watcher de qt6ct es dir-scoped con debounce.
- `libcolorreload-gtk-module.so` vive vendorizado en `~/.local/share/gtk-3.0/modules/` (GTK resuelve módulos por nombre ahí); **no existe build GTK4 del módulo** (kde-gtk-config solo compila GTK3).
- D-Bus service duplicates: dbus-broker escanea dirs y **el primero que registra gana** (alfabético dentro del dir) — los overrides de usuario van en `~/.local/share/dbus-1/services/` y ganan a `/usr/share`. Tras crear uno, dbus-broker-launch *nota* el cambio y re-escanea (journal: "Noticed file-system modification, trigger reload").

## 7. Pendiente / roadmap

- [ ] **Fase 2 — desinstalar Plasma (~237 paquetes, ~1379 MiB)**: validar de nuevo `pacman -Rs` con la lista; keep-set primero a `--asexplicit` (`plasma-integration kde-gtk-config bluez bluez-utils noto-fonts-emoji ttf-hack`); retirar el dual-write de `kdeglobals [Icons]` tras desinstalar `plasma-integration`; limpiar configs/caches/estado KDE (`~/.config/{KDE,kdedefaults,kwin*,plasma-*,baloo*,kwalletrc}`, `~/.cache/plasmashell`, `~/.local/share/{baloo,plasma,kactivitymanagerd,kwalletd}`); revisar portales (el portal de KDE queda muerto) y kwallet.

- [ ] **Caché de logros de Steam en disco** (TTL ~1 día) para no re-pedir la biblioteca al arrancar.
- [ ] **Partir `services/Steam.qml`** por capas si se crece (API / librería / sesiones / formateo).
- [ ] `steam-activity.py`: mandar el snapshot **por stdin** en vez de argv (riesgo `ARG_MAX`).
- [ ] Tests pytest ligeros: parser VDF, merge de sesiones Millennium, residual delta/sesión.
- [ ] Keep-awake se reactiva siempre al arrancar la shell: persistir su estado.
- [ ] Heatmap de Steam vacío: pie explicativo ya existe; considerar rellenar cifras del mes con logros cuando no hay tiempo.
- [ ] A futuro: si upstream monta plugins de verdad, mover Madison VPN y Timers como plugins.

---

*Última actualización: 2026-10-29 (repaso integral: Clipboard argv/verificación de paths, VPN busy guard, Activities verify cap, Requests 15 s + plugin build user-local, Updates askpass en RAM + heartbeat, Displays hotplug, Steam cap/gate del reload; aislamiento de Plasma fase 1: greetd+tuigreet, theme Qt6ct con paleta Material, module GTK vendorizado, FileManager1 → Thunar, cursor Adwaita). Mantener este fichero al día con cada feature grande o aprendizaje nuevo.*
