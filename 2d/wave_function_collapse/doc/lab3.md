# Wave Function Collapse Lab 3

Welcome to lab 3. If you understand an algorithm best when you code your own, this is the one for you. We look a bit at the base provided with this lab and then a bit more thorough at the algorithm so you can implement it on your own.

The scene prepared for this has the surprising name lab3_base. You could start from a blank slate, the scene just gives a bit of convenience to start coding the algorithm.

To have a sample layer which contains both the template and the seed tiles and a config layer is a choice that was made because it seemed easier to convey how the algorithm works. You can of course have your template and seed tiles on different tile map layers.

With the provided base you get a few empty function definitions to guide the implementation. Again feel free to erase everything. Especially a few classes would help to made the code easier to work with, the only reason they were avoided in the demo implementation is to keep everything restricted to one script and as basic as possible.

## Wave Function Collapse explainer

To implement the algorithm we need to know how it works. While lab 1 already had a little bit of an explanation of that, it was avoiding to talk too much about data structures. We won't avoid them now. Promised.

If you took the lab 3 base to tinker with it already gives you a dictionary of sample cells, key is cell coordinate on the tile map layer and value is the corresponding texture atlas coordinate in the tile set. You also get the dictionary of output cells if you want that. Again keys are cell coordinates and if a seed tile was present its texture atlas coordinate was set. In GDScript you can get the keys from a Dictionary through the keys() function, if you want to iterate of this.

You first task is to implement reading in the adjacency information about tiles. Put differently we want to know for which texture atlas coordinate in which cardinal direction which different texture atlas coordinate can go. So which tile can be above a certain tile, which below, left and right.

Next we need a datastructure to hold for each output cell which tiles are possible to exist in this cell. Either any of the template tiles or the seed tile.

If a seed tile is present we put that on an update stack. This stack helps to track around which cells we need to call the collapse function.

Then we need a function that propagates changes to the number of possible tiles to its neighbors. In the lab3 base script this is called collapse. Be careful to also put neighbor cells on the update stack in this function call, if their possible tiles got reduced. Reducing the possible tiles works as follows: Look at each tile in the reference cell, can each tile in the neighbor cell go with these tiles in the direction of the neighbor? Discard tiles in the neighbor that are not consistent.

Lastly we need a function that executes a random choice for the number of possible tiles, pick one. There is literally this function "pick_random" for arrays in GDScript. In lab 2 we look at weighted choice, go there if you want to enhance this random choice function later.

To tie everything together we need to know for which cell this random choice to pick one possible tile should be done. That's the magic in the wfc algorithm. We look at ~fanfare~ ENTROPY!
A very easy variant is look at all still undetermined cells. For those with the least amount of possible tiles pick one of those cells and then apply the random choice of a tile. Oh and don't forget the update stack.

Structurally it would look somewhat like this in the code:

``` python
setup_data_structures()
put_seed_tiles_on_update_stack()
while still_a_cell_undetermined:
    collapse_tiles() # around cells on update stack until stack is empty
    find_least_entropy_candidate()
    pick_random_tile_on_candidate() # and put this cell on the update stack
```

The only complicated thing is the find good data structures to represent everything you need.

With the template provided a possible output could look like this (borrowed from lab 2):

![screenshot showing a variant of the generated output](lab2_start_output.jpg "sample output")

Do be creative with your own approach to implement the algorithm. If you get stuck, take a peek at the wfc_demo script. It's probably hard to finish this lab within 60 minutes if you have no previous experience with wave function collapse.

## Final words

I hope you liked this lab. It was fun writing it. Do try the other labs if you feel up to it!

Written by: Thomas Lobig https://github.com/tlobig