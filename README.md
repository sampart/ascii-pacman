# ASCII Pacman

As part of my computing A-level I was taught to program in Pascal.  (We used Turbo Pascal 1.5 for Windows and we were taught Delphi later).  However, I wanted to do something a little more interesting, adventurous and tricky than what we were taught at college and so I began work on the _ASCII Pacman project_.

I carried working on it for a few years after for a couple of reasons:  First, because it helped prevent me forgetting how to code in Pascal, but also because the project threw up some interesting puzzles and challenges for me.  The main one of these was the issue of how the enemy can find the fastest path to the player.  Conventional maze-solving algorithms (e.g. follow left-hand walls) don't work with the open plan levels which are possible (for instance, the play area could be completely open with walls only around the outside as a border, or could have passageways of more than one square wide and so on).

## Path-finding methods

The **original version** had a very simple algorithm: if the player is above the enemy and the square above the enemy does not contain a wall, move up.   Otherwise, if the player is below the enemy and the square below the enemy does not contain a wall, move down.  Otherwise, ... you get the idea :-)

The **next versions** (up to 1.0a) contained this same method with one key improvement: as the enemy found "dead-ends" (defined as squares on the playfield from where there is only one direction to go) he marked these with a number in his "knowledge array".  Any square which has two ways out, one of which is marked as dead-end _x_, will also then be marked as dead-end _x_, so any paths leading to dead ends will be marked as dead-ends themselves.  The enemy will then never move into a dead-end path unless the player is somewhere on that path too.

I then devised and tested **a method which works fine in theory**: begin by calling a path-finding procedure on every direction (up, down, left and right) which is not blocked by a wall.  This procedure will return a number which is the number of moves it will take to get to the player if you set off in that direction (I used _MaxInt_ if the path resulted in a dead-end).  This procedure works by calling itself recursively on every possible direction and then returning the result of the shortest distance + 1 (for itself).  This is a nice method in theory.  However, in practice its complexity (i.e. the number of recursive calls generated and thus the processing power required and so on) means that it's infeasible.  I left it running for 20 minutes on my laptop (on a play-area with a relatively large number of walls and thus one which wouldn't take as much processing as a more open area) and the enemy had still not moved a single square in any direction...

The **current method** I'm using (version 1.1) was suggested by my friend [Sean](http://www.seanlyttle.co.uk), who's particularly clever at this sort of thing.   The basic idea is that procedures set off in each possible direction from the enemy, with each direction taking it in turns to make a move (rather than one direction completing and then another trying).  If a procedure reaches a square which another has already visited, then that route will terminate -- something else is obviously faster than it as that other procedure got to that square first.  This is controlled using stacks (hence the _stack2i.pas_ download below) and results in the shortest path from an enemy to the player being found every time.

The path-finding algorithm takes into account the fact that there may be several enemies, and that it would be a bit boring if they all followed the exact same path to the player.  A system of **priorities** has therefore been implemented whereby the order in which directions are tested is altered.  This means, for instance, that if the player is in the bottom-right corner of an empty play-area and a number of enemies are in the top-left of the play-area, some will go down and then right and others will go right and then down.  Obviously it works for non-empty play-areas too, but it's more noticeable in an empty one.  The path is recalculated every move.

## The current version

The current version (release 1.1; released 20/9/2004) contains the following main features:

* A cherry which, when eaten, allows you to eat the enemy

* Enemy route-finding (see above), and the option to have multiple enemies


* Level Editor with save / load facilities or the option to play a standard level

* Standard pacman stuff (walls, the ability to win by eating all dots, game over if the enemy catches you, About screen etc)

The previous release (1.0a) improved the structure and layout of the program, resulting in cleaner code.  Release 1.1 concentrated on improved functionality and so will have noticeable differences in the executable as well as the code.  The main improvement is with regard to enemies.  The path-finding method now allows an enemy to find the shortest path to the player.  Furthermore, multiple enemies are now supported (although since they all follow their fastest route to the player, it could get pretty challenging to win!).  There are also a number of changes to the level editor, including wall-painting (allowing faster editing) and the option to cancel the loading and saving of levels and the path changing.

**NB:** The level file structure has altered in this version.   Old level files will open, but the objects (player, enemies, cherry) won't be loaded and will need putting back in.  Attempting to load new-format levels in an old version will give a run-time error!

## Useful code

One thing worth mentioning about the code (as this may be useful to other Pascal programmers), is the line:

```pascal
**VAR** Timer : longint **absolute** $40:$6C;
```

At this position is held the number of clock ticks since midnight. (18.2 ticks = 1 second.)  This variable can therefore be used for creating delays and so on.
