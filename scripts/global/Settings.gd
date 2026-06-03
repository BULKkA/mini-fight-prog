# Settings.gd
extends Node

signal settings_loaded
signal settings_saved
signal setting_changed(setting_name, value)

const SETTINGS_FILE := "user://settings.cfg"

# =========================
# НАСТРОЙКИ
# =========================

var music_volume: float = 1.0
var sfx_volume: float = 1.0

var fullscreen: bool = false
var vsync: bool = true

var resolution: Vector2i = Vector2i(1920, 1080)

# =========================
# ИНИЦИАЛИЗАЦИЯ
# =========================

func _ready() -> void:
	load_settings()

# =========================
# СОХРАНЕНИЕ / ЗАГРУЗКА
# =========================

func save_settings() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "sfx_volume", sfx_volume)

	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)

	cfg.set_value("video", "width", resolution.x)
	cfg.set_value("video", "height", resolution.y)

	cfg.save(SETTINGS_FILE)

	settings_saved.emit()


func load_settings() -> void:
	var cfg := ConfigFile.new()

	if cfg.load(SETTINGS_FILE) != OK:
		apply_settings()
		save_settings()
		return

	music_volume = cfg.get_value("audio", "music_volume", 1.0)
	sfx_volume = cfg.get_value("audio", "sfx_volume", 1.0)

	fullscreen = cfg.get_value("video", "fullscreen", false)
	vsync = cfg.get_value("video", "vsync", true)

	var width = cfg.get_value("video", "width", 1920)
	var height = cfg.get_value("video", "height", 1080)

	resolution = Vector2i(width, height)

	apply_settings()

	settings_loaded.emit()

# =========================
# ПРИМЕНЕНИЕ
# =========================

func apply_settings() -> void:
	_apply_music_volume()
	_apply_sfx_volume()
	_apply_fullscreen()
	_apply_vsync()
	_apply_resolution()

# =========================
# МУЗЫКА
# =========================

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_music_volume()

	setting_changed.emit("music_volume", music_volume)


func _apply_music_volume() -> void:
	var bus := AudioServer.get_bus_index("Music")

	if bus == -1:
		return

	AudioServer.set_bus_volume_db(
		bus,
		linear_to_db(max(music_volume, 0.0001))
	)

# =========================
# ЗВУКИ
# =========================

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()

	setting_changed.emit("sfx_volume", sfx_volume)


func _apply_sfx_volume() -> void:
	var bus := AudioServer.get_bus_index("SFX")

	if bus == -1:
		return

	AudioServer.set_bus_volume_db(
		bus,
		linear_to_db(max(sfx_volume, 0.0001))
	)

# =========================
# ПОЛНОЭКРАННЫЙ РЕЖИМ
# =========================

func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	_apply_fullscreen()

	setting_changed.emit("fullscreen", fullscreen)


func _apply_fullscreen() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)

# =========================
# VSYNC
# =========================

func set_vsync(enabled: bool) -> void:
	vsync = enabled
	_apply_vsync()

	setting_changed.emit("vsync", vsync)


func _apply_vsync() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED
		if vsync
		else DisplayServer.VSYNC_DISABLED
	)

# =========================
# РАЗРЕШЕНИЕ
# =========================

func set_resolution(size: Vector2i) -> void:
	resolution = size
	_apply_resolution()

	setting_changed.emit("resolution", resolution)


func _apply_resolution() -> void:
	DisplayServer.window_set_size(resolution)

# =========================
# СБРОС
# =========================

func reset_to_defaults() -> void:
	music_volume = 1.0
	sfx_volume = 1.0

	fullscreen = false
	vsync = true

	resolution = Vector2i(1920, 1080)

	apply_settings()
	save_settings()
