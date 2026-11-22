# Estética de PaleShell

Guía para crear apps, ventanas, widgets o páginas web con el mismo diseño que la shell. La fuente de
verdad del código es `assets/styles.json` (colores), `services/Hallownest.qml` (paleta en QML),
`components/hallownest/` (controles) y `plugin/src/Caelestia/Config/tokens.hpp` (curvas y duraciones).
Si algo de aquí contradice al código, manda el código: corrige este archivo.

## 1. Idea general

Inspirada en **Hollow Knight**: un reino subterráneo en penumbra, objetos de un azul-gris muy oscuro
que flotan sobre el Vacío, iluminados por una luz pálida (el *Alma*). Tres rasgos lo definen:

- **Oscuridad en capas**: casi todo es fondo oscuro; la jerarquía se marca con escalones de
  luminosidad mínimos y bordes finísimos, no con sombras duras ni colores saturados.
- **Una sola luz**: el acento (`soul`) es el único color fuerte en pantalla. Los colores de
  "amuletos" (`lifeblood`, `grimm`, `gold`…) aparecen solo con un significado (estado, alerta).
- **Ornamento discreto**: rombos en vez de círculos para indicadores, filigrana fina en las esquinas,
  títulos en serif tallada (Cinzel), brillos suaves (glow) en lo que está activo. Nada recargado.

Movimiento: rápido y sin rebote, como el *dash* del Caballero. Arranca rápido y frena suave.

## 2. Color

### 2.1 Niveles de fondo (de más profundo a más elevado)

| Token QML | Rol | hallownest | pale (claro) |
|---|---|---|---|
| `Hallownest.void_` | Fondo absoluto: notch, isla, ventanas a pantalla completa, texto sobre botones rellenos | `#07090e` | `#f6f4ee` |
| `Hallownest.shell` | Fondo de ventana/panel | `#0e121b` | `#ece9e0` |
| `Hallownest.card` | Tarjetas, filas, campos de texto | `#151a26` | `#e2ded3` |
| `Hallownest.button` | Botones y controles en reposo | `#1c2230` | `#d6d1c4` |
| `base.bright` (solo JSON) | Hover fuerte / scrollbars en temas externos | `#2a3346` | `#c5bfb0` |

Regla: **cada nivel se aleja del fondo**. En estilos oscuros sube en luz; en `pale` (claro) `void_`
es el más claro y los niveles oscurecen. Nunca pongas un nivel "más profundo" encima de uno más alto.

### 2.2 Texto

| Token | Uso | hallownest |
|---|---|---|
| `text` | Texto normal | `#d7e0ec` |
| `subtext` | Secundario, iconos inactivos, subtítulos | `#9aa6b8` |
| `faint` | Placeholders, deshabilitado, metadatos | `#546073` |
| `soul` | Texto destacado, valores, títulos, selección | según flavour |

### 2.3 Acento y bordes (dependen del *flavour*)

| Token | Rol |
|---|---|
| `soul` (`accent`) | La luz principal: activo, seleccionado, foco, títulos, botón relleno |
| `steel` | Ornamentos, títulos de sección, rombos inactivos, filigrana |
| `border` | `Qt.alpha(steel, 0.15)`: el borde de 1 px de casi todo |
| `tertiary` / `error` / `success` | Solo en el esquema de terminal/apps externas (vía `caelestia`) |

Flavours (en `hallownest`):

| Flavour | accent | steel |
|---|---|---|
| `vessel` (por defecto) | `#f5f9ff` blanco pálido | `#9ba4b5` |
| `lifeblood` | `#6cc9ff` azul | `#8fb3cc` |
| `infection` | `#ff8a2a` naranja | `#b8a08f` |
| `greenpath` | `#74c98a` verde | `#94b39c` |

### 2.4 Colores de amuleto (semánticos)

| Token | hallownest | Significado |
|---|---|---|
| `lifeblood` | `#38bdf8` | Activo/encendido (switches), cargando, selección de texto, conectado |
| `grimm` | `#e63946` | Peligro, alerta, batería baja, apagar, error |
| `gold` | `#f4a261` | Aviso, destacado, agentes de IA trabajando, próxima clase |
| `unn` | `#52b788` | Éxito, OK |
| `infection` | `#ff6b35` | Advertencia caliente, uso alto |
| `crystal` | `#a8dadc` | Info fría, decorativo |
| `glowBlue`, `hotSpring`, `lifebloodSoft/Deep` | | Variantes para gráficos y escenas |

