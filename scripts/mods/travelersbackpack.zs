#modloaded travelersbackpack



# *======= Traveler's Backpacks =======*
recipes.remove(<travelersbackpack:hose>);
recipes.addShaped(<travelersbackpack:hose>, [
	[<travelersbackpack:hose_nozzle>, <ore:itemRubber>, <ore:itemRubber>],
	[null, null, <ore:itemRubber>],
	[null, null, <ore:dyeGreen>]]);

# Remake Sleeping bag (prevent conflict)
remakeEx(<travelersbackpack:sleeping_bag_bottom>, [[<quark:quilted_wool:14>, <quark:quilted_wool:14>, <quark:quilted_wool>]]);
