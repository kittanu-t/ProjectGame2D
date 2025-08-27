@onready var goal_area: Area2D = $goal
#@onready var player: CharacterBody2D = $Player
var elapsed_time: float = 0.0
var timer_running: bool = false

func _ready() -> void:
	# ... existing spawn logic ...
	goal_area.body_entered.connect(Callable(self, "_on_goal_entered"))

func start_game_timer() -> void:
	elapsed_time = 0.0
	timer_running = true

func stop_game_timer() -> void:
	timer_running = false

func _process(delta: float) -> void:
	if timer_running:
		elapsed_time += delta

func _on_goal_entered(body: Node) -> void:
	if body == player and timer_running:
		stop_game_timer()
		# เปรียบเทียบและบันทึก best time
		var best := load_best_time() # ฟังก์ชันจากตัวอย่างด้านบน
		if best < 0 or elapsed_time < best:
			save_best_time(elapsed_time)
		# เปลี่ยนไป Finish scene และส่ง elapsed_time เพื่อแสดง
		get_tree().change_scene_to_file("res://Scenes/Main/finish.tscn")
		# หรือใช้ autoload / singleton เพื่อส่งผลลัพธ์ ให้ Finish ดึงค่า elapsed_time หรืออ่านจาก save ไฟล์