### 2.5 Estilos (`style`) disponibles

Oscuros: `hallownest` (azul noche, por defecto), `beezone` (ámbar/miel), `void` (blanco y negro,
`"mono": true`: los amuletos se vuelven grises), `grimm` (carmesí), `cityoftears` (azul lluvia, con
lámparas doradas como terciario). Claros (`"light": true`): `pale` (crema), `kingdomsedge` (gris
ceniza, frío), `queensgardens` (verde salvia, con rosa de flor como terciario). Todos tienen los cuatro
flavours. Valores exactos en `assets/styles.json`.

### 2.6 Reglas de uso

- **Tintes con alfa, no colores nuevos**. Patrones fijos del código:
  - fondo tintado: `Qt.alpha(accent, 0.12–0.16)` (hover `0.20–0.24`)
  - borde tintado: `Qt.alpha(accent, 0.35–0.55)`; foco `Qt.alpha(soul, 0.5)`
  - pista de slider/progreso vacía: `Qt.alpha(steel, 0.18)`
  - selección de lista: fondo `Qt.alpha(soul, 0.06)`, borde `Qt.alpha(soul, 0.14)`
- **Hover**: `Hallownest.raise(color, k)` (k ≈ 1.6–1.7 en botones). Nunca `Qt.lighter`: en `pale`
  hay que oscurecer.
- **Deshabilitado**: `opacity: 0.4`.
- Sobre un fondo relleno de acento, el texto/icono va en `void_`.
- La UI propia usa `Hallownest.*`, no `Colours.palette.*` (eso es Material 3 heredado de Caelestia).

## 3. Tipografía

| Familia | Dónde | Cómo |
|---|---|---|
| **Cinzel** (serif romana, `Hallownest.serif`, `assets/fonts/cinzel`) | Títulos, encabezados de sección, nombres de página, nombres de hablante en diálogos | Bold, `letterSpacing` 0.6–0.8 |
| **Noto Serif** (`Hallownest.bodySerif`) | Cuerpo de diálogos NPC (`NotifView`) | 9.5 pt |
| **Google Sans Flex** (por defecto de `StyledText`, con `ROND = 0`) | Cuerpo, etiquetas, botones | 9–10 pt; botones DemiBold |
| **JetBrainsMono Nerd Font** (`Hallownest.mono`) | Números que cambian (steppers, porcentajes, horas), código | Bold para valores |
| **Material Symbols Rounded** (`MaterialIcon`) | Iconos | tamaño con `fontStyle: Tokens.font.icon.small/medium`; `fill: 1` cuando está activo |

Tamaños habituales: título de ventana `HkTitle` 12 pt (más grande en cabeceras), sección `HkSection`
10 pt en `steel`, texto 10 pt, subtexto 8 pt, botones 9 pt.

## 4. Forma y espaciado

- **Radios**: tarjetas 14 (`HkCard`), popups 12, botones con texto y campos 9 (`HkButton`, `HkField`,
  botones solo-icono circulares), barra de búsqueda 12 (`SearchBar`), switches en píldora (`height / 2`),
  notch expandido 26, colapsado ≤ 14. Tokens `Tokens.rounding.*`: 4, 8, 12, 16, 20, 28, 32, 48.
- **Filas agrupadas** (`ToggleRow`, `StepperRow`, `SelectRow` de `modules/nexus/common`): esquinas 14 en la primera y última del grupo, 4 en las intermedias,
  separadas por 2–4 px; parecen una sola tarjeta segmentada. Alto mínimo 44.
- **Bordes**: 1 px en `border` en todo (botones, tarjetas, campos). Sin bordes gruesos.
- **Alturas de control**: botón y campo 30, botón pequeño 24, switch 38×20.
- **Espaciado** (`Tokens.spacing/padding`): 4, 8, 12, 16, 20, 28, 32, 48 (`extraSmall` …
  `extraExtraLarge`; no existe `normal`). Padding de botón con texto: 12 a cada lado.
