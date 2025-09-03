# DialogueUI.gd (Godot 4, typewriter + auto-advance/auto-close)
extends CanvasLayer

@onready var panel: Control = $PanelContainer
@onready var text: RichTextLabel = $PanelContainer/VBoxContainer/Text
@onready var hint: Label = $PanelContainer/VBoxContainer/Hint
@export var ui_font: Font
@export var ui_font_size: int = 24

@export var advance_actions: PackedStringArray = ["ui_accept", "Jump"]
@export var type_speed: float = 0.02         # วินาที/ตัวอักษร; 0 = โชว์ทันที
@export var auto_advance_per_line_sec: float = 0.0   # >0 = หลังพิมพ์จบ "บรรทัด" รอ X วิ แล้วไปบรรทัดถัดไป
@export var auto_close_sec: float = 0.0              # >0 = เมื่อ "บรรทัดสุดท้าย" โชว์ครบ รอ X วิ แล้วปิด

var _lines: PackedStringArray = PackedStringArray()
var _idx: int = 0
var _typing: bool = false
var _cancel_typing: bool = false
var _sched_token: int = 0   # ใช้ยกเลิก schedule เก่า ๆ

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	# กันกรณีธีมทำให้มองไม่เห็นตัวอักษร
	if ui_font:
		# RichTextLabel ใช้คีย์ "normal_font" / "normal_font_size"
		text.add_theme_font_override("normal_font", ui_font)
		text.add_theme_font_size_override("normal_font_size", ui_font_size)
		# Label ใช้คีย์ "font" / "font_size"
		hint.add_theme_font_override("font", ui_font)
		hint.add_theme_font_size_override("font_size", ui_font_size - 2)
	#text.add_theme_color_override("default_color", Color(1,1,1,1))
	#hint.add_theme_color_override("font_color", Color(1,1,1,0.85))
	show()

func start(lines: PackedStringArray) -> void:
	_lines = lines
	if _lines.is_empty():
		queue_free()
		return
	_idx = 0
	_show_line()

func _unhandled_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if event.is_action_pressed("ui_cancel"):
		queue_free()
		return
	for a in advance_actions:
		if event.is_action_pressed(a):
			if _typing:
				# ข้าม typewriter → โชว์ทั้งบรรทัด
				_cancel_typing = true
			else:
				_cancel_schedules()
				_next_or_close()
			return

# ---------- flow ----------
func _show_line() -> void:
	text.text = ""
	_cancel_typing = false
	_cancel_schedules()
	if type_speed <= 0.0:
		text.text = _lines[_idx]
		_typing = false
		_after_line_finished()
	else:
		_typing = true
		_type_line()

func _next_or_close() -> void:
	_idx += 1
	if _idx >= _lines.size():
		queue_free()
	else:
		_show_line()

func _after_line_finished() -> void:
	# ถ้าบรรทัดสุดท้าย
	if _idx == _lines.size() - 1:
		if auto_close_sec > 0.0:
			_schedule_after(auto_close_sec, Callable(self, "_close_if_alive"))
	else:
		# ยังมีบรรทัดต่อไป
		if auto_advance_per_line_sec > 0.0:
			_schedule_after(auto_advance_per_line_sec, Callable(self, "_next_or_close"))

func _close_if_alive() -> void:
	if is_inside_tree():
		queue_free()

# ---------- typewriter (coroutine) ----------
func _type_line() -> void:
	var full: String = _lines[_idx]
	var i: int = 0
	while i <= full.length():
		if _cancel_typing:
			text.text = full
			break
		text.text = full.substr(0, i)
		i += 1
		await get_tree().create_timer(max(type_speed, 0.001)).timeout
	_typing = false
	_after_line_finished()

# ---------- scheduling helpers ----------
func _cancel_schedules() -> void:
	_sched_token += 1

func _schedule_after(seconds: float, callback: Callable) -> void:
	if seconds <= 0.0:
		callback.call()
		return
	_sched_token += 1
	var my_token := _sched_token
	await get_tree().create_timer(seconds).timeout
	# ถ้าถูกยกเลิกไปแล้ว/ยังพิมพ์อยู่/โดนปิดไปก่อน ก็ไม่ต้องเรียก
	if my_token != _sched_token or _typing or not is_inside_tree():
		return
	callback.call()
