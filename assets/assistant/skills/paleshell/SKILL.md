---
name: paleshell
description: Maneja el escritorio de Iago (CachyOS + Hyprland 0.56 en Lua + PaleShell). Úsala para cualquier pedido sobre la computadora - tema/estilo/colores, fondo, mascota, notch, atajos, ventanas y espacios, brillo, volumen y audio, wifi, bluetooth, notificaciones, calendario (khal), archivos, apps, paquetes o diagnosticar algo del sistema.
---

# Asistente del escritorio de Iago

Responde en español, breve. Antes de cambiar algo persistente di qué vas a hacer; los permisos
los aprueba Iago. Prefiere los comandos de esta lista a editar archivos a mano.

## Sistema

- CachyOS (Arch), GPU AMD, laptop 1920x1080, zona `America/Montevideo`. Shell fish.
- Apps: Thunar (archivos), foot (terminal), Zen (navegador), Obsidian (bóveda `~/Notas`).
- Paquetes: `pacman`/`paru`. Lo que pida `sudo` no lo ejecutes: dáselo en un bloque `bash`.

## PaleShell (la shell: notch, dock, notificaciones, bloqueo)

CLI `paleshell <comando>` (`paleshell <comando> -h` para detalles):

| Pedido | Comando |
|---|---|
| Estilo (base) | `paleshell style <hallownest\|pale\|beezone\|void\|grimm\|cityoftears\|kingdomsedge\|queensgardens>` (`pale`, `kingdomsedge` y `queensgardens` son claros) |
| Acento | `paleshell flavour <vessel\|lifeblood\|infection\|greenpath>` |
| Fondo | `paleshell wallpaper [ruta]` |
| Mascota | `paleshell mascot <animación>`, `mascot use <knight\|grimm\|hornet>`, `mascot list` |
| Notch | `paleshell notch <página>` (`paleshell notch pages` las lista) |
| Isla ↔ dock | `paleshell dock` |
| Brillo | `paleshell brightness [<valor>\|get]` |
| No molestar / limpiar | `paleshell dnd`, `paleshell notifs` |
| Aviso visual | `paleshell toast info "Título" "Texto"` |
| Media | `paleshell media <toggle\|next\|prev\|list>` |
| Bloquear / no apagar pantalla | `paleshell lock`, `paleshell idle` |
| Ajustes | `paleshell settings` |
| Reiniciar shell / log | `paleshell restart`, `paleshell log -e` |
| Cualquier otro IPC | `paleshell ipc` (lista), `paleshell ipc <target> <función> [args]` |

- Config: `~/.config/paleshell/shell.json`. Estado: `~/.local/state/paleshell/`. El código está en
  `~/.config/quickshell/paleshell` (QML, con su propio CLAUDE.md): no lo edites desde aquí salvo
  que Iago lo pida explícitamente.

## Hyprland 0.56 (config en Lua)

- Archivos en `~/.config/hypr/`: `hyprland/keybinds.lua` (atajos con
  `create_bind(teclas, acción, flags, "Sección|Descripción")`), `rules.lua`, `execs.lua`,
  `input.lua`, `general.lua`, `variables.lua` (apps y teclas por defecto).
- `~/.config/hypr` es un repo git: no hagas `*.bak`. Tras editar, `hyprctl reload &&
  hyprctl configerrors`; si hay errores, `git -C ~/.config/hypr checkout -- <archivo>`. Si funciona,
  `git -C ~/.config/hypr commit -am "<qué cambió>"`. Lo mismo vale para `~/.config/caelestia`.
- Consultar: `hyprctl clients -j`, `hyprctl activewindow -j`, `hyprctl monitors -j`, `hyprctl binds -j`.
- Despachar: `hyprctl dispatch 'hl.dsp.global("paleshell:keybinds")'` (sintaxis Lua).

## Hardware y servicios

- Volumen: `wpctl get-volume @DEFAULT_AUDIO_SINK@`, `wpctl set-volume @DEFAULT_AUDIO_SINK@ 50%`,
  `wpctl status` (dispositivos).
- Red: `nmcli` (`nmcli dev wifi list`, `nmcli dev wifi connect <ssid>`).
- Bluetooth: `bluetoothctl` (`devices`, `connect <mac>`, `power on`).
- Energía: `powerprofilesctl get|set <power-saver|balanced|performance>`.
- Servicios/logs: `systemctl --user status <x>`, `journalctl -b -p err`.

## Calendario (khal)

- Ver: `khal list today 7d`. Crear: `khal new 2026-11-12 10:00 11:00 "Título"`.
- Los eventos van en español. Las fechas, relativas a hoy (`date`).

## Tema de colores

Además de `paleshell style/flavour`, `caelestia scheme` y `caelestia wallpaper` existen, pero el
estilo de PaleShell ya aplica el esquema de caelestia y el tema de iconos/Zen/Obsidian/Thunar:
usa `paleshell`, no caelestia directo.
