# Qué incluye este fork

Documento orientado a **usuarios finales**: diferencias y mejoras respecto a [caelestia-shell](https://github.com/caelestia-dots/shell) upstream.

Repositorio: [iMacnucintosh/hyprland-shell](https://github.com/iMacnucintosh/hyprland-shell).

---

## Resumen rápido

| Área | Qué ganas |
| --- | --- |
| **Activities** | Espacios de trabajo agrupados (Casa / Trabajo / Juegos…), overview, estilo por actividad |
| **Barra** | Pills de actividades, iconos de apps en workspaces, indicador **REC**, tray y status más claros |
| **Reloj** | Popout con calendario + temporizadores (con sonido y persistencia) |
| **Grabación** | Estable (no se corta al salir del panel); guarda en `~/Vídeos/Videocapturas de pantalla` |
| **Notificaciones** | Clic → enfoca la app / ventana relacionada |
| **Nexus** | Página **Shell** para configurar activities y aspecto |
| **Launcher** | Hover inferior, edición de `.desktop`, iconos Papirus |
| **Kitty / GTK** | Paleta alineada a la activity (Kitty + Thunar/Material) |
| **Madison VPN** | Icono bajo Bluetooth: OTP / desconectar; engranaje para editar `openfortivpn`; limpia túnel tras sleep |
| **Utilities** | Mantener activo (café) en interruptores rápidos, ON por defecto |
| **Clipboard** | Historial estilo Plasma (cliphist): Super+Shift+V, pegar en la ventana enfocada, favoritos |
| **Updates** | Arch / AUR / Flatpak: icono+badge, popout, Nexus; update en fondo (panel) o con logs (Nexus) |
| **Atajos** | Remapeables desde Nexus; Super+E → Thunar; atajos de activities |

---

## Activities (espacios agrupados)

Sistema opcional (activado por defecto en este fork) que agrupa desktops de Hyprland en **actividades**.

### En la barra

- En lugar del strip clásico de workspaces, ves una **pill por actividad** (icono + sus desktops).
- Clic en el icono de la actividad → salta a su primer desktop.
- El scroll de workspaces se queda **dentro** de la actividad actual (no salta a otra actividad).

### Overview

- Atajo por defecto: **Super + Tab** (remapeable).
- Vista a pantalla completa de todas las actividades y sus desktops.
- Clic en un desktop para ir a él.
- Arrastra ventanas entre desktops (también entre activities); al soltar se enfoca el destino y se aplica su look.
- Apps **ancladas (pinned)** no se arrastran y muestran un icono de pin.
- Cierra con Escape o clic fuera.

### Cambiar de actividad

- Por defecto: **Super + Ctrl + ← / →** (al primer desktop de la activity anterior/siguiente).
- Remapeable en **Nexus → Keyboard & mouse**.

### Estilo por actividad

Al cambiar de actividad puedes aplicar (y recordar) de forma independiente:

- Wallpaper
- Esquema / colores
- Modo claro / oscuro
- Transparencia
- “Light apps” (apps Adwaita/Qt en claro aunque el shell esté oscuro)

Las actividades que no son la principal pueden **heredar** el look de Home o definir el suyo.

El apply es **un solo proceso** (`scripts/apply-activity-style.py`): evita carreras light/dark y respeta el modo de la activity aunque `smartScheme` esté activo. GTK/Thunar se actualizan con la paleta Material (recarga en vivo vía `colors.css` + `colorreload-gtk-module`).

### Apps ancladas a un desktop

Desde **Nexus → Shell** puedes asociar aplicaciones a un desktop concreto de una activity.  
Hyprland aplica esas reglas al arrancar (archivo generado `~/.config/hypr/caelestia-activity-rules.lua`).

### Configuración

**Nexus → Shell**:

- Activar / desactivar activities
- Mostrar iconos de apps en los workspaces de la barra
- Crear, renombrar, elegir icono y número de desktops (1–10)
- Look por activity
- Pin de apps por desktop

Defaults de ejemplo: Home (2 desktops), Games (1), Work (2).

### Setup Hyprland (importante)

En tu config Lua de Hyprland:

```lua
require("caelestia-binds")           -- atajos (Nexus → Keyboard & mouse)
require("caelestia-activity-rules")  -- reglas de activities / pins (Nexus → Shell)
```

---

## Launcher (menú de aplicaciones)

- Atajo (en tu setup): **Alt + Space** (remapeable en Nexus → Keyboard & mouse).
- También se abre al llevar el puntero al **borde inferior**, en la zona centrada del launcher (como un panel).
- Se cierra al sacar el puntero (como el dashboard), con Escape, al elegir una app, o al perder el foco.
  Si lo abriste con el atajo, se mantiene hasta Escape / elegir app (igual que el resto de paneles por tecla).
- Se puede desactivar el hover en **Nexus → Panels → Launcher → Show on hover**.
- **Clic derecho** sobre una app: menú contextual (un solo menú abierto a la vez) con:
  - Editar nombre / descripción / icono (diálogo centrado; el launcher no se cierra al editar)
  - Override guardado en `~/.local/share/applications`
  - Favoritos, ocultar o restablecer la personalización

---

## Grabación de pantalla

- Card de **Screen recorder** en el panel de utilities (fullscreen / región, con o sin audio).
- El arranque va **desacoplado** del ciclo de vida del panel (`scripts/record-start.sh` / `record.sh`), así la captura **no se aborta** al sacar el ratón del panel o al cambiar de desktop.
- Mientras grabas, utilities/sidebar **permanecen abiertos** al salir el puntero (evita teardowns mid-capture).
- Indicador **REC** / **PAUSE** bajo el reloj en la barra mientras hay grabación activa.
- El chip principal del recorder no re-dispara start mientras ya está grabando (evita toggle-stop accidental).
- Archivos en **`~/Vídeos/Videocapturas de pantalla`** (override: env `CAELESTIA_RECORDINGS_DIR`).
- Desde la lista: reproducir, abrir carpeta (Thunar) o borrar.

---

## System updates

Inspirado en [arch-update-checker](https://github.com/iMacnucintosh/arch-update-checker):

- **Nexus → Updates**: refrescar, contador, actualizar sistema, lista expandable (info / update / uninstall / URL).
- Engranaje → fuentes (Arch / AUR / Flatpak, todas on por defecto), wrapper AUR (**yay**), intervalo, notificaciones, single-package.
- Icono en status (junto a Madison VPN) **solo si hay paquetes**; badge con el número; popout rápido.
- Poll cada **30 min**; toast al detectar paquetes nuevos (default on).
- **Actualizar sistema**: popup de contraseña → en **panel** corre en segundo plano; en **Nexus** muestra log en vivo. Notificación al terminar + rechequeo. Paquete suelto / orphans siguen en terminal.

---

## Madison VPN (FortiClient / openfortivpn)

Icono en la pastilla de status (debajo de Bluetooth):

- Clic desconectado → diálogo OTP integrado → conecta
- Clic conectado → desconecta
- Estado con poll (`~/.local/share/madison-vpn/status_vpn.sh`); exige que la intranet responda (no basta con `ppp0` vivo)
- Tras **suspender el PC**: al reanudar se ejecuta `heal` (limpia túnel zombie + DNS/`hosts`) y el icono refleja la realidad

Scripts e install: repo privado [madison_vpn_widget](https://github.com/iMacnucintosh/madison_vpn_widget) → carpeta `hyprland/`:

```bash
cd madison_vpn_widget/hyprland && ./install.sh
```

Credenciales en `~/.config/openfortivpn/config` (las mismas que Plasma; **no** van en este repo). Engranaje en el popout VPN para editar host/puerto/usuario/`set-dns`/`trusted-cert` (password/OTP no se muestran). En Nexus → Panels → Status icons puedes mostrar/ocultar «Madison VPN».

---

## Utilities / mantener activo

- En **interruptores rápidos**: icono de café (**Keep awake**), a la izquierda del gamepad.
- **Activado por defecto** (bloquea idle/suspend del compositor vía idle inhibitor).
- La card grande «Mantener activo» está oculta por defecto (se puede volver a mostrar en Nexus → Panels → Utilities → Cards).

---

## Explorador y theming GTK

- Explorador por defecto: **Thunar** (`general.apps.explorer` + Super+E + `xdg-mime` para carpetas).
- Para que Thunar/GTK sigan el esquema de Caelestia: `adw-gtk-theme`, `papirus-icon-theme`, y `GTK_MODULES=colorreload-gtk-module` (Hyprland).
- Iconos de apps en el launcher: tema **Papirus** (sincronizado en `~/.config/kdeglobals` al aplicar el esquema).
- Diálogos `pkexec` (Timeshift, VPN helper, etc.): activa `hyprpolkitagent.service` (`systemctl --user enable --now hyprpolkitagent`).

---

## Kitty y colores de la activity

Kitty no es un target nativo de Caelestia; este fork lo integra así:

1. Plantilla de usuario: `~/.config/caelestia/templates/kitty.conf` (variables `{{ surface.hex }}`, `{{ term0.hex }}`, …).
2. Generada en: `~/.local/state/caelestia/theme/kitty.conf`.
3. En `~/.config/kitty/kitty.conf`:

```conf
include ~/.local/state/caelestia/theme/kitty.conf
allow_remote_control yes
listen_on unix:${XDG_RUNTIME_DIR}/kitty-{kitty_pid}.sock
```

4. Recarga en vivo al cambiar wallpaper / esquema / activity:
   - `~/.config/caelestia/scripts/kitty-reload-colours.sh`
   - Hook en `cli.json` (`theme.postHook` / `wallpaper.postHook`)
   - `scripts/caelestia-quiet.py` (usado por la shell) llama a esa recarga tras aplicar colores
5. En zsh (ventanas nuevas): `cat ~/.local/state/caelestia/sequences.txt` en `~/.zshrc`.

Tras el primer arranque de Kitty con `listen_on`, al cambiar de activity (barra, atajos u overview) la paleta de las ventanas abiertas se actualiza sola.

---

## Reloj y temporizadores

Al pasar el ratón por el **reloj** de la barra:

1. **Calendario** (el mismo del dashboard).
2. **Temporizadores**:
   - Presets: **5 / 10 / 20 / 30** min
   - Duración manual (1–180 min): escribe el número y pulsa Enter o +
   - Lista de timers activos con cuenta atrás y cancelar
   - Al terminar: aviso (toast) + sonido del sistema
   - Se **conservan** si reinicias la shell (estado en `~/.local/state/caelestia/timers.json`)

El reloj lleva siempre la pastilla de fondo; al hover se resalta como el resto de la barra.

---

## Notificaciones

- **Clic izquierdo** en un popup o en la card de la **sidebar**: enfoca/abre la app (workspace, tray o `.desktop`) y cierra la notificación. No hay botón aparte de “abrir”.
- Botones de la card: cerrar, acciones de la app (si tienen texto/icono útil) y copiar; se ocultan acciones vacías (p. ej. Teams).
- Compatible con `actionOnClick` cuando hay una sola acción de notificación.

---

## Barra (otros retoques)

- **Tray**: muestra también ítems en estado Passive (p. ej. Teams en idle); highlight al hover / menú abierto; tamaño de icono estable.
- **Status icons**: pastilla al hover como el tray; en PC de sobremesa se oculta el icono de batería.
- **Popouts** de status un poco más anchos para que no se recorten.
- **Reloj** centrado de forma estable en el slot de la barra.
- Indicador de **grabación** bajo el reloj (ver sección anterior).
- En escritorio sin batería: perfil de energía forzado a Performance; controles de perfil solo en portátil.

---

## Nexus y atajos

Ya presentes en este fork respecto a un Caelestia “vanilla” típico:

- **Atajos de Hyprland remapeables** desde Nexus (genera `caelestia-binds.lua`).
- Categoría **Activities** en el mapa de teclas (siguiente / anterior / overview).
- Página **Shell** (activities + opciones de barra relacionadas).
- UI de colores / wallpapers acoplada al look de la activity en edición.
- Traducciones **español** ampliadas para las cadenas nuevas.

---

## Clipboard (historial)

Popout flotante junto al cursor (estilo Caelestia), respaldado por **cliphist** + `wl-clipboard`:

- Atajo por defecto: **Super + Shift + V** (Super+V sigue siendo float de ventana; remapeable en Nexus).
- Buscar, favoritos persistentes (estrella a la derecha; vacía solo al hover), borrar entradas o limpiar historial.
- Al elegir un ítem: se copia y se pega con **Ctrl+V** en la ventana que tenía el foco (`wtype`).
- Texto, imágenes del portapapeles (miniatura) y rutas/`file://` a imagen copiadas desde el explorador (también con preview).
- Fondo igual que el panel izquierdo (`m3surface` + blur de Hyprland).
- Límite de historial configurable (por defecto **50**) en **Nexus → Services → Clipboard**.
- Dependencias: `cliphist`, `wl-clipboard`, `wtype`.

---

## Atajos por defecto (activities)

| Acción | Atajo por defecto |
| --- | --- |
| Overview de activities | Super + Tab |
| Activity anterior | Super + Ctrl + ← |
| Activity siguiente | Super + Ctrl + → |
| Historial del clipboard | Super + Shift + V |

Cámbialos en **Nexus → Keyboard & mouse**.

---

## Notas

- Esto es un **fork**: no sustituye la documentación de instalación de upstream ([README](./README.md)).
- Historial de cambios recientes: [CHANGELOG.md](./CHANGELOG.md).
- Algunas piezas siguen en evolución; si algo no aparece tras actualizar, reinicia la shell (`caelestia shell -r`) y comprueba los `require(...)` de Hyprland.
- `scripts/caelestia-quiet.py` evita spamear OSC a todos los PTY al cambiar el tema (recarga Kitty, sync Papirus/kdeglobals, GTK/`colors.css`).
- `scripts/apply-activity-style.py` aplica wallpaper + esquema de la activity en un solo proceso.
