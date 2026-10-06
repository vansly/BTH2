@tool
extends EditorScript

## Builds assets/meshes/forest_library.tscn from the 32 .glb files in assets/grid_map/forest.
## This is the scripted version of dragging each model into a scene and running
## Mesh | Create Collision Shape on it.
##
## To run: open this file in the Script Editor and press **File | Run** (Ctrl + Shift + X).
## Output goes to the **Output** panel below.

const SOURCE_DIR := "res://assets/grid_map/forest"
const OUTPUT := "res://assets/meshes/forest_library.tscn"

## The models are laid out in rows just so they are readable in the editor. These positions
## are NOT baked into the library (export with Apply MeshInstance Transforms off), so the
## layout can be anything.
const SHELF_SPACING := 3.0
const SHELF_COLUMNS := 8


func _run() -> void:
	var dir := DirAccess.open(SOURCE_DIR)
	if dir == null:
		push_error("Không mở được %s" % SOURCE_DIR)
		return
	var files := dir.get_files()
	files.sort()

	var root := Node3D.new()
	root.name = "ForestLibrary"
	var index := 0
	for file: String in files:
		if not file.ends_with(".glb"):
			continue
		var item_name := file.get_basename()
		var mesh := _load_mesh(SOURCE_DIR + "/" + file)
		if mesh == null:
			push_warning("%s: không tìm thấy MeshInstance3D" % file)
			continue

		var instance := MeshInstance3D.new()
		instance.name = item_name
		instance.mesh = mesh
		instance.position = Vector3((index % SHELF_COLUMNS) * SHELF_SPACING, 0.0,
			(index / SHELF_COLUMNS) * SHELF_SPACING)
		root.add_child(instance)
		instance.owner = root

		var body := StaticBody3D.new()
		body.name = "StaticBody3D"
		instance.add_child(body)
		body.owner = root

		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shaped := _shape_for(item_name, mesh)
		collision.shape = shaped[0]
		collision.transform = shaped[1]
		body.add_child(collision)
		collision.owner = root

		print("  %-24s %s" % [item_name, shaped[2]])
		index += 1

	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		error = ResourceSaver.save(packed, OUTPUT)
	if error != OK:
		push_error("Lưu %s thất bại: %d" % [OUTPUT, error])
		return
	print("Đã dựng %s với %d item" % [OUTPUT, index])
	root.free()
	# Force a FileSystem rescan so the file just written shows up in the dock right away.
	EditorInterface.get_resource_filesystem().scan()


## Returns [shape, transform, label to print] for one item.
##
## Right now every model uses a trimesh, exactly like the Mesh | Create Collision Shape |
## Trimesh you clicked by hand. Run the game, then come back here: one kind of model cannot
## use a trimesh. See the "Chạy thử: Cáo kẹt ở chân thang" section of the guide.
func _shape_for(item_name: String, mesh: Mesh) -> Array:
	if item_name.begins_with("stair_") \
			and not item_name.begins_with("stair_beside"):
		var box := BoxShape3D.new()
		box.size = Vector3(2.0, 2.0, 2.0 * sqrt(2.0))
		var tf := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(45.0)),
				Vector3(0.0, -sqrt(2.0) / 2.0, -sqrt(2.0) / 2.0))
		return [box, tf, "nêm 45° (hộp xoay)"]
	return [mesh.create_trimesh_shape(), Transform3D.IDENTITY, "trimesh"]


func _load_mesh(path: String) -> Mesh:
	var scene: PackedScene = load(path)
	if scene == null:
		return null
	var root := scene.instantiate()
	var found := _find_mesh(root)
	var mesh: Mesh = found.mesh if found != null else null
	root.free()
	return mesh


func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result := _find_mesh(child)
		if result != null:
			return result
	return null
