extends Node3D

@export var pivot_path: NodePath = ^"Pivot"
@export var camera_path: NodePath = ^"Pivot/Camera3D"

# ---- Framing ----
@export var start_yaw_deg: float = 45.0
@export var start_pitch_deg: float = 35.0
@export var start_distance: float = 18.0
@export var min_pitch_deg: float = 15.0
@export var max_pitch_deg: float = 65.0
@export var min_distance: float = 6.0
@export var max_distance: float = 60.0

# ---- Bounds on ground (x/z) ----
@export var bounds := Rect2(Vector2(-20, -20), Vector2(40, 40))

# ---- Feel / speeds ----
@export var orbit_sensitivity := 0.25      # deg/px
@export var base_pan_per_px := 0.0015      # world units/px (before scaling)
@export var pan_zoom_scale := 0.06         # zoom influence on pan speed
@export var key_pan_speed := 8.0           # WASD units/sec
@export var rotate_keys_speed := 60.0
@export var zoom_step := 1.1
@export var pinch_zoom_speed := 0.08
@export var damp := 12.0

# Modifiers
@export var slow_mult := 0.4               # Shift
@export var fast_mult := 2.0               # Alt

# ---- Auto spin (demo) ----
@export var auto_spin_on_start := true
@export var auto_spin_speed_deg := 10.0    # deg/sec
@export var input_grace_sec := 0.5         # ignore early startup noise
var _auto_spin_enabled: bool = true
var _start_time_s: float = 0.0

# ---- Internals ----
var _pivot: Node3D
var _cam: Camera3D
var _yaw: float = 0.0
var _pitch: float = 0.0
var _distance: float = 10.0
var _vel_pan := Vector3.ZERO

func _ready() -> void:
	_pivot = get_node(pivot_path)
	_cam = get_node(camera_path)
	# Initial framing
	_yaw = start_yaw_deg
	_pitch = clampf(start_pitch_deg, min_pitch_deg, max_pitch_deg)
	_distance = clampf(start_distance, min_distance, max_distance)
	_cam.current = true
	_start_time_s = Time.get_ticks_msec() * 0.001
	_apply_transforms(true)

func _process(delta: float) -> void:
	# Auto spin at start; stop forever on first user input
	if auto_spin_on_start and _auto_spin_enabled:
		_yaw += auto_spin_speed_deg * delta

	# Keyboard pan
	var v2 := Vector2.ZERO
	if Input.is_action_pressed("cam_left"):    v2.x -= 1.0
	if Input.is_action_pressed("cam_right"):   v2.x += 1.0
	if Input.is_action_pressed("cam_forward"): v2.y -= 1.0
	if Input.is_action_pressed("cam_back"):    v2.y += 1.0
	if v2 != Vector2.ZERO:
		v2 = v2.normalized()
		var right := _pivot.basis.x
		var fwd := -_pivot.basis.z
		_vel_pan += (right * v2.x + fwd * v2.y) * key_pan_speed * delta

	# Keyboard rotate
	if Input.is_action_pressed("cam_ccw"): _yaw -= rotate_keys_speed * delta
	if Input.is_action_pressed("cam_cw"):  _yaw += rotate_keys_speed * delta

	# Apply smoothed pan
	if _vel_pan.length() > 0.00001:
		var p := global_transform.origin
		p += _vel_pan
		p.y = 0.0
		p.x = clampf(p.x, bounds.position.x, bounds.position.x + bounds.size.x)
		p.z = clampf(p.z, bounds.position.y, bounds.position.y + bounds.size.y)
		global_transform.origin = p
		_vel_pan = _vel_pan.lerp(Vector3.ZERO, 1.0 - exp(-damp * delta))
	else:
		_vel_pan = Vector3.ZERO

	_apply_transforms(false)

func _unhandled_input(event: InputEvent) -> void:
	# Stop auto-spin permanently after real input (with startup grace)
	if _auto_spin_enabled and auto_spin_on_start:
		var now_s := Time.get_ticks_msec() * 0.001
		if (now_s - _start_time_s) >= input_grace_sec:
			if (event is InputEventMouseButton and event.pressed) \
			or (event is InputEventMouseMotion and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE))) \
			or (event is InputEventMagnifyGesture) \
			or (event is InputEventPanGesture) \
			or (event is InputEventKey and event.pressed):
				_auto_spin_enabled = false

	# Zoom (wheel)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = clampf(_distance / zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = clampf(_distance * zoom_step, min_distance, max_distance)

	# Mouse orbit / pan
	if event is InputEventMouseMotion:
		var d: Vector2 = event.relative
		if Input.is_action_pressed("cam_orbit"):
			_yaw -= d.x * orbit_sensitivity
			_pitch = clampf(_pitch + d.y * orbit_sensitivity, min_pitch_deg, max_pitch_deg)
		elif Input.is_action_pressed("cam_pan"):
			_queue_pan_pixels(d)

	# Pinch zoom (trackpad / iOS)
	if event is InputEventMagnifyGesture:
		var f: float = 1.0 - (event.factor - 1.0) * pinch_zoom_speed
		_distance = clampf(_distance * f, min_distance, max_distance)

	# Two-finger pan (trackpad / iOS)
	if event is InputEventPanGesture:
		var d2: Vector2 = event.delta * 0.6
		_queue_pan_pixels(d2)

func _queue_pan_pixels(pixel_delta: Vector2) -> void:
	var right: Vector3 = _pivot.basis.x.normalized()
	var fwd: Vector3   = -_pivot.basis.z.normalized()

	var zoom_factor : float = 1.0 + ((_distance - min_distance) / max(0.001, (max_distance - min_distance))) * pan_zoom_scale
	zoom_factor = clampf(zoom_factor, 0.5, 2.0)

	var mult := 1.0
	if Input.is_key_pressed(KEY_SHIFT): mult *= slow_mult
	if Input.is_key_pressed(KEY_ALT):   mult *= fast_mult

	var world_per_px := base_pan_per_px * zoom_factor * mult
	var move: Vector3 = (-right * pixel_delta.x + -fwd * pixel_delta.y) * world_per_px
	_vel_pan += move * _distance

func _apply_transforms(_force: bool) -> void:
	_pivot.rotation_degrees = Vector3(_pitch, _yaw, 0.0)
	var back := -_pivot.transform.basis.z.normalized()
	var up := _pivot.transform.basis.y.normalized()
	var cam_pos := _pivot.global_transform.origin + back * _distance + up * (_distance * 0.05)
	_cam.global_transform.origin = cam_pos
	_cam.look_at(_pivot.global_transform.origin, Vector3.UP)
