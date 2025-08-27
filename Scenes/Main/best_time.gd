# utils_save.gd (could be put in Main or a small singleton)
func save_best_time(time_sec: float) -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("user://save.cfg")
	# ถ้าไฟล์ไม่มีก็ยัง ok
	cfg.set_value("records", "best_time", time_sec)
	cfg.save("user://save.cfg")

func load_best_time() -> float:
	var cfg := ConfigFile.new()
	if cfg.load("user://save.cfg") == OK:
		var t = cfg.get_value("records", "best_time", -1.0)
		return float(t)
	return -1.0