- **Rombos**: los indicadores (radio, pulgar del switch, puntos de página, marca activa de toggle)
  son cuadrados rotados 45° con `radius` 0–2, no círculos. Las casillas de verificación sí son
  círculos (`HkCheck`).
- **La isla**: el notch cuelga del borde superior; su forma (`IslandShape`) tiene esquinas inferiores
  redondeadas y *filetes* cóncavos arriba que lo funden con el borde de la pantalla. Fondo `void_`.

## 5. Luz, profundidad y ornamento

- **Glow** en vez de sombra: `MultiEffect` con `shadowEnabled`, offset 0, `shadowColor` = el color
  del elemento, `shadowBlur` 0.5–0.8, `blurMax` 8–24. Se usa en lo activo: rombo de página actual,
  relleno del slider, punteros de selección, la máscara con `glow`.
- El notch proyecta un halo (`blurMax` 32, offset vertical 3) que cambia según el estado: negro en
  reposo, `lifeblood` activo, `gold` con agentes, `grimm` en temporada Grimm.
- **Filigree**: trazo de 1 px en `steel` en las esquinas inferiores, con gemas en rombo; opacidad
  0.22–0.3. Va en tarjetas `ornate` y en el notch expandido. Úsalo en una o dos superficies
  principales, no en todas.
- **HkSelection**: elemento seleccionado con fondo apenas tintado y dos punteros en rombo a los lados
  que pulsan (1.4 s, seno) con glow.
- **Partículas de Alma** (`SoulParticles`): motas de 2 px que suben y se desvanecen. Ambiente, nunca
  protagonista.
- **SoulVessel**: recipiente circular con líquido que se balancea, para niveles (batería, volumen…).
- **Máscara** (`Mask`, `HealthMask`): la máscara del Caballero como icono/medidor.
- Dibujos del usuario (Inkscape) como `PathSvg` en coordenadas del SVG original.

## 6. Movimiento

Curvas propias en `tokens.hpp`, sin sobrepaso:

| Tipo (`Anim.*`) | Bezier | Duración | Para |
|---|---|---|---|
| `FastSpatial` | 0.16, 1, 0.3, 1 | 350 ms | Presionar, mover pulgares, crecer rombos |
| `DefaultSpatial` | 0.2, 1, 0.32, 1 | 500 ms | Tamaños y posiciones de paneles, notch |
| `SlowSpatial` | 0.25, 0.9, 0.3, 1 | 650 ms | Entradas grandes |
| `FastEffects` | 0.4, 0, 0.2, 1 | 150 ms | Opacidades rápidas |
| `DefaultEffects` | 0.4, 0, 0.2, 1 | 200 ms | Fundidos, `fill` de iconos |
| `SlowEffects` | 0.45, 0, 0.15, 1 | 300 ms | Fundidos lentos |

- Color: `Behavior on color { CAnim {} }` en todo lo que cambia de estado.
- Presionar: `scale: pressed ? 0.94 : 1` (casillas 0.85) con `FastSpatial`.
- Texto que cambia (`StyledText.animate`): se desvanece y reaparece.
- Bucles ambientales con `Easing.InOutSine` y periodos lentos (1.4–3.2 s).
- Lo que debe terminar sí o sí (tipeo de diálogos) va con `Timer`, no con animaciones.
- Trazos que se dibujan: `ShapePath.trim.end` de 0 a 1 (Qt ≥ 6.10); `Filigree.drawn` ya lo expone. Lo usan
  el overview (salas trazadas a pluma) y la transición de estilo.
- Cambio de estilo (`modules/styletransition`): velo en el `void_` viejo (280 ms), el tema se aplica
  debajo (`Hallownest.setTheme` espera 300 ms), el velo pasa al color nuevo mientras la filigrana se
  traza en las cuatro esquinas y aparece el nombre del estilo en Cinzel, y todo se desvanece (~2 s).

## 7. Componentes (`components/hallownest/`)

Úsalos siempre antes que los controles M3 o los de Qt.

