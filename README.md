# Epic Survivor

Prototipo 0.1 de supervivencia fantástica 2D para iOS y Android, desarrollado con Godot 4 y GDScript.

## Estado actual

Primera base de proyecto y escena de movimiento: Aldric provisional, arena de prueba amplia, cámara de seguimiento, joystick táctil y control WASD. El arte y el combate aún no están implementados.

## Plan técnico

Consulta el plan en docs/PLAN_TECNICO_PROTO_01.md para la arquitectura, fases, backlog, dependencias y criterios de aceptación.

## Requisitos

- Godot 4.7.2 estable y plantillas de exportación de la misma versión.
- Xcode en macOS para exportar iOS.
- OpenJDK 17 y Android SDK para exportar Android.

La escena principal es scenes/app/main.tscn. En escritorio se puede mover a Aldric con WASD; en móvil, manteniendo y arrastrando desde la zona inferior izquierda.
