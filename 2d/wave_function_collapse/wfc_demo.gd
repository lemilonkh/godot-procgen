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
		
@export var slow_down_output : bool = false

var sample_cells : Dictionary
var output_cells : Dictionary
var adjacencies : Dictionary
var super_positions : Dictionary
var sample_tiles : Dictionary
var cell_update_stack : Array[Vector2i]
var known_tiles : Dictionary
var weights : Dictionary

# helper function - returns true if cell is surrounded by cells with same atlas coord
func is_inside_cell(cell: Vector2i) -> bool:
	for neighbor in config_layer.get_surrounding_cells(cell):
		if config_layer.get_cell_atlas_coords(neighbor) != config_layer.get_cell_atlas_coords(cell):
			return false
	return true

func setup_config() -> void:
	
	# see which cells are part of the sample
	for cell in config_layer.get_used_cells_by_id(0, Vector2i(0,0) ):
		if is_inside_cell(cell):
			sample_cells[cell] = true
			
	# see which cells are part of the output
	for cell in config_layer.get_used_cells_by_id(0, Vector2i(1,0) ):
		if is_inside_cell(cell):
			output_cells[cell] = true
			
	# build up dictionary of adjacencies
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
		sample_tiles.get_or_add(cell_tile,true)
		
		# then save them in the dictionary, the key is the tile type of the current
		# cell and the corresponding direction, the value is a dictionary again for
		# quick lookups later
		adjacencies.get_or_add([cell_tile,TileSet.CELL_NEIGHBOR_TOP_SIDE],Dictionary()
			).get_or_add(up_tile,true)
		adjacencies.get_or_add([cell_tile,TileSet.CELL_NEIGHBOR_BOTTOM_SIDE],Dictionary()
			).get_or_add(down_tile,true)
		adjacencies.get_or_add([cell_tile,TileSet.CELL_NEIGHBOR_LEFT_SIDE],Dictionary()
			).get_or_add(left_tile,true)
		adjacencies.get_or_add([cell_tile,TileSet.CELL_NEIGHBOR_RIGHT_SIDE],Dictionary()
			).get_or_add(right_tile,true)
		if sample_layer.tile_set.get_custom_data_layer_by_name("weight") != -1:
			var weight = sample_layer.get_cell_tile_data(cell).get_custom_data("weight")
			weights[cell_tile] = weight
	# set up super positions for unfilled output tiles
	# already filled tiles need to cause an update
	for cell in output_cells:
		if sample_layer.get_cell_atlas_coords(cell) == Vector2i(-1,-1):
			super_positions[cell]  = sample_tiles.keys()
		else:
			known_tiles[cell] = sample_layer.get_cell_atlas_coords(cell)
			cell_update_stack.push_back(cell)

# see if given a certain number of possible tiles from a neighbor restricts
# which tiles are still valid according to known adjacencies
func constraint_possibilites(neighbor_possibilites,from_direction,cell) -> bool:
	#if not super_positions.has(cell):
		#return false
	var possible_tiles = super_positions[cell]
	var possibilities_count = len(possible_tiles)
	var direction = from_direction
	var still_possible : Array[Vector2i]
	still_possible.clear()
	for tile in possible_tiles:
		for neighbor_tile in neighbor_possibilites:
			# lookup if this is a valid adjacency
			if adjacencies[[neighbor_tile,direction]].has(tile):
				still_possible.push_back(tile)
				break
			
	
	# let the function caller know if the possibilities were reduced
	if len(still_possible) < possibilities_count:
		# it is possible that "still possible" only has 1 or 0 tiles now but
		# this is checked only after all updates are done
		super_positions[cell] = still_possible
		return true
	else:
		return false
	
# in this function all neighbors of a cell are checked if based on the
# current possible tiles of the cell the neighbors possibilites can be reduced
func collapse_neighbors(cell: Vector2i,output_layer: TileMapLayer) -> void:
	
	var cell_possibilities : Array[Vector2i]
	if super_positions.has(cell):
		cell_possibilities.append_array(super_positions[cell])
	else:
		cell_possibilities.push_back(output_layer.get_cell_atlas_coords(cell))
		
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
	
	for entry in neighbors:
		var neighbor_cell = entry[0]
		if super_positions.has(neighbor_cell):
			if constraint_possibilites(cell_possibilities,entry[1],neighbor_cell):
				cell_update_stack.push_back(neighbor_cell)

func render_tile_to_ouput(cell: Vector2i, output_layer: TileMapLayer) -> void:
	output_layer.set_cell(cell,0,known_tiles[cell])

# this function encapsulates a random choice of a tile
# if not all tiles shall have equal chance, this would be the place
# to model a weighted choice
func choose_tile(cell: Vector2i) -> Vector2i:
	if len(weights.keys()) > 0:
		var possible_tiles : Array[Vector2i]
		possible_tiles.clear()
		for choice in super_positions[cell]:
			if weights[choice] > 0.0:
				possible_tiles.push_back(choice)
		return possible_tiles.pick_random()
	else:
		return super_positions[cell].pick_random()

func draw_output() -> void:
	sample_cells.clear()
	output_cells.clear()
	adjacencies.clear()
	super_positions.clear()
	sample_tiles.clear()
	cell_update_stack.clear()
	known_tiles.clear()
	weights.clear()
	if sample_layer and config_layer:
		setup_config()
		print("starting generation")
		var output_layer : TileMapLayer = sample_layer.duplicate()
		output_layer.tile_set = sample_layer.tile_set.duplicate()
		add_child(output_layer)
		output_layer.owner = self
		output_layer.name = "output_layer"
		output_layer.clear()
		for cell in output_cells:
			if known_tiles.has(cell):
				output_layer.set_cell(cell,0,known_tiles[cell])
			else:
				output_layer.set_cell(cell,0,Vector2i(100,100))
		
		while len(super_positions) > 0:
			while len(cell_update_stack) > 0:
				var cell = cell_update_stack.pop_back()
				collapse_neighbors(cell,output_layer)
				
			var super_positions_keys = super_positions.keys()
			var least_entropy = len(sample_tiles)
			var least_entropy_candidates : Array[Vector2i]
			least_entropy_candidates.clear()
			for cell_key in super_positions_keys:
				var entropy = len(super_positions[cell_key])
				if entropy < 2:
					if entropy < 1:
						known_tiles[cell_key] = Vector2i(100,100)
					else:
						known_tiles[cell_key] = super_positions[cell_key][0]
						render_tile_to_ouput(cell_key, output_layer)
						if slow_down_output:
							await get_tree().create_timer(0.1).timeout
					super_positions.erase(cell_key)
				else:
					if entropy < least_entropy:
						least_entropy = entropy
						least_entropy_candidates.clear()
					if entropy <= least_entropy:
						least_entropy_candidates.push_back(cell_key)
						
			var cell_to_set_next = least_entropy_candidates.pick_random()
			var chosen_tile  = choose_tile(cell_to_set_next)
			known_tiles[cell_to_set_next] = chosen_tile
			super_positions.erase(cell_to_set_next)
			render_tile_to_ouput(cell_to_set_next,output_layer)
			cell_update_stack.push_back(cell_to_set_next)
			if slow_down_output:
				await get_tree().create_timer(0.1).timeout

		print("done with generation")
