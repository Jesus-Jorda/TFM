class_name HabilidadData
extends Resource


# DATOS DE UNA HABILIDAD
# Descripción pura (datos): la lógica real vive en
# Character.usar_habilidad() y la interfaz se genera
# dinámicamente a partir de estos datos.

# Identificador único. Coincide con el caso del match
# en Character.usar_habilidad().
@export var id: String = ""

# Nombre visible bajo el icono / en tooltips.
@export var nombre: String = ""

# Texto del tooltip al pasar el ratón por el icono.
@export var descripcion: String = ""

# Icono mostrado en la interfaz (cambia según personaje).
@export var icono: Texture2D = null

# Segundos de recarga tras usarse (0 = sin recarga).
@export var cooldown: float = 0.0

# Pasiva: solo se muestra como icono informativo,
# no es pulsable ni tiene recarga.
@export var es_pasiva: bool = false

# Activables con confirmación: la primera pulsación
# muestra "pulsa otra vez para confirmar".
@export var requiere_confirmacion: bool = false

# Acción de teclado definida en project.godot que
# dispara la habilidad ("" = sin atajo de teclado).
@export var accion_input: String = ""
