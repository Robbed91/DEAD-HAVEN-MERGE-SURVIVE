extends SceneTree
## Converts generated flat-chroma source renders into transparent,
## consistently-sized source and runtime PNGs. Magenta and green keys are
## supported so each object can use the key least likely to occur in its art.

const SOURCE_SIZE := 1024
const RUNTIME_SIZE := 256

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or args.size() % 3 != 0:
		push_error("Usage: --script tools/process_icon_chroma.gd -- <input> <source-output> <runtime-output> [...]")
		quit(2)
		return
	for index in range(0, args.size(), 3):
		if not _process_icon(args[index], args[index + 1], args[index + 2]):
			quit(4)
			return
	quit()

func _process_icon(input_path: String, source_path: String, runtime_path: String) -> bool:
	var image := Image.load_from_file(input_path)
	if image == null or image.is_empty():
		push_error("Could not load %s" % input_path)
		return false
	image.convert(Image.FORMAT_RGBA8)
	image.resize(SOURCE_SIZE, SOURCE_SIZE, Image.INTERPOLATE_LANCZOS)
	_remove_chroma(image)
	var source_error: Error = image.save_png(source_path)
	var runtime := image.duplicate()
	runtime.resize(RUNTIME_SIZE, RUNTIME_SIZE, Image.INTERPOLATE_LANCZOS)
	var runtime_error: Error = runtime.save_png(runtime_path)
	if source_error != OK or runtime_error != OK:
		push_error("PNG export failed: source=%s runtime=%s" % [source_error, runtime_error])
		return false
	print("ICON_PROCESSED %s -> %s, %s" % [input_path, source_path, runtime_path])
	return true

func _remove_chroma(image: Image) -> void:
	var corner := image.get_pixel(0, 0)
	var green_key := corner.g > corner.r and corner.g > corner.b
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			# Chroma compositing is identified by the keyed channel dominance.
			# Neutral steel, timber, cloth, rust and soft black shadows remain
			# opaque because none of those materials reaches this saturation.
			var dominance := c.g - maxf(c.r, c.b) if green_key else minf(c.r, c.b) - c.g
			if dominance <= 0.035:
				c.a = 1.0
			else:
				var alpha := 1.0 - smoothstep(0.035, 0.42, dominance)
				if alpha < 0.015:
					c = Color(0, 0, 0, 0)
				else:
					# Undo the keyed matte approximately for clean scaled edges.
					if green_key:
						c.r = clampf(c.r / alpha, 0.0, 1.0)
						c.g = clampf((c.g - (1.0 - alpha)) / alpha, 0.0, 1.0)
						c.b = clampf(c.b / alpha, 0.0, 1.0)
					else:
						c.r = clampf((c.r - (1.0 - alpha)) / alpha, 0.0, 1.0)
						c.g = clampf(c.g / alpha, 0.0, 1.0)
						c.b = clampf((c.b - (1.0 - alpha)) / alpha, 0.0, 1.0)
					c.a = alpha
			image.set_pixel(x, y, c)
