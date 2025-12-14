extends CanvasLayer
class_name PerformanceHUD

"""
PerformanceHUD - Debug overlay for monitoring game performance

USAGE:
- Toggle with F3 key
- Shows FPS, Draw Calls, Objects, Memory
- Color-coded thresholds (green/yellow/red)

INTEGRATION:
- Add as child of main scene or autoload
- Self-contained, no external dependencies
"""

# UI References
var panel: PanelContainer
var vbox: VBoxContainer
var fps_label: Label
var draw_calls_label: Label
var objects_label: Label
var nodes_label: Label
var memory_label: Label

# Tracking
var is_visible: bool = false
var fps_history: Array = []
var fps_history_max: int = 60  # 1 second of samples at 60fps

# Thresholds for color coding
const FPS_GOOD = 55
const FPS_WARN = 40
const DRAW_CALLS_GOOD = 500
const DRAW_CALLS_WARN = 2000
const OBJECTS_GOOD = 2000
const OBJECTS_WARN = 5000
const NODES_GOOD = 10000
const NODES_WARN = 20000

func _ready():
	_create_ui()
	panel.visible = is_visible
	print("PerformanceHUD ready - Press F3 to toggle")

func _create_ui():
	# Create panel
	panel = PanelContainer.new()
	add_child(panel)
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	
	# Position in top-right corner
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -200
	panel.offset_right = -10
	panel.offset_top = 10
	panel.offset_bottom = 0
	
	# Create container for labels
	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Performance (F3)"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(title)
	
	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)
	
	# FPS
	fps_label = _create_metric_label("FPS: --")
	vbox.add_child(fps_label)
	
	# Draw Calls
	draw_calls_label = _create_metric_label("Draw Calls: --")
	vbox.add_child(draw_calls_label)
	
	# Objects Drawn
	objects_label = _create_metric_label("Objects: --")
	vbox.add_child(objects_label)
	
	# Nodes
	nodes_label = _create_metric_label("Nodes: --")
	vbox.add_child(nodes_label)
	
	# Memory
	memory_label = _create_metric_label("Memory: --")
	vbox.add_child(memory_label)

func _create_metric_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	return label

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		is_visible = !is_visible
		panel.visible = is_visible

func _process(_delta):
	if not is_visible:
		return
	
	_update_metrics()

func _update_metrics():
	# FPS
	var fps = Engine.get_frames_per_second()
	fps_history.append(fps)
	if fps_history.size() > fps_history_max:
		fps_history.pop_front()
	
	var avg_fps = 0.0
	for f in fps_history:
		avg_fps += f
	avg_fps /= fps_history.size()
	
	fps_label.text = "FPS: %d (avg: %d)" % [fps, int(avg_fps)]
	fps_label.add_theme_color_override("font_color", _get_threshold_color(fps, FPS_GOOD, FPS_WARN, true))
	
	# Draw Calls
	var draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	draw_calls_label.text = "Draw Calls: %d" % draw_calls
	draw_calls_label.add_theme_color_override("font_color", _get_threshold_color(draw_calls, DRAW_CALLS_GOOD, DRAW_CALLS_WARN, false))
	
	# Objects Drawn
	var objects = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
	objects_label.text = "Objects: %d" % objects
	objects_label.add_theme_color_override("font_color", _get_threshold_color(objects, OBJECTS_GOOD, OBJECTS_WARN, false))
	
	# Nodes
	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	nodes_label.text = "Nodes: %d" % nodes
	nodes_label.add_theme_color_override("font_color", _get_threshold_color(nodes, NODES_GOOD, NODES_WARN, false))
	
	# Memory
	var mem_static = Performance.get_monitor(Performance.MEMORY_STATIC)
	var mem_mb = mem_static / 1048576.0
	memory_label.text = "Memory: %.1f MB" % mem_mb

func _get_threshold_color(value: float, good_threshold: float, warn_threshold: float, higher_is_better: bool) -> Color:
	if higher_is_better:
		if value >= good_threshold:
			return Color(0.4, 1.0, 0.4)  # Green
		elif value >= warn_threshold:
			return Color(1.0, 1.0, 0.4)  # Yellow
		else:
			return Color(1.0, 0.4, 0.4)  # Red
	else:
		if value <= good_threshold:
			return Color(0.4, 1.0, 0.4)  # Green
		elif value <= warn_threshold:
			return Color(1.0, 1.0, 0.4)  # Yellow
		else:
			return Color(1.0, 0.4, 0.4)  # Red