| Componente | Qué es |
|---|---|
| `HkButton` | Píldora; `filled` (acento sólido), `tinted` (fondo alfa del acento) o neutro; `icon`, `iconAfter` |
| `HkSwitch` | Interruptor píldora con pulgar en rombo; encendido en `lifeblood` |
| `HkCheck` / `HkRadio` | Casilla circular / opción con rombo |
| `HkField` | Campo de texto píldora sobre `card`, `leadingIcon`, borde de foco en `soul` |
| `HkSelect` | Desplegable (botón + popup `HkCard`) |
| `HkSlider` | Pista de 4 px, relleno con glow, pulgar en rombo |
| `HkStepper` | − valor (mono) + |
| `HkCard` | Tarjeta `card`, radio 14, luz cenital superior; `ornate` añade grano (`HkGrain`), doble marco interior y filigrana |
| `HkGrain` | Textura sutil de grano mineral/papel (`assets/hallownest/grain.png`) para superficies principales |
| `HkTitle` / `HkSection` | Título Cinzel en `soul` / encabezado de sección Cinzel en `steel` |
| `HkDivider` | Separador horizontal con líneas degradadas y rombo central |
| `HkSelection` | Resaltado de elemento seleccionado con punteros pulsantes |
| `CharmNotches` | Indicador de páginas en rombos que se expande a iconos al pasar el ratón |
| `Filigree`, `IslandShape`, `SoulVessel`, `SoulOrb`, `SoulParticles`, `HealthMask`, `Mask` | Ornamento y medidores |

Esqueleto típico de una ventana propia:

```qml
FloatingWindow {
    color: Hallownest.shell

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        HkTitle { text: Tr.tr("Title"); size: 14 }
        HkSection { first: true; text: Tr.tr("Section") }
        ToggleRow { first: true; text: Tr.tr("Option"); checked: true }   // qs.modules.nexus.common
        StepperRow { label: Tr.tr("Value"); value: 3 }
        HkButton { filled: true; text: Tr.tr("Apply"); icon: "check" }
    }
}
```

## 8. Fuera de QML (web, GTK, terminal, otras apps)

- Lee los colores del estilo activo, no los copies a mano: `~/.local/state/paleshell/hallownest.json`
  da `{style, flavour}` y `assets/hkstyle.py` (`palette()`) devuelve el diccionario fusionado (`void`,
  `shell`, `card`, `button`, `bright`, `text`, `subtext`, `faint`, `outline`, amuletos, `accent`,
  `steel`, …). Así lo hacen `assets/*-theme.py` (Zen, Obsidian, Thunar, zathura/btop, iconos).
- Para que una app nueva siga el tema, añade su script `assets/<app>-theme.py <style> <flavour>` y
  llámalo desde `Hallownest.setTheme`.
- Equivalencias CSS sugeridas:

```css
:root {
  --void: #07090e; --shell: #0e121b; --card: #151a26; --button: #1c2230;
  --text: #e8eef5; --subtext: #9aa6b8; --faint: #546073;
  --soul: #f0f4f8; --steel: #9ba4b5; --border: rgb(155 164 181 / 0.15);
  --lifeblood: #38bdf8; --grimm: #e63946; --gold: #f4a261; --unn: #52b788;
  --radius-card: 14px; --ease-spatial: cubic-bezier(0.2, 1, 0.32, 1); --dur-spatial: 500ms;
}
h1, h2, .section { font-family: "Cinzel", serif; font-weight: 700; letter-spacing: 0.05em; }
body { font-family: "Google Sans Flex", sans-serif; background: var(--shell); color: var(--text); }
```

- Terminal y apps GTK/Qt reciben el esquema de `caelestia` (`assets/schemes/hollowknight/<schemeFlavour>/`),
  generado desde `styles.json` con `python3 scripts/gen-hollowknight-scheme.py`.

## 9. Lista de comprobación

- [ ] Solo un color fuerte en pantalla (`soul`); amuletos solo con significado.
- [ ] Fondos en orden `void_` → `shell` → `card` → `button`, bordes de 1 px en `border`.
- [ ] Títulos en Cinzel, números en mono, iconos Material Rounded.
- [ ] Indicadores en rombo; glow (no sombra) en lo activo.
- [ ] Hover con `Hallownest.raise`, deshabilitado a 0.4, presión a 0.94.
- [ ] Animaciones `Anim.*` sin rebote; color con `CAnim`.
- [ ] Probado en `hallownest`, `pale` (claro) y `void` (mono).
