# Laboratorio Loco

Videojuego 2D de puzles para Godot 4.6. El laboratorio se genera de forma
procedural y la partida admite varios personajes en turnos. Los jugadores
exploran salas, resuelven terminales, puzles de cables y puzles laser, usan
objetos y reparan la plataforma de salida.

## Requisitos

- Godot 4.6 o compatible.
- Proyecto configurado para la plantilla `Mobile`.
- Escena inicial: `Scenes/UI/PantallaInicio.tscn`.

La configuracion principal esta en `project.godot`. El viewport base es
1280x720 y el proyecto usa el renderizador movil.

## Controles

### Movimiento

- Teclado: `W`, `A`, `S`, `D`.
- Movil o raton: cruceta direccional en pantalla.
- El movimiento solo corresponde al personaje activo del turno.
- Los personajes que no tienen el turno permanecen bloqueados.

### Interaccion

- Teclado: `E`, accion `interactuar`.
- Movil o raton: boton contextual de interaccion.
- El boton aparece cuando hay un objeto interactuable cercano.

### Habilidades

- `G`: accion configurada como `golpe_suelo`.
- `H`: accion configurada como `superfuerza`.
- El resto de habilidades se usan desde los botones del inventario.
- Las habilidades tienen recargas y pueden verse afectadas por fusibles,
  cintas y otros objetos de apoyo.

### Interfaces

- `ESC`: cerrar el terminal o el puzle de cables cuando la interfaz lo
  permite.
- Los botones de la interfaz permiten usar, tirar y seleccionar objetos.
- `PASAR TURNO`: termina manualmente el turno actual.

## Flujo de una partida

1. `PantallaInicio` inicia la seleccion de jugadores.
2. Se eligen los personajes y sus datos se guardan en `GameSession`.
3. `Main` crea el laboratorio procedural y muestra la primera sala.
4. `GestorTurnos` asigna el turno y limita el movimiento al jugador activo.
5. El jugador explora, recoge objetos y resuelve los mecanismos de las
   puertas.
6. Las salas guardan su estado: puertas, terminales, puzles, objetos,
   cajas y apagones.
7. La plataforma de salida se completa con las piezas necesarias.
8. Al entrar en el circulo de salida se pide confirmacion.
9. El jugador que sale ve `HAS GANADO`; despues continua el siguiente jugador
   o se muestran los resultados finales.

## Arquitectura

```text
Scenes/
  PantallaInicio.tscn
  Characters/
  Objects/
  Rooms/
  UI/

Scripts/
  Main/         Coordinacion global y turnos
  Laboratory/   Generacion del mapa, puertas y terminales
  Rooms/        Construccion visual y objetos de las salas
  Objects/      Objetos interactuables y mecanicas
  Resources/    Datos persistentes y sesion
  Player/       Punto de entrada del jugador
  UI/           Interfaces y controles
  Audio/        Musica y efectos
```

### Flujo de construccion de una sala

1. `Main.mostrar_sala()` selecciona el `RoomData` de la sala.
2. `RoomBuilder` crea el nodo de sala.
3. `FloorGenerator`, `WallGenerator` y `DoorGenerator` generan la
   estructura.
4. `TerminalGenarator` crea los terminales.
5. `ObjectGenerator` garantiza objetos, puzles, cajas y baterias.
6. `PowerGenerator` crea visualmente baterias, consumibles y puzles.
7. Se reinsertan los personajes que pertenecen a esa sala.
8. Se aplican apagones, vibraciones y estados persistentes.

### Persistencia

`RoomData` contiene el estado de cada sala. `ObjectData` contiene el estado
de cada objeto. Los cambios no dependen de que la sala este visible:

- Las puertas actualizan ambos extremos de la conexion.
- Los terminales conservan energia, pregunta y resolucion.
- Los puzles conservan su solucion y progreso.
- Las cajas guardan su posicion al moverse.
- Los objetos recogidos se marcan para reposicionarse en el siguiente
  cambio de turno o al abandonar la sala.

## Referencia de scripts `.gd`

### `Scenes/Characters`

- `Character.gd`: personaje jugable base. Gestiona movimiento, animaciones,
  habilidades, recargas, empujes, apagones y teletransportes.

### `Scripts/Main`

- `Main.gd`: coordinador principal. Genera el laboratorio, cambia de sala,
  conserva jugadores, aplica apagones, conecta puertas y reconstruye salas.
- `GestorTurnos.gd`: administra jugadores activos, rondas, cuenta atras,
  cambio de turno, bloqueo de personajes, boton de pasar turno y victorias.

### `Scripts/Resources`

