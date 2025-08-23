extends Node3D
##
## CameraRig with mobile gestures (Godot 4.x)
## Node structure:
##   CameraRig (this script)
##     └── Pivot (Node3D)
##          └── Camera3D
##

@export var pivot_path: NodePath = ^"Pivot"
@export var camera_path: NodePath = ^"Pivot/Camera3D"

# --- Framing ---
@export var start_yaw_deg: float = 45.0
@export var start_pitch_deg: float = 35.0
@export var start_distance: float = 18.0
@export var min_pitch_deg: float = 15.0
@export var max_pitch_deg: float = 65.0
@export var min_distance: float = 6.0
@export var max_distance: float = 60.0

# --- Bounds on ground (x/z) ---
@export var bounds := Rect2(Vector2(-20, -20), Vector2(40, 40))

# --- Desktop feel ---
@export var orbit_sensitivity := 0.25    # deg per px (mouse)
@export var base_pan_per_px := 0.0015
@export var pan_zoom_scale := 0.06
@export var key_pan_speed := 8.0
@export var rotate_keys_speed := 60.0
@export var zoom_step := 1.1
@export var damp := 12.0
@export var slow_mult := 0.4   # Shift
@export var fast_mult := 2.0   # Alt

# --- Mobile feel ---
@export var touch_orbit_sens := 0.16     # deg per px (1 finger)
@export var touch_pan_per_px := 0.0012   # world per px (2 fingers)
@export var pinch_zoom_speed := 0.08     # gesture factor

# --- Optional demo auto-spin (stops on first user input) ---
@export var auto_spin_on_start := false
@export var auto_spin_speed_deg := 8.0
@export var input_grace_sec := 0.5

var _pivot: Node3D
var _cam: Camera3D
var _yaw := 0.0
var _pitch := 0.0
var _distance := 10.0
var _vel_pan := Vector3.ZERO
var _auto_spin_enabled := true
var _start_time_s := 0.0

# touch state
var _touches := {}            # index -> Vector2 position
var _last_two_mid := Vector2.ZERO
var _last_two_dist := 0.0

func _ready() -> void:
	_pivot = get_node(pivot_path)
	_cam = get_node(camera_path)
	_yaw = start_yaw_deg
	_pitch = clampf(start_pitch_deg, min_pitch_deg, max_pitch_deg)
	_distance = clampf(start_distance, min_distance, max_distance)
	_cam.current = true
	_start_time_s = Time.get_ticks_msec() * 0.001
	_apply_transforms(true)

func _process(delta: float) -> void:
	# Auto spin (optional)
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
	# Stop auto-spin on first real input (after a small grace)
	if _auto_spin_enabled and auto_spin_on_start:
		var now_s := Time.get_ticks_msec() * 0.001
		if (now_s - _start_time_s) >= input_grace_sec:
			if event.is_pressed() or event is InputEventMouseMotion \
			or event is InputEventPanGesture or event is InputEventMagnifyGesture \
			or event is InputEventScreenTouch or event is InputEventScreenDrag:
				_auto_spin_enabled = false

	# -------- Desktop mouse ----------
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = clampf(_distance / zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = clampf(_distance * zoom_step, min_distance, max_distance)

	if event is InputEventMouseMotion:
		var d: Vector2 = event.relative
		if Input.is_action_pressed("cam_orbit"):
			_yaw -= d.x * orbit_sensitivity
			_pitch = clampf(_pitch + d.y * orbit_sensitivity, min_pitch_deg, max_pitch_deg)
		elif Input.is_action_pressed("cam_pan"):
			_queue_pan_pixels(d)

	# -------- Trackpad / mobile gestures (native) ----------
	if event is InputEventMagnifyGesture:
		var f: float = 1.0 - (event.factor - 1.0) * pinch_zoom_speed
		_distance = clampf(_distance * f, min_distance, max_distance)
	if event is InputEventPanGesture:
		var d2: Vector2 = event.delta * 0.6
		_queue_pan_pixels(d2)

	# -------- Raw touch fallback (Android & some browsers) ----------
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
			_reset_two_finger_refs()
	if event is InputEventScreenDrag:
		_touches[event.index] = event.position
		var count := _touches.size()

		if count == 1:
			# One-finger orbit
			var d: Vector2 = event.relative
			_yaw -= d.x * touch_orbit_sens
			_pitch = clampf(_pitch + d.y * touch_orbit_sens, min_pitch_deg, max_pitch_deg)

		elif count >= 2:
			# Two-finger pan + pinch zoom (approx)
			var a : Vector2 = _touches.values()[0]
			var b : Vector2 = _touches.values()[1]
			var mid := (a + b) * 0.5
			var dist := a.distance_to(b)

			if _last_two_mid != Vector2.ZERO:
				var move_px := mid - _last_two_mid
				_touch_pan_pixels(move_px)
			if _last_two_dist > 0.0:
				var delta_dist := dist - _last_two_dist
				var f: float = 1.0 - (delta_dist / 300.0) * pinch_zoom_speed  # 300px ≈ comfortable pinch unit
				_distance = clampf(_distance * f, min_distance, max_distance)

			_last_two_mid = mid
			_last_two_dist = dist

# ---- helpers ----
func _reset_two_finger_refs() -> void:
	_last_two_mid = Vector2.ZERO
	_last_two_dist = 0.0

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

func _touch_pan_pixels(pixel_delta: Vector2) -> void:
	# separate sensitivity for touch
	var right: Vector3 = _pivot.basis.x.normalized()
	var fwd: Vector3   = -_pivot.basis.z.normalized()
	var move: Vector3 = (-right * pixel_delta.x + -fwd * pixel_delta.y) * touch_pan_per_px * _distance
	_vel_pan += move

func _apply_transforms(_force: bool) -> void:
	_pivot.rotation_degrees = Vector3(_pitch, _yaw, 0.0)
	var back := -_pivot.transform.basis.z.normalized()
	var up := _pivot.transform.basis.y.normalized()
	var cam_pos := _pivot.global_transform.origin + back * _distance + up * (_distance * 0.05)
	_cam.global_transform.origin = cam_pos
	_cam.look_at(_pivot.global_transform.origin, Vector3.UP)
