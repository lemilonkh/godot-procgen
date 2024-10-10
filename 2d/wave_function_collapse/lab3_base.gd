@tool
extends Node2D

# the drawing input
@export var sample_layer : TileMapLayer = null
# the configuration input
@export var config_layer : TileMapLayer = null

# a simple trigger button
@export var _draw_output : bool:
	set(value):
		draw_output()
		

var sample_cells : Dictionary
var output_cells : Dictionary
#var adjacencies : Dictionary
var super_positions : Dictionary
var cell_update_stack : Array[Vector2i]

func setup_config() -> void:
	
	# see which cells are part of the sample
	for cell in config_layer.get_used_cells_by_id(0, Vector2i(0,0) ):
			sample_cells[cell] = true
			
	# see which cells are part of the output
	for cell in config_layer.get_used_cells_by_id(0, Vector2i(1,0) ):
			output_cells[cell] = true
			
	# build up adjacencies
	for cell in sample_cells:
		# first get all neighboring tile types
		var cell_tile = sample_layer.get_cell_atlas_coords(cell)
		var up_tile = sample_layer.get_cell_atlas_coords(
			sample_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_TOP_SIDE))
		var down_tile = sample_layer.get_cell_atlas_coords(
			sample_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE))
		var left_tile = sample_layer.get_cell_atlas_coords(
			sample_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_LEFT_SIDE))
		var right_tile = sample_layer.get_cell_atlas_coords(
			sample_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_RIGHT_SIDE))
		
		# do something useful with the information about adjacent tiles
		pass

	# set up output space, if you have a seed tile you can mark that down as known
	for cell in output_cells:
		if sample_layer.get_cell_atlas_coords(cell) == Vector2i(-1,-1):
			
			pass
			
		else:
			
			pass

# see if given a certain number of possible tiles from a neighbor restricts
# which tiles are still valid according to known adjacencies
# should return true if the number of possibilities was constraint after this run
func constraint_possibilites(neighbor_possibilites,from_direction,cell) -> bool:
	
	pass
	return false
	
# in this function all neighbors of a cell are checked if based on the
# current possible tiles of the cell the neighbors possibilites can be reduced
func collapse_neighbors(cell: Vector2i,output_layer: TileMapLayer) -> void:
	
	# gath
	var possibilities # set this to something useful
	pass
		
	# this structure seemed useful, see if you want to use it, too
	var neighbors = [
		[output_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_TOP_SIDE),
			TileSet.CELL_NEIGHBOR_TOP_SIDE],
		[output_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE),
			TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],
		[output_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_LEFT_SIDE),
			TileSet.CELL_NEIGHBOR_LEFT_SIDE],
		[output_layer.get_neighbor_cell(cell,TileSet.CELL_NEIGHBOR_RIGHT_SIDE),
			TileSet.CELL_NEIGHBOR_RIGHT_SIDE]
	]
	
	for neighbor_info in neighbors:
		var neighbor_cell = neighbor_info[0]
		if possibilities.has(neighbor_cell):
			var direction = neighbor_info[1]
			if constraint_possibilites(possibilities,direction,neighbor_cell):
				cell_update_stack.push_back(neighbor_cell)

func render_tile_to_ouput(cell: Vector2i, output_layer: TileMapLayer) -> void:
	var tile_coordinates # set this to something useful
	output_layer.set_cell(cell,0,tile_coordinates)

# this function encapsulates a random choice of a tile
# if not all tiles shall have equal chance, this would be the place
# to model a weighted choice
func choose_tile(cell: Vector2i) -> Vector2i:
	pass
	return Vector2i(100,100)

func draw_output() -> void:
	# don't forget to clear these, this toolscript is not initialized each run
	sample_cells.clear()
	output_cells.clear()
	cell_update_stack.clear()
	if sample_layer and config_layer:
		print("starting generation")
		setup_config()
		var output_layer : TileMapLayer = sample_layer.duplicate()
		output_layer.tile_set = sample_layer.tile_set.duplicate()
		add_child(output_layer)
		output_layer.owner = self
		output_layer.name = "output_layer"
		output_layer.clear()
		for cell in output_cells:
			#  copy the seed tiles
			pass
		
		while len(super_positions) > 0:
			while len(cell_update_stack) > 0:
				var cell = cell_update_stack.pop_back()
				collapse_neighbors(cell,output_layer)
				
			var least_entropy_candidates # set this to something useful
			# select from the still undetermined cells that which has the least different
			# possible tiles and then select one tile from this
			# if only one tile was still possible that's good, we can remove it from the
			# undetermined cells
			# if none was possible that's bad, tile map generation has failed
			
					
			if len(least_entropy_candidates) > 0:
				var cell_to_set_next = least_entropy_candidates.pick_random()
				var chosen_tile  = choose_tile(cell_to_set_next)
				# handle that a tile was chosen for the cell
				pass

		print("done with generation")