- `CatalogoPersonajes.gd`: catalogo de personajes y sus habilidades.
- `CharacterData.gd`: recurso con los datos de un personaje seleccionado.
- `GameSession.gd`: estado global de la partida, jugadores y orden de llegada.
- `HabilidadData.gd`: datos de una habilidad, coste y recarga.
- `LaboratoryData.gd`: contenedor del laboratorio y su lista de salas.
- `ObjectData.gd`: estado persistente de un objeto de sala.
- `RoomData.gd`: dimensiones, conexiones, puertas, terminales, puzles,
  objetos y progreso de una sala.

### `Scripts/Laboratory`

- `Door.gd`: puerta interactuable. Comprueba si se puede atravesar y
  sincroniza el estado abierto/cerrado con la sala opuesta.
- `LaboratoryConector.gd`: conecta salas y sus relaciones de vecindad.
- `LaboratoryGenerator.gd`: crea la topologia procedural del laboratorio.
- `LaboratoryPlacer.gd`: coloca las salas en el mapa logico.
- `LaboratoryRenderer.gd`: representa o depura visualmente la distribucion.
- `LaboratoryTypeGenerator.gd`: asigna tipos y caracteristicas a las salas.
- `TerminalBanco.gd`: banco de preguntas y respuestas de terminales.
- `TerminalGenarator.gd`: crea los terminales de una sala y sus direcciones.

### `Scripts/Rooms`

- `DoorGenerator.gd`: crea las puertas fisicas y sus bloqueos por terminal o
  puzle. Normaliza el estado compartido entre ambos lados.
- `FloorGenerator.gd`: genera el suelo de la sala.
- `ObjectGenerator.gd`: genera decoracion, consumibles, baterias, cajas,
  paneles y componentes laser. Aplica garantias de objetos y reposicion.
- `PowerGenerator.gd`: crea los nodos visuales de objetos interactuables,
  baterias, paneles electricos y puzles laser.
- `RoomBuilder.gd`: coordina la construccion completa de una sala.
- `WallGenerator.gd`: genera paredes, limites y colisiones de la sala.

### `Scripts/Objects`

- `Bateria.gd`: objeto recogible generico. Recoge baterias y consumibles,
  actualiza `ObjectData` y los envia al inventario.
- `ConductoVentilacion.gd`: permite atravesar conductos conectados entre
  salas.
- `InteractableObject.gd`: base para objetos interactuables.
- `InteractionManager.gd`: detecta el objeto cercano del jugador activo y
  muestra el prompt de interaccion.
- `InventoryManager.gd`: inventario, uso y lanzamiento de objetos, recargas
  y reposicion pendiente.
- `LaserMirror.gd`: espejo giratorio del puzle laser.
- `LaserPuzzle.gd`: emisor, espejos, receptor, solucion, persistencia y
  apertura de la puerta laser.
- `MetalBox.gd`: caja metalica empujable por personajes con superfuerza.
- `ObjectBase.gd`: base comun para objetos de sala y superficies.
- `PanelElectrico.gd`: panel del puzle de cables, sobrecarga, vibracion y
  apertura de puertas.
- `ParedDanada.gd`: pared o hueco que permite el paso de personajes con la
  habilidad correspondiente.
- `SalidaOrdenador.gd`: interfaz del ordenador de la plataforma y colocacion
  de piezas de reparacion.
- `SalidaPlataforma.gd`: zona de salida, confirmacion, victoria, resultados
  y creditos finales.
- `Tele.gd`: comportamiento de la television decorativa.
- `Terminal.gd`: terminal de sala. Gestiona energia, preguntas, respuestas,
  apertura de puertas y estado persistente.

### `Scripts/Player`

- `Player.gd`: punto de entrada reservado para la logica general del jugador.
  El comportamiento jugable principal esta en `Scenes/Characters/Character.gd`.

### `Scripts/UI`

- `AjustesUI.gd`: panel de ajustes, audio, pantalla completa y salida.
- `MovementControls.gd`: cruceta tactil y asignacion del jugador activo.
- `PantallaInicio.gd`: pantalla inicial y entrada a la seleccion de partida.
- `PuzzleCables.gd`: interfaz visual del puzle de cables y boton de salida.
- `SeleccionJugadores.gd`: seleccion del numero de jugadores.
- `SeleccionPersonaje.gd`: seleccion y confirmacion de personajes.
- `TerminalInterface.gd`: interfaz de preguntas y respuestas de terminales.
- `TerminalTest.gd`: interfaz auxiliar para probar terminales.
- `TransicionTurno.gd`: pantalla de transicion entre turnos.

### `Scripts/Audio`

- `AudioManager.gd`: musica, efectos, volumen y reproduccion de sonidos.

## Autoloads

Configurados en `project.godot`:

- `CatalogoPersonajes`: catalogo compartido de personajes.
- `GameSession`: datos globales de la partida.
- `GestorAudio`: gestion global del audio.



