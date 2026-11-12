# Epic Survivor — Plan técnico de implementación del prototipo 0.1

**Estado:** primera base de proyecto y escena de movimiento creadas; importación y ejecución en Godot aún no validadas.  
**Fecha de revisión:** 12 de noviembre de 2026. **Base de versiones consultada:** 11 de noviembre de 2026.  
**Objetivo:** convertir el diseño funcional acordado en un prototipo vertical, jugable y exportable para iOS y Android.

**Repositorio destino:** [joanaps92/EpicSurvivor](https://github.com/joanaps92/EpicSurvivor), rama main.

**Progreso:** F0/F1 iniciadas con resolución vertical, renderer Compatibility, arena provisional, cámara, joystick táctil y WASD. Los criterios de aceptación de esas fases siguen pendientes hasta abrir y ejecutar el proyecto en Godot y probarlo en dispositivos.

## 1. Decisiones de diseño que debe respetar la implementación

- Juego de supervivencia 2D cenital, fantasía medieval y pixel art moderno.
- Pantalla vertical; el personaje se mueve con una mano y el combate se resuelve automáticamente.
- Mapas abiertos por chunks procedurales, con semillas reproducibles. La exploración sirve para sobrevivir y posicionarse; el prototipo no necesita misiones ni puntos de interés.
- Enemigos continuos, con eventos de hordas; minijefes a 03:00 y 06:30; jefe final a 10:00.
- La partida se pausa mientras se elige una mejora. El reloj de supervivencia se detiene en 10:00 al entrar en la fase del jefe; el combate final no tiene límite de tiempo.
- Las gemas de experiencia se recogen al acercarse. Subir de nivel presenta tres opciones.
- Curación por provisiones que dejan enemigos y por una mejora de regeneración. La vida no puede superar el máximo.
- Una resurrección como máximo por partida: 50 % de vida máxima y 3 segundos de invulnerabilidad; la siguiente muerte termina la partida.
- Aldric es el único héroe jugable del primer prototipo. Los héroes prediseñados desbloqueables y los datos de región deben poder añadirse sin reescribir el núcleo.
- Las armas y pasivas solo existen dentro de la partida. La persistencia guarda desbloqueos y récords, no una build de combate ni mejoras permanentes de estadísticas.
- Sin backend, cuenta, conexión obligatoria, anuncios ni red cooperativa en 0.1.

### Alcance de contenido recomendado para 0.1

La primera entrega jugable contiene Aldric, la espada larga y el arco corto, cuatro enemigos básicos (trasgo, esqueleto, orco y arquero corrupto), dos patrones de horda reutilizados en los tres eventos de 02:00, 05:00 y 08:00, dos minijefes y el Capitán Caído como jefe final. La región jugable inicial será **Praderas del Ocaso**. El sistema recibe datos de región y combina región con tiempo para configurar enemigos e intensidad; bosque y tierras marchitas quedan como contenido posterior, salvo que el equipo amplíe explícitamente el alcance.

Los valores de balance acordados anteriormente —por ejemplo, provisión con probabilidad inicial del 1 %, curación de 20, regeneración base de 0,5 HP/s, límite técnico de partida de alrededor de 150 enemigos y objetivos de nivel por minuto— son **puntos de partida para pruebas**, no requisitos inamovibles. Todos residirán en recursos de datos editables.

## 2. Base técnica y decisiones de implementación

### Motor y plataformas

- **Godot 4.7.2-stable + GDScript tipado.** A la fecha de referencia, 4.7.2 es la versión estable más reciente y 4.8 está en beta; fijar motor y plantillas de exportación en la misma versión reduce diferencias entre máquinas. No actualizar durante una fase sin revisar el proyecto y reexportar ambas plataformas.
- **Renderizador Compatibility** como punto inicial: es suficiente para este juego 2D y permite probar en el simulador iOS, cuyo soporte documentado se limita a Compatibility. Medir también en dispositivos reales antes de dar por cerrado el rendimiento.
- Escena de juego lógica de **360 × 640**, orientación vertical, filtro de texturas nearest y escala de viewport con expansión controlada. Adaptar HUD y controles a zonas seguras; en pantallas con otra proporción se muestra más mundo, nunca se recorta al jugador ni controles esenciales.
- No usar plugins externos como dependencia obligatoria. Mantener escenas, scripts, recursos personalizados y un pequeño ejecutor de pruebas GDScript dentro del proyecto.

### Reglas de ingeniería

1. La lógica de partida depende de referencias explícitas a RunState, jugador y entidades; evitar que el combate consulte un jugador global. Esto conserva la posibilidad de ampliar el juego sin introducir red en esta versión.
2. Datos de héroes, enemigos, armas, mejoras, regiones y eventos viven en recursos .tres; el código ejecuta reglas, no almacena curvas de balance como números dispersos.
3. Las señales comunican cambios de estado (daño, muerte, subida de nivel, jefe, victoria); los sistemas no deben conocer nodos de UI concretos.
4. El reloj de partida avanza solo durante el juego activo. Se congela al pausar, al elegir mejoras y en menús. En fase de jefe, mostrar 10:00 + tiempo de jefe.
5. Mantener las interacciones físicas simples: colisión real para jugador/obstáculos importantes; movimiento de enemigos dirigido al jugador y desvío ligero. No ejecutar navegación global por cada enemigo.
6. Semilla y coordenadas de chunk son suficientes para regenerar terreno. No guardar el mundo completo ni simular regiones lejanas.
7. El pooling se añade donde el perfil lo justifique, empezando por proyectiles, impactos, gemas y enemigos de alta rotación.

## 3. Arquitectura

~~~mermaid
flowchart TD
    APP[App / menú] --> FLOW[GameFlow]
    FLOW --> RUN[RunScene / GameSession]
    RUN --> STATE[RunState: reloj, semilla, región, fase]
    RUN --> PLAYER[Player: movimiento, vida, AutoCombat]
    PLAYER --> WEAPONS[Weapon components]
    WEAPONS --> REGISTRY[EnemyRegistry / objetivos]
    REGISTRY --> ENEMIES[Enemy scenes + HealthComponent]
    ENEMIES --> DROPS[XP, provisiones, cofres]
    DROPS --> PROG[ExperienceSystem / UpgradeManager]
    STATE --> WORLD[ChunkManager + RegionData]
    STATE --> TIMELINE[WaveTimeline + DifficultyScaler]
    TIMELINE --> SPAWNER[SpawnDirector]
    SPAWNER --> ENEMIES
    PLAYER --> SURVIVAL[HealthComponent / ReviveManager]
    RUN --> HUD[HUD / pantallas de nivel, pausa y fin]
    FLOW --> SAVE[SaveManager]
~~~

### Módulos y responsabilidades

| Módulo | Responsabilidad y límite |
|---|---|
| GameFlow (autoload) | Transición entre menú, partida y resultado. No contiene reglas de combate. |
| SaveManager (autoload) | Leer/escribir progreso local versionado, validar valores y migrar versiones compatibles. No guarda el estado temporal de combate. |
| GameSession / RunState | Estado de una expedición: héroe, región, semilla, reloj, fase, nivel, inventario de partida y banderas de resurrección/victoria. |
| PlayerController | Entrada táctil, movimiento y orientación visual. No lanza ataques manuales. |
| AutoCombat y componentes de arma | Cadencia, objetivo y patrón por arma. El jugador no sabe cómo dispara cada arma. |
| EnemyRegistry | Alta/baja de enemigos y consulta de candidatos de ataque. Empezar con índice sencillo; añadir partición espacial solo si el perfil de la escena completa lo requiere. |
| HealthComponent | Daño, curación acotada, armadura, invulnerabilidad y señal de muerte. Reutilizable por jugador y enemigos. |
| ExperienceSystem / UpgradeManager | Recogida de gemas, XP, umbrales, oferta de tres mejoras válidas y aplicación de efectos a la build de la partida. |
| ChunkManager | Crear y liberar chunks cercanos a la cámara a partir de región, semilla y coordenadas. |
| WaveTimeline / DifficultyScaler / SpawnDirector | Eventos por tiempo, intensidad por tiempo+región, límites de aparición y selección ponderada de enemigos. |
| ReviveManager | Oferta y consumo único de resurrección. No controla la persistencia permanente. |
| UI | Vistas que escuchan señales y solicitan acciones al flujo de juego; no contienen reglas de dificultad. |

### Recursos de datos previstos

- HeroData: id, nombre, escena/arte, vida, velocidad, arma inicial, rasgo y condiciones de desbloqueo.
- EnemyData: id, escena, vida, daño, velocidad, XP, peso de aparición y regla de botín.
- WeaponData: cadencia, daño, alcance, patrón, máximo de nivel y escena de proyectil/efecto.
- UpgradeData: id, grupo (arma/pasiva), máximos, magnitud por nivel, prerequisitos y efecto.
- RegionData: id, paleta/tileset, conjunto de chunks, enemigos ponderados, jefe y parámetros de dificultad.
- WaveEventData: inicio, duración, multiplicador de aparición, pool de enemigos y reglas de fin.
- RunConfig: límites técnicos y parámetros globales de balance para una versión del prototipo.

## 4. Estructura de carpetas

~~~text
EpicSurvivor/
├── project.godot
├── export_presets.cfg                 # sin secretos ni claves de firma
├── README.md
├── .gitignore                         # excluye .godot/, builds y credenciales
├── assets/
│   ├── art/{characters,enemies,tilesets,fx,ui}/
│   ├── audio/{music,sfx}/
│   └── fonts/
├── scenes/
│   ├── app/{main_menu,hero_select,region_select,results}/
│   ├── run/{run,level_up,revive,pause}/
│   ├── player/
│   ├── enemies/{normal,miniboss,boss}/
│   ├── weapons/{melee,projectiles,effects}/
│   ├── world/{chunks,props}/
│   └── ui/{hud,components}/
├── scripts/
│   ├── app/
│   ├── run/
│   ├── entities/{player,enemies}/
│   ├── combat/
│   ├── spawning/
│   ├── progression/
│   ├── procedural/
│   ├── persistence/
│   └── ui/
├── data/
│   ├── heroes/
│   ├── enemies/
│   ├── weapons/
│   ├── upgrades/
│   ├── regions/
│   └── waves/
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── fixtures/
│   └── run_headless.gd
└── docs/
    ├── PLAN_TECNICO_PROTO_01.md
    └── balance/
~~~

El plan se guarda en docs/PLAN_TECNICO_PROTO_01.md en la raíz del repositorio EpicSurvivor.

## 5. Dependencias

### Dependencias del juego

| Dependencia | Necesidad | Decisión para 0.1 |
|---|---|---|
| Godot Engine | Editor, runtime y exportador | 4.7.2 estable, fijado por el equipo. |
| Plantillas de exportación Godot | Generar binarios de plataforma | Instalar la versión que corresponda exactamente al motor fijado. |
| Add-ons de terceros | No requeridos | No introducirlos salvo necesidad probada y decisión registrada. |
| Backend/servicios online | No requeridos | Ninguno para la partida ni el guardado. |

### Herramientas de exportación

- **Android:** macOS, Windows o Linux con OpenJDK 17 y Android SDK configurados en Godot. La guía estable consultada indica platform-tools 35+, Build Tools 35.0.1, Platform 35, NDK 28.1.13356709 y CMake 3.10.2.4988404. Son valores de referencia publicados por la guía el 11-11-2026; confirmar los requisitos vigentes de Godot y el nivel API de Google Play justo antes de generar un paquete. Para pruebas internas se acepta APK; preparar AAB/Gradle cuando se acuerde distribución en tienda.
- **iOS:** macOS con Xcode instalado y abierto al menos una vez, plantilla de exportación Godot de la misma versión, identificador de paquete único y cuenta/certificado de Apple para instalar en dispositivos. El equipo de desarrollo necesita acceso a un iPhone para validar entrada táctil, zonas seguras y rendimiento; el simulador no sustituye esa comprobación.
- No guardar contraseñas, keystores, perfiles de aprovisionamiento ni claves de Apple en Git. Usar configuración local del equipo o secretos del sistema de CI si se incorpora CI más adelante.

## 6. Backlog por fases

Orden sugerido. Las fases 3 y 4 pueden avanzar después de que movimiento y combate básicos estén estables, pero la integración completa de oleadas requiere ambas.

| Fase | Versión interna | Backlog y dependencias | Entrega |
|---|---|---|---|
| **F0 — Base y decisión de dispositivos** | 0.0.1-pre | SET-01 crear proyecto y Git; SET-02 fijar Godot/plantillas; SET-03 configurar orientación, resolución, renderer y export presets; SET-04 designar un Android y un iPhone de referencia, incluyendo versión mínima del SO; SET-05 acordar perfil de rendimiento y controles de aceptación. Sin dependencias. | Proyecto abre, importa y arranca en editor; ruta de exportación de ambos sistemas documentada. |
| **F1 — Movimiento y pantalla vertical** | 0.0.1 | MOV-01 joystick flotante táctil; MOV-02 movimiento analógico y límites de velocidad; CAM-01 cámara cenital suavizada; UI-01 HUD temporal y áreas seguras; WORLD-01 arena estática de prueba; INPUT-01 reanudar al volver de segundo plano. Depende de F0. | Aldric se mueve con un dedo en pantalla vertical y también con entrada simulada en editor. |
| **F2 — Combate automático** | 0.0.2 | COM-01 HealthComponent; COM-02 ataque de espada automática hacia objetivo elegible; COM-03 arco corto como arma adquirible; EN-01 cuatro enemigos y muerte/daño; EN-02 navegación simple sin atascar al jugador; PERF-01 profiler básico y escenario de estrés; POOL-01 pooling solo para objetos de alta rotación si el perfil lo aconseja. Depende de F1. | El jugador causa y recibe daño sin botón de ataque; objetivos, cadencias y daño provienen de datos. |
| **F3 — XP y build de partida** | 0.0.3 | XP-01 gemas de 1/5/20 XP y recogida por proximidad; XP-02 curva configurable; UPG-01 tres ofertas válidas por subida; UPG-02 dos armas y diez pasivas del catálogo inicial; UPG-03 límites de cuatro armas y cuatro pasivas; UI-02 selección pausa/resume; CHEST-01 recompensa simple de minijefes preparada. Depende de F2. | Una partida permite acumular XP y mejorar armas/pasivas; no persiste la build al acabar. |
| **F4 — Mundo procedural por chunks** | 0.0.4 | PROC-01 RegionData y semilla; PROC-02 generación determinista por coordenada de chunk; PROC-03 creación/liberación alrededor del jugador; PROC-04 suelo, decoración y obstáculos de Praderas del Ocaso; PROC-05 reglas que impiden encerrar al jugador y mantienen rutas de salida; PROC-06 puntos de aparición fuera de la zona inmediata de cámara. Depende de F1; para validar combate completo, F2. | Misma semilla + región produce el mismo layout; moverse no acumula chunks fuera del radio activo. |
| **F5 — Ritmo, dificultad y jefes** | 0.0.5 | TIME-01 reloj de partida y máquina de estados; WAVE-01 aparición continua con cap; WAVE-02 hordas de 20 s a 02:00, 05:00 y 08:00; DIFF-01 modificadores combinados de tiempo+región; BOSS-01 minijefe 03:00 y 06:30 con ataques telegrafiados; BOSS-02 Capitán Caído desde 10:00; BOSS-03 detener oleadas normales y negar XP a invocaciones; UI-03 anuncios de evento y tiempo adicional del jefe. Depende de F2, F3 y F4. | Se puede jugar la secuencia completa; el jefe no desaparece por tiempo y se derrota o la partida acaba al morir. |
| **F6 — Curación, resurrección y guardado** | 0.0.6 | SUR-01 provisión automática al recoger; SUR-02 regeneración configurable; SUR-03 una resurrección con 50 % HP/3 s invulnerable; FLOW-01 victoria, derrota, pausa y reintento; SAVE-01 esquema local versionado para récords/desbloqueos; SAVE-02 escritura segura y valores corruptos tolerados; UNLOCK-01 datos de desbloqueo sin asignar recompensas permanentes de estadísticas. Depende de F3 y F5. | Ciclo completo de partida; progreso sobrevive al cierre y no conserva equipo temporal. |
| **F7 — Ajuste y builds móviles** | 0.1.0 | MOB-01 pruebas en los dispositivos de F0; MOB-02 safe areas, interrupciones, suspensión y reanudación; PERF-02 medir partida con cap de enemigos, proyectiles y gemas; ART-01 legibilidad de pixel art/HUD; AUDIO-01 feedback mínimo; EXP-01 exportar e instalar Android; EXP-02 exportar, firmar e instalar iOS; BAL-01 registrar curvas y ajustar recursos; DOC-01 README, créditos/licencias y pasos para repetir builds. Depende de F1–F6. | Versión de prueba instalada en un teléfono Android y un iPhone; partida completa validada en cada plataforma. |

### Grafo de dependencias

~~~mermaid
flowchart LR
    F0 --> F1
    F1 --> F2
    F1 --> F4
    F2 --> F3
    F2 --> F5
    F3 --> F5
    F4 --> F5
    F3 --> F6
    F5 --> F6
    F1 --> F7
    F2 --> F7
    F3 --> F7
    F4 --> F7
    F5 --> F7
    F6 --> F7
~~~

## 7. Criterios de aceptación

### Por fase

**F0 — Base**

- La versión de editor y las plantillas instaladas coinciden con la decisión fijada.
- El proyecto arranca en orientación vertical y no muestra errores de importación.
- Se registran modelo/OS de los dispositivos de referencia, renderer y objetivo de fotogramas.

**F1 — Movimiento**

- El joystick inicia donde toca el usuario, responde a arrastre continuo y se cancela al levantar el dedo o perder foco.
- La velocidad diagonal no supera la velocidad cardinal.
- El joystick y el HUD no invaden la isla dinámica/notch ni el indicador de inicio; la cámara conserva a Aldric dentro del área jugable.
- Al regresar de una interrupción, el juego no sigue acumulando tiempo ni movimiento de fondo.

**F2 — Combate**

- Sin tocar botones de ataque, espada y arco disparan según su configuración y dañan solo objetivos válidos.
- Daño, vida y velocidad de los cuatro enemigos se leen desde recursos.
- Cada enemigo muere una sola vez, emite sus drops una sola vez y se elimina/libera correctamente.
- Los impactos aplican una única instancia de daño por ataque y respetan invulnerabilidad/armadura configuradas.

**F3 — Progresión**

- Gemas cercanas se recogen; ampliar el radio con magnetismo cambia el área de recogida y no duplica XP.
- La subida consume el umbral requerido y pausa el combate hasta confirmar una opción.
- Las tres opciones son distintas y aplicables; no se ofrecen mejoras máximas, armas duplicadas ni slots imposibles de aceptar.
- La progresión se reinicia al iniciar una nueva partida y el equipo no se escribe en el guardado permanente.

**F4 — Procedural**

- Dos ejecuciones con la misma región y semilla generan la misma configuración de chunks y props.
- Otra semilla genera una distribución distinta sin atravesar reglas de transitabilidad.
- El jugador siempre puede abandonar cada chunk y no aparece atrapado por obstáculos.
- Los chunks fuera del radio activo se liberan; la memoria/árbol de escena no crece con distancia recorrida.

**F5 — Oleadas y jefes**

- Reloj de juego: eventos en 02:00, 03:00, 05:00, 06:30, 08:00 y 10:00, con variación máxima de un segundo bajo pausa normal.
- El cap provisional de enemigos activos evita sobrepasar el límite configurado; si se alcanza, se difieren apariciones sin borrar enemigos cerca del jugador.
- A 02:00/05:00/08:00 empieza el evento de horda configurado; al llegar a 10:00 cesan las apariciones normales y aparece el jefe.
- El tiempo de supervivencia queda fijado en 10:00; el tiempo extra del jefe sí avanza y nunca provoca derrota automática.
- Las invocaciones del jefe no dan XP; vencer al jefe produce victoria y la muerte definitiva produce derrota.
- DifficultyScaler produce valores reproducibles según tiempo y región; dos recursos de región de prueba pueden mostrar distinta presión sin ramificar lógica de combate.

**F6 — Supervivencia y persistencia**

- Las provisiones se consumen al recogerlas, curan la cantidad configurada y nunca exceden vida máxima.
- La regeneración comienza y se acumula según el valor del recurso; se detiene/continúa según las reglas de pausa.
- Solo se ofrece una resurrección; aceptarla conserva build y nivel, restaura 50 % de vida y concede 3 s de invulnerabilidad.
- Rechazarla o morir después de usarla termina la partida.
- Tras cerrar/reabrir, los desbloqueos y récords se mantienen; una build de partida no aparece en el siguiente intento.
- Un archivo de guardado ausente o inválido inicia valores seguros y no bloquea la partida.

**F7 — Prototipo 0.1**

- Una sesión completa, desde selección hasta victoria/derrota, funciona en al menos un teléfono Android y un iPhone de referencia.
- Se ejecutan 10 minutos de supervivencia y se permite que el jefe permanezca indefinidamente, sin que el reloj fuerce un cierre.
- Se registra rendimiento en el escenario de carga acordado en F0. Objetivo inicial: 60 FPS; cualquier excepción en dispositivos mínimos debe quedar medida y decidirse antes de marcar la fase como aceptada.
- No hay cierres inesperados, bloqueo del input, pantalla ilegible ni pérdida de guardado en los recorridos de aceptación.
- El paquete de entrega incluye builds identificadas, versión de Godot, pasos de instalación, registro de dispositivos probados y limitaciones conocidas.

### Objetivos de balance que deben quedar registrados

Los siguientes valores son una guía de playtest, no bloquean el trabajo técnico hasta ser ratificados con partidas reales:

| Tiempo de partida | Nivel orientativo |
|---:|---:|
| 01:00 | 3–4 |
| 03:00 | 7–9 |
| 05:00 | 11–13 |
| 08:00 | 16–19 |
| 10:00 | 20–23 |

### Parámetros iniciales para los recursos de balance

Estos valores vienen del diseño funcional y sirven para crear los primeros recursos .tres; deben quedar editables y calibrarse con partidas:

| Enemigo | Vida | Daño | Velocidad (px/s) | XP |
|---|---:|---:|---:|---:|
| Trasgo | 18 | 5 | 95 | 1 |
| Esqueleto | 30 | 8 | 70 | 2 |
| Arquero corrupto | 22 | 6 | 60 | 2 |
| Orco | 90 | 15 | 45 | 5 |

- Escalado inicial de vida: HP(t) = HP base × (1 + 0,045 × minutos).
- XP para el siguiente nivel: 8 + 4L + floor(0,35 × L²), siendo L el nivel actual.
- Hordas: 20 segundos; estampida de trasgos y marcha de los muertos.
- Vida inicial de referencia: orco campeón 500, caballero espectral 950 y Capitán Caído 2.500.
- Curación inicial por provisión: probabilidad 1 % por enemigo normal y 20 HP; regeneración inicial 0,5 HP/s.
- Resurrección: una por partida, 50 % de vida máxima y 3 segundos de invulnerabilidad.

Registrar por semilla: nivel alcanzado por minuto, daño recibido/causado, enemigos creados y activos, XP recogida, mejoras elegidas, duración de minijefes/jefe, uso de resurrección y FPS. El modo de simulación sin gráficos es una mejora opcional posterior; 0.1 puede registrar telemetría local de partidas normales.

## 8. Guardado, calidad y entrega

- El guardado local usa un schema_version y campos permitidos explícitos. Una migración futura debe conservar solo campos conocidos y aplicar valores iniciales si falla.
- Los criterios anteriores se comprobarán mediante pruebas de GDScript sin framework externo, recorridos manuales en editor y pruebas en dispositivos. No se requiere montar CI en la primera vertical slice; se recomienda incorporar validación headless del proyecto cuando haya un repositorio y una máquina de integración.
- Cada fase debe dejar una escena ejecutable o un build demostrable. No declarar validado en dispositivo algo que solo se haya importado/exportado desde el editor.
- El cierre de 0.1 requiere builds de prueba para iOS y Android; no implica publicación en App Store ni Google Play.

## 9. Fuera de alcance y riesgos a vigilar

- Contenido jugable completo de Lyra, Borin, Eldrin y regiones 2/3; el modelo de datos queda preparado.
- Cooperativo online, backend, sincronización, cuentas, anuncios, compras y tablas globales.
- Misiones, inventario persistente, equipo entre partidas y mejoras permanentes de estadísticas.
- Enemigos o chunks ilimitados en memoria, generación de mundo remoto persistente, navegación compleja y destrucción de terreno.
- Riesgos principales: pixel art en proporciones distintas, densidad de enemigos en móviles modestos, exportación iOS dependiente de macOS/Xcode/firma, y balance conjunto de XP/oleadas. Tratar cada riesgo con pruebas tempranas y ajustar recursos, no dispersar constantes en scripts.

## 10. Fuentes técnicas consultadas

- [Archivo oficial de versiones de Godot](https://godotengine.org/download/archive/) — estado de Godot 4.7.2 estable y Godot 4.8 beta, consultado el 11-11-2026.
- [Exportación para Android — documentación estable](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) — JDK/SDK y paquetes enumerados por Godot.
- [Exportación para iOS — documentación estable](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html) — macOS/Xcode, plantillas, Bundle ID y renderer del simulador.
- [Resoluciones múltiples — documentación estable](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html) — resolución base y opciones de escala para relaciones de aspecto diferentes.
