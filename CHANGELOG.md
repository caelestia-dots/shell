# Changelog

Cambios relevantes de este fork respecto a releases internas. El detalle de uso está en [FEATURES.md](./FEATURES.md).

## 2026-10-26

### Launcher

- Menú contextual al clic derecho sobre apps (editar `.desktop`, favoritos, ocultar, restablecer).
- Diálogo de edición centrado (`DesktopEditDialog`) con selector de icono; el launcher no se cierra al editar.
- Un solo menú contextual abierto a la vez (`Menus.qml`); el clic en ítems funciona sobre el texto.
- Overrides de `.desktop` resueltos y guardados de forma fiable en `~/.local/share/applications`.

### Grabación de pantalla

- Arranque desacoplado del panel (`scripts/record-start.sh` + `execDetached`) para que no se cancele al salir el ratón o cambiar de workspace.
- Utilities/sidebar se mantienen abiertos mientras `Recorder.running` / `arming`.
- Indicador **REC** / **PAUSE** bajo el reloj en la barra.
- El botón principal no re-dispara start durante una captura activa.

### Activities / tema

- Overview: arrastrar ventanas entre desktops/activities y enfocar el destino al soltar.
- Estilo por activity al cambiar de foco (wallpaper, esquema, modo, transparency, light apps).
- Integración Kitty: plantilla de usuario, `include` del tema generado, recarga en vivo al cambiar activity.
- `caelestia-quiet.py` recarga Kitty tras aplicar colores; `sync-light-apps-cli.py` conserva el hook de recarga (ya no lo pisa).

### Barra / UI

- Centrado estable del reloj.
- Traducciones ES ampliadas para las cadenas nuevas.
