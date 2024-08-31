/*
Campanimia (Campanula + alkimia) - consumes different aspects fron attached crucibles
Amount of generated mana is based on eamount of different aspects
Catches: 
- flux generated by cauldrons (don't throw all items at once or sphagetti nuddle will apear!)
- each aspect will count only once (2 cauldron with terra, makes terra count only once)

Mana generations numbers:
1 -> 1
2 -> 2
3 -> 4
4 -> 8
5 -> 14
6 -> 21
7 -> 33
8 -> 48
9 -> 69
10 -> 96
11 -> 132
12 -> 180
13 -> 240
14 -> 318
15 -> 416
16 -> 539
17 -> 693
18 -> 884
19 -> 1120
20 -> 1410
21 -> 1764
22 -> 2195
23 -> 2718
24 -> 3348
25 -> 4105
26 -> 5013
27 -> 6097
28 -> 7388
29 -> 8920
30 -> 10733
31 -> 12874
32 -> 15394
33 -> 18354
34 -> 21822
35 -> 25877
36 -> 30608
37 -> 36116
38 -> 42516
39 -> 49938
40 -> 58530
41 -> 68457
42 -> 79909
43 -> 93098
44 -> 108263
45 -> 125673
46 -> 145630
47 -> 168475
48 -> 194587
49 -> 224395
50 -> 258377
51 -> 297066
*/
#loader contenttweaker
# priority 1

import mods.contenttweaker.VanillaFactory;
import mods.randomtweaker.cote.ISubTileEntity;
import mods.randomtweaker.cote.ISubTileEntityGenerating;
import mods.randomtweaker.cote.Update;
import crafttweaker.data.IData;
import mods.zenutils.DataUpdateOperation.APPEND;
import mods.zenutils.DataUpdateOperation.MERGE;
import mods.zenutils.DataUpdateOperation.REMOVE;
import mods.zenutils.DataUpdateOperation.OVERWRITE;
import crafttweaker.world.IWorld;
import crafttweaker.block.IBlock;
import crafttweaker.world.IBlockPos;
import crafttweaker.util.Position3f;
import crafttweaker.player.IPlayer;
import crafttweaker.entity.IEntity;
import crafttweaker.util.Math;

var campanimia as ISubTileEntityGenerating = VanillaFactory.createSubTileGenerating("campanimia");
campanimia.maxMana = 300000; //Max mana generated with all 51 aspects is 297066
campanimia.passiveFlower = false;
campanimia.range = 1;
campanimia.onUpdate = function(subtile, world, pos) { //subtile.acceptsRedstone(); TODO
    if(world.isRemote()) return;
    if(world.time%20!=7) return; 
    //check blocks
    val cruciblesPos = getCruciblesPos(world, pos);
    if(cruciblesPos.length == 0) return;
    val crucibles = getCrucibles(world, cruciblesPos);
    //calculate aspects
    val aspects = getAspectsList(crucibles);
    if(aspects.length==0) return;
    //check buffer
    val generatedMana = pow(10,pow(aspects.length,0.475) - 1) as int;
    if(subtile.getMaxMana() - subtile.getMana()<generatedMana) return; //Or make it to loose acutally mana? To always keep buffer empty to not loose mana?
    //take essentia
    drinkEssentia(world, cruciblesPos);
    //generate mana
    subtile.addMana(generatedMana);
    playSound("thaumcraft:spill", pos, world);
    return;
};
campanimia.register();

function getCruciblesPos(world as IWorld, posFlower as IBlockPos) as IBlockPos[] {
    var cruciblesPos = [] as IBlockPos[];
    val poss = [
        toBlockPos(posFlower.x + 1, posFlower.y, posFlower.z),
        toBlockPos(posFlower.x - 1, posFlower.y, posFlower.z),
        toBlockPos(posFlower.x, posFlower.y, posFlower.z + 1),
        toBlockPos(posFlower.x, posFlower.y, posFlower.z - 1),
    ] as IBlockPos[];

    for pos in poss {
        val block = world.getBlock(pos);
        if(isNull(block)
        || isNull(block.data)
        || isNull(block.data.id)
        || block.data.id!="thaumcraft:tilecrucible"
        || block.data.Amount<100
        || block.data.Heat!=200
        || block.data.Aspects.length==0) continue;
        cruciblesPos += pos;
    }

    return cruciblesPos;
}

function toBlockPos(x as int, y  as int, z  as int) as IBlockPos{
    return crafttweaker.util.Position3f.create(x, y, z) as IBlockPos;
}

function getCrucibles(world as IWorld, cruciblesPosList as IBlockPos[]) as IBlock[]{
    var crucibles = [] as IBlock[];
    for cruciblePos in cruciblesPosList{
        crucibles += world.getBlock(cruciblePos);
    }
    return crucibles;
}

function getAspectsList(crucibles as IBlock[]) as IData { 
    var aspects as IData = [];
    for crucible in crucibles {
        for i in 0 .. crucible.data.Aspects.length{
            aspects += [crucible.data.Aspects[i].key];
        }
    }
    return aspects;
}

function drinkEssentia(world as IWorld, cruciblesPosList as IBlockPos[]) as void {
    for cruciblePos in cruciblesPosList {
        var overwriteData = [] as IData;
        val crucible = world.getBlock(cruciblePos);
        for i in 0 .. crucible.data.Aspects.length {
            if(crucible.data.Aspects[i].amount>1) overwriteData = overwriteData.deepUpdate([{amount: (crucible.data.Aspects[i].amount - 1), key: crucible.data.Aspects[i].key}], MERGE);
        }
        val newData = crucible.data.deepUpdate({Aspects: overwriteData, Amount: (crucible.data.Amount - 100)}, {Aspects: OVERWRITE, Amount: OVERWRITE});
        world.setBlockState(world.getBlockState(cruciblePos), newData, cruciblePos);
    }
    return;
}

function playSound(str as string, pos as IBlockPos, world as IWorld) as void{
    val list = world.getAllPlayers();
    for player in list {
        if(isNull(player)
        || player.world.dimension!=world.dimension
        || Math.sqrt(pow(player.x - pos.x, 2) * pow(player.y - pos.y, 2) * pow(player.z - pos.z, 2))>50) continue;
        player.sendPlaySoundPacket(str, "ambient", pos, 0.05f, 1.0f);
    }
}
