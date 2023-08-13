{
You may re-use any of this code in any commerical or non-commercial application as required.
You may also modify this program as you wish.  However, please don't pass this application off as your own work!
}

{
known bugs:
===========
no beep produced when cherry eaten (problem with messagebeep call)

changes since version 1.0 (not a comprehensive list)
====================================================
ENEMY_MOVEMENT drastically improved by the use of FIND_PATH (see website for details)
"Wall painting" enabled.
Multiple enemies implemented (file structure altered!)
Cancel option included in loading, saving and path-changing in the level editor
}

{The grid is 40 by 15.  The standard level looks as follows:

ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
ƒ                                      ƒ
ƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒ
ƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒ
ƒ                                      ƒ
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ                    
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ
ƒ                                      ƒ
ƒƒ  ƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒ
ƒƒ  ƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒ
ƒ                                      ƒ
ƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒ
ƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ  ƒƒƒƒƒƒƒƒƒƒ
ƒ                                      ƒ
ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒ}

PROGRAM Pacman;

USES WINCRT, WINPROCS, STRINGS, WINDOS, STACK2I;

CONST
     MinInt = -MaxInt-1; {smallest possible int}

     {various characters}
     LevelEditCaret = '_';
     PlayerCharacter = 'C';
     EnemyCharacter = '§';
     EnemyEdibleCharacter = '$';
     CherryCharacter = '¶';
     WallCharacter = 'ƒ'; {setting this to '.' is likely to cause major issues!}

{This has now been modified so that positions of player, enemies and cherry are recorded by
data in the array, rather than by separate variable}

TYPE
    LevelDetails = RECORD
    LevelArray : ARRAY [1..40, 1..15] OF CHAR;
END;

VAR
   EndedGame : BOOLEAN; {Set when win or lose, checked by the game loop}

   LevelArray : ARRAY [1..40, 1..15] OF CHAR;
   VisitedArray : ARRAY [1..40, 1..15] OF INTEGER;

   XPositionOfPlayer: INTEGER; {99 used to indicate a non-placed player; was called XPositionOfPlayer}
   YPositionOfPlayer: INTEGER; {was called YPositionOfPlayer}

   EnemyStack : NodePtr; {see stack2i for details of NodePtr}

   XPositionOfCherry: INTEGER; {99 used to indicate a non-placed cherry}
   YPositionOfCherry: INTEGER;

   GotCherry : Boolean;
   CherryTimer : INTEGER; {not used at present, but will be in future so that the cherry's effect doesn't last for ever}
   CursorPosX : INTEGER;
   CursorPosY : INTEGER;

   EnemyKnowledgeArray : ARRAY [1..40, 1..15] OF INTEGER;
   CurrentDeadEndInteger : INTEGER; {was called CharacterToDenoteDeadEnds}
   AddedtoCurrentDeadEndInteger : BOOLEAN; {was called AddedToCharacterToDenoteDeadEnds}

   Path : STRING;

{Draws player, enemies and cherry on the play area}
PROCEDURE POSITION_OBJECTS;
VAR CurrentEnemy : NodePtr;
BEGIN
     {This check added in so that we can call this procedure during level editing}
     IF XPositionOfPlayer<>99 THEN
     BEGIN
          GOTOXY (XPositionOfPlayer,YPositionOfPlayer);
          WRITE (PlayerCharacter);
     END;

     CurrentEnemy := EnemyStack;
     WHILE (CurrentEnemy <> NIL) DO
     BEGIN          
          GOTOXY (CurrentEnemy^.X, CurrentEnemy^.Y);
          WRITE (EnemyCharacter);
          CurrentEnemy := CurrentEnemy^.Next;
     END;

     IF XPositionOfCherry<>99 THEN
     BEGIN
          GOTOXY (XPositionOfCherry, YPositionOfCherry);
          WRITE (CherryCharacter);
     END;
END;

{draws out the grid of dots and writes them to the array.}
PROCEDURE LAY_BORDER_AND_GRID_OF_DOTS;
VAR LinesDrawnX : INTEGER;
    LinesDrawnY : INTEGER;
BEGIN
     {Draw border walls:}
     FOR LinesDrawnX:=1 TO 40 DO
     BEGIN
          GOTOXY (LinesDrawnX, 1);
          WRITE (WallCharacter);
          LevelArray[LinesDrawnX, 1]:=WallCharacter;
     END;

     FOR LinesDrawnX:=1 TO 15 DO
     BEGIN
          GOTOXY (1, LinesDrawnX);
          WRITE (WallCharacter);
          LevelArray[1, LinesDrawnX]:=WallCharacter;
     END;

     FOR LinesDrawnX:=1 TO 40 DO
     BEGIN
          GOTOXY (LinesDrawnX, 15);
          WRITE (WallCharacter);
          LevelArray[LinesDrawnX, 15]:=WallCharacter;
     END;

     FOR LinesDrawnX:=0 TO 15 DO
     BEGIN
          GOTOXY (40, LinesDrawnX);
          WRITE (WallCharacter);
          LevelArray[40, LinesDrawnX]:=WallCharacter;
     END;

     {Lay dots:}
     FOR LinesDrawnY:=2 TO 14 DO
     BEGIN
          FOR LinesDrawnX:=2 TO 39 DO
          BEGIN
               GOTOXY (LinesDrawnX, LinesDrawnY);
               WRITE ('.');
               LevelArray[LinesDrawnX, LinesDrawnY]:='.';
          END;
     END;
END;

PROCEDURE WRITE_CONTROLS_TEXT;
BEGIN
     GOTOXY (42, 1);
     WRITE ('Welcome to ASCII Pac Man.');
     GOTOXY (42, 3);
     WRITE ('Control Pac Man using the');
     GOTOXY (42, 4);
     WRITE ('following keys:');
     GOTOXY (42, 6);
     WRITE ('T: Up, G: Down, F: Left and H: Right.');
     GOTOXY (42, 7);
     WRITE ('(Press Q to quit.)')
END;

PROCEDURE DRAW_OUT_CUSTOM_GRID;
VAR XPlace : INTEGER;
    YPlace : INTEGER;
BEGIN
     CLRSCR;
     FOR XPlace:=1 TO 40 DO
     BEGIN
          FOR YPlace:=1 TO 15 DO
          BEGIN
               GOTOXY (XPlace,YPlace);
               WRITE (LevelArray[XPlace,YPlace]);
          END;                                   
     END;
END;

PROCEDURE FINISH_EDITING;
BEGIN
          DRAW_OUT_CUSTOM_GRID;
          WRITE_CONTROLS_TEXT;
          POSITION_OBJECTS;
END;

{writes the specified char to the screen and the array}
PROCEDURE WRITE_LEVEL_CHAR(SentX : INTEGER; SentY: INTEGER; SentChar : CHAR);
BEGIN
     GOTOXY(SentX, SentY);
     WRITE(SentChar);
     LevelArray[SentX,SentY]:=SentChar;
     GOTOXY(SentX, SentY);
END;

{returns TRUE if the provided co-ordinates contain an enemy, checks all enemies on stack}
FUNCTION ENEMY_HERE(SentX, SentY : INTEGER) : BOOLEAN;
VAR CurrentEnemy : NodePtr;
    EnemyFound : BOOLEAN;
BEGIN
     CurrentEnemy := EnemyStack;
     EnemyFound := FALSE;

     WHILE (CurrentEnemy <> NIL) AND (EnemyFound = FALSE) DO
     BEGIN
          IF ((CurrentEnemy^.X = SentX) AND (CurrentEnemy^.Y = SentY)) THEN
          BEGIN
               EnemyFound := TRUE;
          END;
          CurrentEnemy := CurrentEnemy^.Next;
     END;

     ENEMY_HERE := EnemyFound;
END;

{returns TRUE if the provided co-ordinates contain an enemy, player or cherry}
FUNCTION OBJECT_HERE(SentX, SentY : INTEGER) : BOOLEAN;
BEGIN
     IF ((XPositionOfPlayer=SentX) AND (YPositionOfPlayer=SentY))
     OR (ENEMY_HERE(SentX, SentY)) OR
     ((XPositionOfCherry=SentX) AND (YPositionOfCherry=SentY)) THEN
     BEGIN
          OBJECT_HERE := TRUE;
     END
     ELSE
     BEGIN
          OBJECT_HERE := FALSE;
     END;
END;


{moves the level edit caret by XChange in the X Direction and YChange in the Y Direction
Negative numbers used for up / left
Returns true if able to move (i.e. not trying to move outside area), else false}
FUNCTION LEVEL_POS_CHANGE(XChange: INTEGER; YChange: INTEGER; PaintWall : BOOLEAN) : BOOLEAN;
BEGIN
     IF (CursorPosX+XChange > 1) AND (CursorPosX+XChange < 40) AND
        (CursorPosY+YChange > 1) AND (CursorPosY+YChange < 15) THEN
     BEGIN
          GOTOXY (CursorPosX, CursorPosY);
          WRITE (LevelArray[CursorPosX, CursorPosY]);
          CursorPosX:=CursorPosX+XChange;
          CursorPosY:=CursorPosY+YChange;
          GOTOXY (CursorPosX, CursorPosY);

          {Are we wall-painting?}
          IF (PaintWall = TRUE) THEN
          BEGIN
               IF (OBJECT_HERE(CursorPosX, CursorPosY) = FALSE) THEN
               BEGIN
                    WRITE_LEVEL_CHAR(CursorPosX, CursorPosY, WallCharacter);
               END;
          END;

          WRITE (LevelEditCaret);
          POSITION_OBJECTS;
          LEVEL_POS_CHANGE:=TRUE;
     END
     ELSE LEVEL_POS_CHANGE:=FALSE;
END;

PROCEDURE TOGGLE_WALLS;
BEGIN
     {Check we're not trying to overwrite an object}
     IF (OBJECT_HERE(CursorPosX, CursorPosY) = FALSE) THEN
     BEGIN
          {Overwrite the "level saved" message, if it's there, as we've made a change}
          GOTOXY(1, 24);
          WRITE('               ');

          {draw wall or dot?}
          IF LevelArray[CursorPosX,CursorPosY]=WallCharacter THEN
          BEGIN
               WRITE_LEVEL_CHAR(CursorPosX, CursorPosY, '.');
          END
          ELSE
          BEGIN
               WRITE_LEVEL_CHAR(CursorPosX, CursorPosY, WallCharacter);
          END;
     END;
END;

{removes the enemy from the provided location by deleting the relevent stack entry}
{if more than one enemy is there (e.g. during gameplay), all will be removed}
PROCEDURE REMOVE_ENEMY(EnemyPosX : INTEGER; EnemyPosY : INTEGER);
VAR NewStack : NodePtr;
BEGIN
     NewStack := NIL; {error when enemy eaten without this line!}
     WHILE (EnemyStack <> NIL) DO
     BEGIN
          {If not discarding, add to new stack}
          IF ((EnemyStack^.X <> EnemyPosX) OR (EnemyStack^.Y <> EnemyPosY)) THEN
          BEGIN
               NewStack := PUSH(NewStack, MAKE_NODE(EnemyStack^.X, EnemyStack^.Y));
          END;
          EnemyStack := POP(EnemyStack);
     END;
     EnemyStack := NewStack;
END;

{Used in level editing - places an enemy at the current cursor location,
or removes it if one's already there.}
PROCEDURE PLACE_ENEMIES;
BEGIN
     {are we removing an enemy rather than placing one?}
     IF (ENEMY_HERE(CursorPosX, CursorPosY)) THEN
     BEGIN
          {Overwrite the "level saved" message, if it's there, as we've made a change}
          GOTOXY(1, 24);
          WRITE('               ');

          GOTOXY (CursorPosX,CursorPosY); {so it shows when you toggle an enemy on and off repeatedly in the same spot}
          WRITE (LevelArray[CursorPosX, CursorPosY]);
          REMOVE_ENEMY(CursorPosX, CursorPosY);
     END

     ELSE IF ((XPositionOfPlayer<>CursorPosX) OR (YPositionOfPlayer<>CursorPosY))
     AND ((XPositionOfCherry<>CursorPosX) OR (YPositionOfCherry<>CursorPosY))
     AND (LevelArray[CursorPosX,CursorPosY]<>WallCharacter) THEN
     BEGIN
          {Overwrite the "level saved" message, if it's there, as we've made a change}
          GOTOXY(1, 24);
          WRITE('               ');

          GOTOXY (CursorPosX, CursorPosY);
          WRITE (EnemyCharacter);

          EnemyStack := PUSH(EnemyStack, MAKE_NODE(CursorPosX, CursorPosY));
     END;

END;

PROCEDURE PLACE_PLAYER;
BEGIN
     IF (LevelArray[CursorPosX, CursorPosY]<>WallCharacter)
     AND ((XPositionOfCherry<>CursorPosX) OR (YPositionOfCherry<>CursorPosY))
     AND (NOT (ENEMY_HERE(CursorPosX, CursorPosY))) THEN
     BEGIN
          {Overwrite the "level saved" message, if it's there, as we've made a change}
          GOTOXY(1, 24);
          WRITE('               ');

          IF XPositionOfPlayer<>99 THEN {overwrite the old player character}
          BEGIN
               GOTOXY (XPositionOfPlayer, YPositionOfPlayer);
               WRITE (LevelArray[XPositionOfPlayer, YPositionOfPlayer]);
          END;
          GOTOXY (CursorPosX, CursorPosY);
          WRITE (PlayerCharacter);
          XPositionOfPlayer:=CursorPosX;
          YPositionOfPlayer:=CursorPosY;
     END;
END;

PROCEDURE PLACE_CHERRY;
BEGIN
     {Remove the cherry or place it?}
     IF (XPositionOfCherry=CursorPosX) AND (YPositionOfCherry=CursorPosY) THEN {remove the cherry}
     BEGIN
          {Overwrite the "level saved" message, if it's there, as we've made a change}
          GOTOXY(1, 24);
          WRITE('               ');

          GOTOXY (CursorPosX,CursorPosY); {so it shows when you toggle the cherry on and off repeatedly in the same spot}
          WRITE (LevelArray[CursorPosX, CursorPosY]);
          XPositionOfCherry:=99;
          YPositionOfCherry:=99;
     END

     ELSE IF (LevelArray[CursorPosX, CursorPosY]<>WallCharacter) AND
     ((XPositionOfPlayer<>CursorPosX) OR (YPositionOfPlayer<>CursorPosY))
     AND (NOT (ENEMY_HERE(CursorPosX, CursorPosY))) THEN
     BEGIN
          {Overwrite the "level saved" message, if it's there, as we've made a change}
          GOTOXY(1, 24);
          WRITE('               ');

          IF XPositionOfCherry<>99 THEN {overwrite the old cherry character}
          BEGIN
               GOTOXY (XPositionOfCherry,YPositionOfCherry);
               WRITE (LevelArray[XPositionOfCherry, YPositionOfCherry]);
          END;
          GOTOXY (CursorPosX,CursorPosY);
          WRITE (CherryCharacter);
          XPositionOfCherry:=CursorPosX;
          YPositionOfCherry:=CursorPosY;
     END;

END;

PROCEDURE SAVE_LEVEL_TO_EDIT;

VAR LevelToSave : STRING[8];
    LinesDrawnX : INTEGER;
    LinesDrawnY : INTEGER;

    LevelFile : FILE OF LevelDetails;
    LevelRecord : LevelDetails;

    CurrentEnemy : NodePtr; {used for cycling through the stack}


BEGIN
     GOTOXY(1,20);
     WRITE ('Save Level (without extension; max 8 chars; "?" cancels): ');
     READLN (LevelToSave);

     IF (LevelToSave[1] <> '?') THEN
     BEGIN
          ASSIGN (LevelFile, Path+LevelToSave+'.dat');
          REWRITE (LevelFile); 
          FOR LinesDrawnX:=1 TO 40 DO
          BEGIN
               FOR LinesDrawnY:=1 TO 15 DO
               BEGIN
                    LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY]:=LevelArray[LinesDrawnX, LinesDrawnY];
               END;
          END;

          {Save position of objects}
          IF (XPositionOfPlayer <> 99) AND (YPositionOfPlayer <> 99) THEN
          BEGIN
               LevelRecord.LevelArray[XPositionOfPlayer, YPositionOfPlayer] := PlayerCharacter;
          END;

          CurrentEnemy := EnemyStack;

          WHILE (CurrentEnemy <> NIL) DO
          BEGIN
               LevelRecord.LevelArray[CurrentEnemy^.X, CurrentEnemy^.Y] := EnemyCharacter;
               CurrentEnemy := CurrentEnemy^.Next;
          END;

          IF (XPositionOfCherry <> 99) AND (YPositionOfCherry <> 99) THEN
          BEGIN
               LevelRecord.LevelArray[XPositionOfCherry, YPositionOfCherry] := CherryCharacter;
          END;

          WRITE (LevelFile, LevelRecord);
          CLOSE (LevelFile);

          GOTOXY(1, 24);
          WRITE('<<Level Saved>>');
     END;

     {overwrite the save level text with spaces and return the cursor to its correct place for editing}
     GOTOXY(1,20);
     WRITE ('                                                                                         ');
     GOTOXY (CursorPosX, CursorPosY);
     WRITE(LevelEditCaret);
END;


PROCEDURE LOAD_LEVEL_TO_EDIT;

VAR LevelToLoad : STRING[8];
    FileExists : BOOLEAN;
    LinesDrawnX : INTEGER;
    LinesDrawnY : INTEGER;
    WriteSpacesLoop : INTEGER;

    LevelFile : FILE OF LevelDetails;
    LevelRecord : LevelDetails;


BEGIN
     REPEAT
           GOTOXY(1,20);
           WRITE ('Load Level (without extension; max 8 chars; "?" to cancel): ');
           READLN (LevelToLoad);

           IF (LevelToLoad[1] <> '?') THEN
           BEGIN
                ASSIGN (LevelFile, Path+LevelToLoad+'.dat');
                {$I-} {this code disables error checking so the program won't crash if the file doesn't exist}
                RESET (LevelFile);
                IF IOresult<>0 THEN
                BEGIN
                     GOTOXY(24, 20);
                     FOR WriteSpacesLoop:=1 TO 200 DO
                     BEGIN
                          WRITE (' ');
                     END;
                     GOTOXY (1, 22);
                     WRITE ('File not found.  Please enter another file name');
                     FileExists:=FALSE;
                END
                ELSE IF IOresult=0 THEN
                BEGIN
                     FileExists:=TRUE;
                END;
                {$I+} {re-enable error-checking}
           END
           ELSE
           BEGIN
                FileExists := TRUE; {to break out of loop}
           END;
     UNTIL FileExists=TRUE;

     {overwrite "not exists" text if it's there}
     GOTOXY (1, 22);
     WRITE ('                                               ');


     IF (LevelToLoad[1] <> '?') THEN
     BEGIN

          {Objects not yet placed}
          XPositionOfPlayer:=99;
          YPositionOfPlayer:=99;

          XPositionOfCherry:=99;
          YPositionOfCherry:=99;

          EnemyStack:=CLEAR(EnemyStack);

          {draw out the newly loaded level}
          READ (LevelFile, LevelRecord);
          FOR LinesDrawnX:=1 TO 40 DO
          BEGIN
               FOR LinesDrawnY:=1 TO 15 DO
               BEGIN
                    IF (LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY] = PlayerCharacter) THEN
                    BEGIN
                         LevelArray[LinesDrawnX, LinesDrawnY]:='.';
                         GOTOXY (LinesDrawnX, LinesDrawnY);
                         WRITE (PlayerCharacter);

                         {Set Player Position}
                         XPositionOfPlayer := LinesDrawnX;
                         YPositionOfPlayer := LinesDrawnY;
                    END
                    ELSE IF (LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY] = CherryCharacter) THEN
                    BEGIN
                         LevelArray[LinesDrawnX, LinesDrawnY]:='.';
                         GOTOXY (LinesDrawnX, LinesDrawnY);
                         WRITE (CherryCharacter);

                         {Set Cherry Position}
                         XPositionOfCherry := LinesDrawnX;
                         YPositionOfCherry := LinesDrawnY;
                    END
                    ELSE IF (LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY] = EnemyCharacter) THEN
                    BEGIN
                         LevelArray[LinesDrawnX, LinesDrawnY]:='.';
                         GOTOXY (LinesDrawnX, LinesDrawnY);
                         WRITE (EnemyCharacter);

                         {Set Enemy Position}
                         EnemyStack := PUSH(EnemyStack, MAKE_NODE(LinesDrawnX, LinesDrawnY));
                         {XPositionOfEnemy := LinesDrawnX;
                         YPositionOfEnemy := LinesDrawnY;}
                    END
                    ELSE
                    BEGIN
                         LevelArray[LinesDrawnX, LinesDrawnY]:=LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY];
                         GOTOXY (LinesDrawnX, LinesDrawnY);
                         WRITE (LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY]);
                    END;
               END;
          END;

          CLOSE (LevelFile);

     END;

     {overwrite the load level text with spaces and return the cursor to its correct place for editing}
     GOTOXY(1,20);
     WRITE ('                                                                                         ');

     GOTOXY (CursorPosX, CursorPosY);
     WRITE(LevelEditCaret);
END;

{Change the directory where levels are saved to / loaded from}
PROCEDURE CHANGE_PATH;

VAR PathExists : BOOLEAN;
    WriteSpacesLoop : INTEGER;

BEGIN
     REPEAT
           GOTOXY(1,20);
           WRITE ('Set Path ("?" cancels): ');
           READLN (Path);

           IF (Path[1] <> '?') THEN
           BEGIN
                {$I-} {this code disables error checking so the program won't crash if the path doesn't exist}
                IF Path[LENGTH(Path)]<>'\' THEN Path:=Path+'\'; {add  trailing '\'}
                ChDir (Path);
                IF IOresult<>0 THEN
                BEGIN
                     GOTOXY(1,20);
                     {this for loop clears the path input prompt and the current path message}
                     FOR WriteSpacesLoop:=1 TO 420 DO
                     BEGIN
                          WRITE (' ');
                     END;
                     GOTOXY (1, 22);
                     WRITE ('Path not found.  Please enter another path');
                     PathExists:=FALSE;
                END
                ELSE IF IOresult=0 THEN
                BEGIN
                     GOTOXY (1, 22);
                     WRITE ('                                          ');
                     PathExists:=TRUE;
                END;
                {$I+}
           END
           ELSE
           BEGIN
                PathExists := TRUE; {to break out of loop}
           END
     UNTIL PathExists=TRUE;

     IF (Path[1] <> '?') THEN
     BEGIN
          GOTOXY (1,23);
          FOR WriteSpacesLoop:=1 TO 150 DO
          BEGIN
               WRITE (' ');
          END;
          GOTOXY (1,23);
          WRITE ('Current Path: ', Path);

     END;

     {overwrite the set path message and whatever they've typed}
     GOTOXY(1, 20);
     FOR WriteSpacesLoop:=1 TO 220 DO
     BEGIN
          WRITE (' ');
     END;

     GOTOXY (CursorPosX, CursorPosY);
     WRITE(LevelEditCaret);
END;

PROCEDURE LEVEL_EDITOR;
VAR UserInput : CHAR;
    LinesDrawnX : INTEGER;
    LinesDrawnY : INTEGER;
    WriteSpacesLoop : INTEGER;
    WallPainting : BOOLEAN;

BEGIN
     CLRSCR;
     LAY_BORDER_AND_GRID_OF_DOTS; {also writes to the array}

     {Objects not placed yet}
     EnemyStack:=CLEAR(EnemyStack);

     XPositionOfPlayer:=99;
     YPositionOfPlayer:=99;

     XPositionOfCherry:=99;
     YPositionOfCherry:=99;

     GOTOXY (43,2);
     WRITE ('PACMAN LEVEL EDITOR');
     GOTOXY (43,4);
     WRITE ('Use the PacMan direction keys:');
     GOTOXY (43,5);
     WRITE ('T: Up, G: Down, F: Left and H: Right.');
     GOTOXY (43,6);
     WRITE ('to move around the level and');
     GOTOXY (43,7);
     WRITE ('the [SPACEBAR] to lay/remove walls');
     GOTOXY (43, 8);
     WRITE ('(Z turns on wall-painting)');
     GOTOXY (43,10);
     WRITE ('P : Place the player.');
     GOTOXY (43,11);
     WRITE ('E : Place / remove an enemy.');
     GOTOXY (43,12);
     WRITE ('C : Place / remove the Cherry.');
     GOTOXY (43,14);
     WRITE ('L : Load Level');
     GOTOXY (43,15);
     WRITE ('S : Save Level');
     GOTOXY (43,16);
     WRITE ('A : Change Path');
     GOTOXY (43,18);
     WRITE ('Press Q to play the level.');

     GOTOXY (1,23);
     FOR WriteSpacesLoop:=1 TO 150 DO
     BEGIN
          WRITE (' ');
     END;
     GOTOXY (1,23);
     WRITE ('Current Path: ', Path);

     GOTOXY (2,2);
     CursorPosX := 2;
     CursorPosY := 2;
     WRITE(LevelEditCaret);

     WallPainting := FALSE; {by default, we just move around normally}

     REPEAT
     IF KeyPressed=TRUE THEN
     BEGIN
          UserInput:=ReadKey;

          CASE UPCASE(UserInput) OF

          'L' : LOAD_LEVEL_TO_EDIT;
          'S' : SAVE_LEVEL_TO_EDIT;
          'T' : LEVEL_POS_CHANGE(0, -1, WallPainting); {up}
          'G' : LEVEL_POS_CHANGE(0, 1, WallPainting); {down}
          'F' : LEVEL_POS_CHANGE(-1, 0, WallPainting); {left}
          'H' : LEVEL_POS_CHANGE(1, 0, WallPainting); {right}
          'E' : PLACE_ENEMIES;
          'P' : PLACE_PLAYER;
          'C' : PLACE_CHERRY;
          'A' : CHANGE_PATH;
          'Q' : IF XPositionOfPlayer<>99 THEN BEGIN FINISH_EDITING; EXIT; END;
          ' ' : TOGGLE_WALLS;
          'Z' :
                IF (WallPainting = TRUE) THEN
                BEGIN
                     WallPainting := FALSE; 
                END
                ELSE
                BEGIN
                     WallPainting := TRUE;
                     {We also want to draw a wall at the current location}
                     IF (OBJECT_HERE(CursorPosX, CursorPosY) = FALSE) THEN
                     BEGIN
                          WRITE_LEVEL_CHAR(CursorPosX, CursorPosY, WallCharacter);
                     END;
                END;
                {The user is prevented from laying objects when WallPainting is TRUE as the wall will
                have been laid at the cursor position before they get a chance to try and place an object!
                However, wall-toggling still works, which can make editing quicker.}
          END;

     END;
     UNTIL 2>3;

END;

PROCEDURE DELAY(NumberOfTicks : INTEGER);

VAR Timer : longint absolute $40:$6C;
{at this position is held the number of clock ticks since midnight.  18.2 ticks = 1 second}
    StartTime : LONGINT;

BEGIN
     StartTime:=Timer;
     WHILE Timer < StartTime + NumberOfTicks DO
     BEGIN
          IF Timer < StartTime THEN
          StartTime:=0;                  
     END;
END;

PROCEDURE INTRODUCTION;
VAR WriteToX : INTEGER;
    WriteToY : INTEGER;

CONST DelayTime = 1;
BEGIN
     CurrentDeadEndInteger:=MinInt+1;
     GotCherry:=FALSE;

     FOR WriteToX:=1 TO 40 DO
     BEGIN
          FOR WriteToY:=1 TO 15 DO
          BEGIN
               EnemyKnowledgeArray[WriteToX, WriteToY]:=MinInt; {smallest possible integer}
          END;
     END;

     CLRSCR;
     GOTOXY (5,8);
     WRITELN ('PPPPPPP    AAAAAAA   CCCCCCC          MM      MM  AAAAAAA  NNN      NN');
     GOTOXY (5,9);
     DELAY(DelayTime);
     WRITELN ('PPPPPPPP  AAAAAAAAA CCCCCCC           MMMM  MMMM AAAAAAAAA NNNN     NN');
     GOTOXY (5,10);
     DELAY(DelayTime);
     WRITELN ('PP     PP AA     AA CC                MM MMMM MM AA     AA NN NN    NN');
     GOTOXY (5,11);
     DELAY(DelayTime);
     WRITELN ('PP     PP AA     AA CC                MM  MM  MM AA     AA NN  NN   NN');
     GOTOXY (5,12);
     DELAY(DelayTime);
     WRITELN ('PPPPPPPP  AAAAAAAAA CC                MM  MM  MM AAAAAAAAA NN   NN  NN');
     GOTOXY (5,13);
     DELAY(DelayTime);
     WRITELN ('PP        AA     AA CC                MM      MM AA     AA NN    NN NN');
     DELAY(DelayTime);
     GOTOXY (5,14);
     WRITELN ('PP        AA     AA CCCCCCC           MM      MM AA     AA NN     NNNN');
     DELAY(DelayTime);
     GOTOXY (5,15);
     WRITELN ('PP        AA     AA  CCCCCCC          MM      MM AA     AA NN      NNN');

     GOTOXY (26,3);
     WRITE ('Please Maximize this window.');
     GOTOXY (32,18);
     WRITE ('Release 1.1');
     GOTOXY (26,20);
     WRITE ('Please select an option:');
     GOTOXY (26,22);
     WRITE ('P - Play Standard Level');
     GOTOXY (26,23);
     WRITE ('E - Edit Level');
     GOTOXY (26,24);
     WRITE ('A - About this program');
     GOTOXY (26,25);
     WRITE ('Q - Quit');
END;

PROCEDURE ABOUT_INFO;
BEGIN
     CLRSCR;
     GOTOXY (28, 3);
     WRITE ('ASCII PACMAN RELEASE 1.1');
     GOTOXY (1,5);
     WRITELN ('This version is Release 1.1.  Please report any bugs and comments to');
     WRITE ('samATsamsolutions.co.uk (replace AT with @)');
     GOTOXY (1,8);
     WRITELN ('This game was created because I wanted to see what could be done with Windows ');
     WRITELN ('Pascal and to do something fun with it.  I''ve carried on with it as it''s');
     WRITELN ('thrown up some interesting challenges, particularly regarding enemy movement.');
     WRITELN;
     WRITELN ('The AI in this release has been drastically improved.  See the website');
     WRITELN ('for details: http://www.samsolutions.co.uk/sam/pacman.php');
     WRITELN;
     WRITELN ('Control Pacman / the cursor using the following keys:');
     WRITELN ('T: Up, G: Down, F: Left and H: Right.');
     WRITELN;
     WRITELN ('You complete a level by removing all dots (.) from that level.  If an enemy ');
     WRITELN ('(' + EnemyCharacter + ') manages to touch you then it''s GAME OVER but once you have the cherry');
     WRITE ('(' + CherryCharacter + ') you can eat enemies (the enemies change to "' + EnemyEdibleCharacter + '" once you');
     WRITELN (' have the cherry).');
     WRITELN;
     WRITE ('Press RETURN to continue');
     READLN;
     INTRODUCTION; {so that the above text is rewritten}
END;

PROCEDURE YOU_WIN;
BEGIN
     CLRSCR;
     GOTOXY (35,12);
     WRITE ('YOU WIN!');
     GOTOXY (22,14);
     WRITE ('Press Return to return to the menu');
     WRITELN;
     WRITELN;
     READLN;
END;

FUNCTION HOW_MANY_DOTS : INTEGER;
VAR NumberOfDots : INTEGER;
    TestArrayPositionX:INTEGER;
    TestArrayPositionY:INTEGER;
BEGIN
     NumberOfDots:=0;
     FOR TestArrayPositionX:=1 TO 40 DO
     BEGIN
          FOR TestArrayPositionY:=1 TO 15 DO
          BEGIN
          IF LevelArray[TestArrayPositionX,TestArrayPositionY]='.' THEN NumberOfDots:=NumberOfDots+1;
          END;
     END;
     HOW_MANY_DOTS:=NumberOfDots;
END;

{Used to draw the standard level}
PROCEDURE DRAW_WALLS (LinesDrawnY: INTEGER; Gap1: INTEGER; Gap2: INTEGER; Gap3: INTEGER);
VAR LinesDrawnX : INTEGER;
BEGIN
     FOR LinesDrawnX:= 2 TO 40 DO
     BEGIN
          GOTOXY (LinesDrawnX, LinesDrawnY);
          IF (LinesDrawnX<> Gap1) AND (LinesDrawnX<> Gap2) AND
          (LinesDrawnX<> Gap3) AND (LinesDrawnX<> Gap1+1) AND (LinesDrawnX<> Gap2+1) AND (LinesDrawnX<> Gap3+1) THEN
          BEGIN
               WRITE (WallCharacter);
               LevelArray[LinesDrawnX, LinesDrawnY]:=WallCharacter;
          END;

          IF (LinesDrawnX= Gap1) OR (LinesDrawnX= Gap2) OR
          (LinesDrawnX= Gap3) OR (LinesDrawnX= Gap1+1) OR (LinesDrawnX= Gap2+1) OR (LinesDrawnX= Gap3+1) THEN
          BEGIN
               WRITE ('.');
               LevelArray[LinesDrawnX, LinesDrawnY]:='.';
          END;
          END;

END;

PROCEDURE DRAW_STANDARD_LEVEL;
BEGIN
     CLRSCR;

     LAY_BORDER_AND_GRID_OF_DOTS; {fills the screen and the level array with dots and the borders}

     DRAW_WALLS (3, 10, 36, 10);
     DRAW_WALLS (4, 10, 36, 10);

     DRAW_WALLS (6, 22, 22, 22);
     DRAW_WALLS (7, 22, 22, 22);

     DRAW_WALLS (9, 3, 14, 33);
     DRAW_WALLS (10, 3, 14, 33);

     DRAW_WALLS (12, 9, 29, 9);
     DRAW_WALLS (13, 9, 29, 9);

     WRITE_CONTROLS_TEXT;
END;

PROCEDURE GAME_OVER;
BEGIN
     CLRSCR;
     GOTOXY (35,12);
     WRITE ('GAME OVER!');
     GOTOXY (22,14);
     WRITE ('Press Return to return to the menu');
     WRITELN;
     WRITELN;
     READLN;
     EndedGame:=TRUE;
END;         

PROCEDURE GOT_CHERRY;
VAR BeepNumber:INTEGER;
BEGIN
     CherryTimer:=0; {not yet used but left in as will soon be used}
     MessageBeep(1); {see http://mech.math.msu.su/~vfnik/WinApi/m/messagebeep.html}
     GotCherry:=TRUE;
     
END;

PROCEDURE TEST_POSITION;
BEGIN
     IF (ENEMY_HERE(XPositionOfPlayer, YPositionOfPlayer)) THEN
     BEGIN
          IF (GotCherry=FALSE) THEN
          BEGIN
               GAME_OVER;
          END
          ELSE IF (GotCherry=TRUE) THEN
          BEGIN
               REMOVE_ENEMY(XPositionOfPlayer, YPositionOfPlayer);
               {write back in the player to get rid of the enemy symbol}
               GOTOXY(XPositionOfPlayer, YPositionOfPlayer);
               WRITE(PlayerCharacter);
          END
     END
     ELSE IF (XPositionOfPlayer=XPositionOfCherry) AND (YPositionOfPlayer=YPositionOfCherry) AND (GotCherry = FALSE) THEN
     BEGIN
          GOT_CHERRY;
     END;
END;

{moves the player by XChange in the X Direction and YChange in the Y Direction
Negative numbers used for up / left
Returns true if able to move (i.e. not blocked by a wall), else false}
FUNCTION PLAYER_POS_CHANGE(XChange: INTEGER; YChange: INTEGER) : BOOLEAN;
BEGIN
     IF LevelArray [XPositionOfPlayer+XChange, YPositionOfPlayer+YChange] <> (WallCharacter) THEN
     BEGIN
          GOTOXY (XPositionOfPlayer, YPositionOfPlayer);
          WRITE (' ');
          LevelArray [XPositionOfPlayer, YPositionOfPlayer]:=' ';
          GOTOXY (XPositionOfPlayer+XChange, YPositionOfPlayer+YChange);
          WRITE (PlayerCharacter);
          XPositionOfPlayer:=XPositionOfPlayer+XChange;
          YPositionOfPlayer:=YPositionOfPlayer+YChange;
          PLAYER_POS_CHANGE:=TRUE;
     END
     ELSE PLAYER_POS_CHANGE:=FALSE;
END;

{returns TRUE if the given point contains a block or is a MARKED tunnel} 
FUNCTION IS_BLOCKED_OR_TUNNEL(XPoint : INTEGER; YPoint : INTEGER) : BOOLEAN;
BEGIN
     IF ((LevelArray[XPoint, YPoint]<>WallCharacter)
     AND (EnemyKnowledgeArray[XPoint, YPoint]=MinInt)) THEN IS_BLOCKED_OR_TUNNEL:=FALSE
     ELSE IS_BLOCKED_OR_TUNNEL:=TRUE

END;

{The function IN_TUNNEL was here.  However, with the new movement algorithm it is no longer required}

{moves the enemy contained in StackItem by XChange in the X Direction and YChange in the Y Direction
Negative numbers used for up / left}
PROCEDURE ENEMY_POS_CHANGE(XChange: INTEGER; YChange: INTEGER; StackItem: NodePtr);
BEGIN
     GOTOXY (StackItem^.X, StackItem^.Y);
     IF (XPositionOfCherry = StackItem^.X) AND (YPositionOfCherry = StackItem^.Y) AND (GotCherry = FALSE) THEN
     BEGIN
          WRITE (CherryCharacter);
     END
     ELSE WRITE(LevelArray[StackItem^.X, StackItem^.Y]);

     GOTOXY (StackItem^.X+XChange, StackItem^.Y+YChange);
     StackItem^.X:=StackItem^.X+XChange;
     StackItem^.Y:=StackItem^.Y+YChange;
     IF GotCherry=FALSE THEN WRITE (EnemyCharacter)
     ELSE IF GotCherry=TRUE THEN WRITE (EnemyEdibleCharacter);
END;

{returns the direction in which you should move from (StartX, StartY) to get to (EndX, EndY) quickest}
{OneX ... FourY are used for setting up the four stacks and thus control which directions are prioritised}
{Of NX and NY, one must be 0 as diagonals aren't allowed.  The other may be -1 or +1, nothing else will work right
as we only want to start our explore from one square away from the enemy}
FUNCTION FIND_PATH(StartX : INTEGER; StartY : INTEGER; EndX : INTEGER; EndY : INTEGER;
OneX : INTEGER; OneY : INTEGER; TwoX : INTEGER; TwoY : INTEGER; ThreeX : INTEGER; ThreeY : INTEGER;
FourX : INTEGER; FourY : INTEGER) : INTEGER;

VAR
   Stack1, Stack2, Stack3, Stack4 : NodePtr; {up, down, left, right}
   NewStack1, NewStack2, NewStack3, NewStack4 : NodePtr; {up, down, left, right}
   Finished : BOOLEAN;

   StacksActive : INTEGER; {used to determine when only one way is still moving and so we can stop, or when nothing is moving}
   CurrentStack : INTEGER; {used to determine which is the only moving stack if only one is moving}
   AddedToStacksActive : BOOLEAN;

   WinningStackNumber : INTEGER;

BEGIN

     {Set up stacks}
     IF LevelArray[StartX+OneX, StartY+OneY] <> WallCharacter THEN
     BEGIN
        Stack1 := MAKE_NODE(StartX+OneX, StartY+OneY);
     END
     ELSE
     BEGIN
         Stack1 := NIL;
     END;

     IF LevelArray[StartX+TwoX, StartY+TwoY] <> WallCharacter THEN
     BEGIN
        Stack2 := MAKE_NODE(StartX+TwoX, StartY+TwoY);
     END
     ELSE
     BEGIN
         Stack2 := NIL;
     END;

     IF LevelArray[StartX+ThreeX, StartY+ThreeY] <> WallCharacter THEN
     BEGIN
        Stack3 := MAKE_NODE(StartX+ThreeX, StartY+ThreeY);
     END
     ELSE
     BEGIN
        Stack3 := NIL;
     END;

     IF LevelArray[StartX+FourX, StartY+FourY] <> WallCharacter THEN
     BEGIN
        Stack4 := MAKE_NODE(StartX+FourX, StartY+FourY);
     END
     ELSE
     BEGIN
         Stack4 := NIL;
     END;

     NewStack1 := NIL;
     NewStack2 := NIL;
     NewStack3 := NIL;
     NewStack4 := NIL;

     Finished := FALSE;

     WHILE ((Finished = FALSE)) DO
     BEGIN


          {set up monitoring variables}
          CurrentStack := 0;
          StacksActive := 0;
          AddedToStacksActive := FALSE;


          {do stuff for each stack}

          {Stack1}

          WHILE ((Stack1 <> NIL) AND (Finished= FALSE)) DO
          BEGIN
               CurrentStack := 1;

               IF (AddedToStacksActive = FALSE) THEN
               BEGIN
                    StacksActive := StacksActive + 1;
                    AddedToStacksActive := TRUE;
               END;

               IF (Stack1^.X = EndX) AND (Stack1^.Y = EndY) THEN
               BEGIN
                    Stack1 := CLEAR(Stack1);
                    Stack2 := CLEAR(Stack2);
                    Stack3 := CLEAR(Stack3);
                    Stack4 := CLEAR(Stack4);
                    Finished := TRUE;
                    WinningStackNumber := 1; {set up return value}
               END;


               {try all directions}

               IF (Finished = FALSE) THEN
               BEGIN

                    IF ((LevelArray[Stack1^.X, Stack1^.Y-1] <> WallCharacter)
                    AND (VisitedArray[Stack1^.X, Stack1^.Y-1] = 0)
                    AND ((Stack1^.X <> StartX) OR (Stack1^.Y-1 <> StartY))) THEN
                    BEGIN
                         NewStack1 := PUSH(NewStack1, MAKE_NODE(Stack1^.X, Stack1^.Y-1));
                         VisitedArray[Stack1^.X, Stack1^.Y-1] := 1;
                    END;

                    IF ((LevelArray[Stack1^.X, Stack1^.Y+1] <> WallCharacter)
                    AND (VisitedArray[Stack1^.X, Stack1^.Y+1] = 0)
                    AND ((Stack1^.X <> StartX) OR (Stack1^.Y+1 <> StartY))) THEN
                    BEGIN
                         NewStack1 := PUSH(NewStack1, MAKE_NODE(Stack1^.X, Stack1^.Y+1));
                         VisitedArray[Stack1^.X, Stack1^.Y+1] := 1;
                    END;

                    IF ((LevelArray[Stack1^.X-1, Stack1^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack1^.X-1, Stack1^.Y] = 0)
                    AND ((Stack1^.X-1 <> StartX) OR (Stack1^.Y <> StartY))) THEN
                    BEGIN
                         NewStack1 := PUSH(NewStack1, MAKE_NODE(Stack1^.X-1, Stack1^.Y));
                         VisitedArray[Stack1^.X-1, Stack1^.Y] := 1;
                    END;

                    IF ((LevelArray[Stack1^.X+1, Stack1^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack1^.X+1, Stack1^.Y] = 0)
                    AND ((Stack1^.X+1 <> StartX) OR (Stack1^.Y <> StartY))) THEN
                    BEGIN
                         NewStack1 := PUSH(NewStack1, MAKE_NODE(Stack1^.X+1, Stack1^.Y));
                         VisitedArray[Stack1^.X+1, Stack1^.Y] := 1;
                    END;

                    Stack1 := POP(Stack1);

               END;
          END;

          Stack1 := NewStack1;
          NewStack1 := NIL;

          {Stack2}

          AddedToStacksActive := FALSE;

          WHILE ((Stack2 <> NIL) AND (Finished= FALSE)) DO
          BEGIN
               CurrentStack := 2;

               IF (AddedToStacksActive = FALSE) THEN
               BEGIN
                    StacksActive := StacksActive + 1;
                    AddedToStacksActive := TRUE;
               END;


               IF (Stack2^.X = EndX) AND (Stack2^.Y = EndY) THEN
               BEGIN
                    Stack1 := CLEAR(Stack1);
                    Stack2 := CLEAR(Stack2);
                    Stack3 := CLEAR(Stack3);
                    Stack4 := CLEAR(Stack4);
                    Finished := TRUE;
                    WinningStackNumber := 2; {set up return value}
               END;


               {try all directions}

               IF (Finished = FALSE) THEN
               BEGIN

                    IF ((LevelArray[Stack2^.X, Stack2^.Y-1] <> WallCharacter)
                    AND (VisitedArray[Stack2^.X, Stack2^.Y-1] = 0)
                    AND ((Stack2^.X <> StartX) OR (Stack2^.Y-1 <> StartY))) THEN
                    BEGIN
                         NewStack2 := PUSH(NewStack2, MAKE_NODE(Stack2^.X, Stack2^.Y-1));
                         VisitedArray[Stack2^.X, Stack2^.Y-1] := 2;
                    END;

                    IF ((LevelArray[Stack2^.X, Stack2^.Y+1] <> WallCharacter)
                    AND (VisitedArray[Stack2^.X, Stack2^.Y+1] = 0)
                    AND ((Stack2^.X <> StartX) OR (Stack2^.Y+1 <> StartY))) THEN
                    BEGIN
                         NewStack2 := PUSH(NewStack2, MAKE_NODE(Stack2^.X, Stack2^.Y+1));
                         VisitedArray[Stack2^.X, Stack2^.Y+1] := 2;
                    END;

                    IF ((LevelArray[Stack2^.X-1, Stack2^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack2^.X-1, Stack2^.Y] = 0)
                    AND ((Stack2^.X-1 <> StartX) OR (Stack2^.Y <> StartY))) THEN
                    BEGIN
                         NewStack2 := PUSH(NewStack2, MAKE_NODE(Stack2^.X-1, Stack2^.Y));
                         VisitedArray[Stack2^.X-1, Stack2^.Y] := 2;
                    END;

                    IF ((LevelArray[Stack2^.X+1, Stack2^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack2^.X+1, Stack2^.Y] = 0)
                    AND ((Stack2^.X+1 <> StartX) OR (Stack2^.Y <> StartY))) THEN
                    BEGIN
                         NewStack2 := PUSH(NewStack2, MAKE_NODE(Stack2^.X+1, Stack2^.Y));
                         VisitedArray[Stack2^.X+1, Stack2^.Y] := 2;
                    END;

                    Stack2 := POP(Stack2);

               END;
          END;

          Stack2 := NewStack2;
          NewStack2 := NIL;

          {Stack3}

          AddedToStacksActive := FALSE;

          WHILE ((Stack3 <> NIL) AND (Finished= FALSE)) DO
          BEGIN
               CurrentStack := 3;

               IF (AddedToStacksActive = FALSE) THEN
               BEGIN
                    StacksActive := StacksActive + 1;
                    AddedToStacksActive := TRUE;
               END;


               IF (Stack3^.X = EndX) AND (Stack3^.Y = EndY) THEN
               BEGIN
                    Stack1 := CLEAR(Stack1);
                    Stack2 := CLEAR(Stack2);
                    Stack3 := CLEAR(Stack3);
                    Stack4 := CLEAR(Stack4);
                    Finished := TRUE;
                    WinningStackNumber := 3; {set up return value}
               END;


               {try all directions}

               IF (Finished = FALSE) THEN
               BEGIN

                    IF ((LevelArray[Stack3^.X, Stack3^.Y-1] <> WallCharacter)
                    AND (VisitedArray[Stack3^.X, Stack3^.Y-1] = 0)
                    AND ((Stack3^.X <> StartX) OR (Stack3^.Y-1 <> StartY))) THEN
                    BEGIN
                         NewStack3 := PUSH(NewStack3, MAKE_NODE(Stack3^.X, Stack3^.Y-1));
                         VisitedArray[Stack3^.X, Stack3^.Y-1] := 3;
                    END;

                    IF ((LevelArray[Stack3^.X, Stack3^.Y+1] <> WallCharacter)
                    AND (VisitedArray[Stack3^.X, Stack3^.Y+1] = 0)
                    AND ((Stack3^.X <> StartX) OR (Stack3^.Y+1 <> StartY))) THEN
                    BEGIN
                         NewStack3 := PUSH(NewStack3, MAKE_NODE(Stack3^.X, Stack3^.Y+1));
                         VisitedArray[Stack3^.X, Stack3^.Y+1] := 3;
                    END;

                    IF ((LevelArray[Stack3^.X-1, Stack3^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack3^.X-1, Stack3^.Y] = 0)
                    AND ((Stack3^.X-1 <> StartX) OR (Stack3^.Y <> StartY))) THEN
                    BEGIN
                         NewStack3 := PUSH(NewStack3, MAKE_NODE(Stack3^.X-1, Stack3^.Y));
                         VisitedArray[Stack3^.X-1, Stack3^.Y] := 3;
                    END;

                    IF ((LevelArray[Stack3^.X+1, Stack3^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack3^.X+1, Stack3^.Y] = 0)
                    AND ((Stack3^.X+1 <> StartX) OR (Stack3^.Y <> StartY))) THEN
                    BEGIN
                         NewStack3 := PUSH(NewStack3, MAKE_NODE(Stack3^.X+1, Stack3^.Y));
                         VisitedArray[Stack3^.X+1, Stack3^.Y] := 3;
                    END;

                    Stack3 := POP(Stack3);
               END;
          END;

          Stack3 := NewStack3;
          NewStack3 := NIL;

          {Stack4}

          AddedToStacksActive := FALSE;

          WHILE ((Stack4 <> NIL) AND (Finished = FALSE)) DO
          BEGIN
               CurrentStack := 4;

               IF (AddedToStacksActive = FALSE) THEN
               BEGIN
                    StacksActive := StacksActive + 1;
                    AddedToStacksActive := TRUE;
               END;


               IF (Stack4^.X = EndX) AND (Stack4^.Y = EndY) THEN
               BEGIN
                    Stack1 := CLEAR(Stack1);
                    Stack2 := CLEAR(Stack2);
                    Stack3 := CLEAR(Stack3);
                    Stack4 := CLEAR(Stack4);
                    Finished := TRUE;
                    WinningStackNumber := 4; {set up return value}
               END;

               {try all directions}

               IF (Finished = FALSE) THEN
               BEGIN

                    IF ((LevelArray[Stack4^.X, Stack4^.Y-1] <> WallCharacter)
                    AND (VisitedArray[Stack4^.X, Stack4^.Y-1] = 0)
                    AND ((Stack4^.X <> StartX) OR (Stack4^.Y-1 <> StartY))) THEN
                    BEGIN
                         NewStack4 := PUSH(NewStack4, MAKE_NODE(Stack4^.X, Stack4^.Y-1));
                         VisitedArray[Stack4^.X, Stack4^.Y-1] := 4;
                    END;

                    IF ((LevelArray[Stack4^.X, Stack4^.Y+1] <> WallCharacter)
                    AND (VisitedArray[Stack4^.X, Stack4^.Y+1] = 0)
                    AND ((Stack4^.X <> StartX) OR (Stack4^.Y+1 <> StartY))) THEN
                    BEGIN
                         NewStack4 := PUSH(NewStack4, MAKE_NODE(Stack4^.X, Stack4^.Y+1));
                         VisitedArray[Stack4^.X, Stack4^.Y+1] := 4;
                    END;

                    IF ((LevelArray[Stack4^.X-1, Stack4^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack4^.X-1, Stack4^.Y] = 0)
                    AND ((Stack4^.X-1 <> StartX) OR (Stack4^.Y <> StartY))) THEN
                    BEGIN
                         NewStack4 := PUSH(NewStack4, MAKE_NODE(Stack4^.X-1, Stack4^.Y));
                         VisitedArray[Stack4^.X-1, Stack4^.Y] := 4;
                    END;

                    IF ((LevelArray[Stack4^.X+1, Stack4^.Y] <> WallCharacter)
                    AND (VisitedArray[Stack4^.X+1, Stack4^.Y] = 0)
                    AND ((Stack4^.X+1 <> StartX) OR (Stack4^.Y <> StartY))) THEN
                    BEGIN
                         NewStack4 := PUSH(NewStack4, MAKE_NODE(Stack4^.X+1, Stack4^.Y));
                         VisitedArray[Stack4^.X+1, Stack4^.Y] := 4;
                    END;

                    Stack4 := POP(Stack4);

               END;

          END;

          Stack4 := NewStack4;
          NewStack4 := NIL;

          {optimisation}
          IF StacksActive < 2 THEN
          BEGIN
             Finished := TRUE;
             WinningStackNumber := CurrentStack;
          END;

          {returns 1 if should go up, 2 = down, 3 = left, 4 = right}
          {must therefore firgure out which stack is which direction as it's not necessarily stack 1 = up anymore
          because of the fact we can alter priorities}
          IF (WinningStackNumber = 1) THEN
          BEGIN
               IF (OneX = 1) THEN
               BEGIN
                    FIND_PATH := 4;
               END
               ELSE IF (OneX = -1) THEN
               BEGIN
                    FIND_PATH := 3;
               END
               ELSE IF (OneY = 1) THEN
               BEGIN
                    FIND_PATH := 2;
               END
               ELSE IF (OneY = -1) THEN
               BEGIN
                    FIND_PATH := 1;
               END
          END
          ELSE IF (WinningStackNumber = 2) THEN
          BEGIN
               IF (TwoX = 1) THEN
               BEGIN
                    FIND_PATH := 4;
               END
               ELSE IF (TwoX = -1) THEN
               BEGIN
                    FIND_PATH := 3;
               END
               ELSE IF (TwoY = 1) THEN
               BEGIN
                    FIND_PATH := 2;
               END
               ELSE IF (TwoY = -1) THEN
               BEGIN
                    FIND_PATH := 1;
               END
          END
          ELSE IF (WinningStackNumber = 3) THEN
          BEGIN
               IF (ThreeX = 1) THEN
               BEGIN
                    FIND_PATH := 4;
               END
               ELSE IF (ThreeX = -1) THEN
               BEGIN
                    FIND_PATH := 3;
               END
               ELSE IF (ThreeY = 1) THEN
               BEGIN
                    FIND_PATH := 2;
               END
               ELSE IF (ThreeY = -1) THEN
               BEGIN
                    FIND_PATH := 1;
               END
          END
          ELSE IF (WinningStackNumber = 4) THEN
          BEGIN
               IF (FourX = 1) THEN
               BEGIN
                    FIND_PATH := 4;
               END
               ELSE IF (FourX = -1) THEN
               BEGIN
                    FIND_PATH := 3;
               END
               ELSE IF (FourY = 1) THEN
               BEGIN
                    FIND_PATH := 2;
               END
               ELSE IF (FourY = -1) THEN
               BEGIN
                    FIND_PATH := 1;
               END
          END;



     END; {outer while loop}

END;

PROCEDURE CLEAR_VISITED;
VAR X, Y : INTEGER;
BEGIN
     FOR X := 1 TO 40 DO
     BEGIN
          FOR Y := 1 TO 15 DO
          BEGIN
               VisitedArray[X, Y] := 0;
          END;
     END;          
END;

PROCEDURE ENEMY_MOVEMENT;
VAR ReturnVal : INTEGER;
    CurrentEnemy : NodePtr;
    RandomNumber : INTEGER;
    PriorityArray : ARRAY [1..24] OF STRING[4]; {used in setting PrioritiesToSend}
    PrioritiesToSend : ARRAY [1..2, 1..4] OF INTEGER; {used in passing OneX ... FourY (see below)}
    CurrentPrioritySet : INTEGER;
    CurrentDirection : INTEGER;
BEGIN
     {set up array}
     PriorityArray[1] := 'UDLR';
     PriorityArray[5] := 'ULRD';
     PriorityArray[9] := 'URLD';
     PriorityArray[13] := 'UDRL';
     PriorityArray[17] := 'ULDR';
     PriorityArray[21] := 'URDL';

     PriorityArray[2] := 'DULR';
     PriorityArray[6] := 'DLRU';
     PriorityArray[10] := 'DRLU';
     PriorityArray[14] := 'DURL';
     PriorityArray[18] := 'DLUR';
     PriorityArray[22] := 'DRUL';

     PriorityArray[3] := 'LDUR';
     PriorityArray[7] := 'LURD';
     PriorityArray[11] := 'LRUD';
     PriorityArray[15] := 'LDRU';
     PriorityArray[19] := 'LUDR';
     PriorityArray[23] := 'LRDU';

     PriorityArray[4] := 'RULD';
     PriorityArray[8] := 'RDLU';
     PriorityArray[12] := 'RLUD';
     PriorityArray[16] := 'RDUL';
     PriorityArray[20] := 'RLDU';
     PriorityArray[24] := 'RUDL';

     CurrentPrioritySet := 0;

     {cycle through enemies}
     CurrentEnemy := EnemyStack;

     WHILE (CurrentEnemy <> NIL) DO
     BEGIN
          CLEAR_VISITED; {it's important that this is inside the while loop as otherwise all the enemies share it}
          ReturnVal := 0; {don't move}

          {set priority list}
          CurrentPrioritySet := CurrentPrioritySet + 1;
          IF (CurrentPrioritySet > 24) THEN
          BEGIN
               CurrentPrioritySet := 1;
          END;

          {Each enemy only moves 2/3rds of the time.}
          RandomNumber:=RANDOM(3);
          IF ((RandomNumber=0) OR (RandomNumber=1)) THEN
          BEGIN
               {set up priority values to pass}
               FOR CurrentDirection := 1 TO 4 DO
               BEGIN
                    CASE PriorityArray[CurrentPrioritySet][CurrentDirection] OF
                         'U' : BEGIN
                                    PrioritiesToSend[1][CurrentDirection] := 0;
                                    PrioritiesToSend[2][CurrentDirection] := -1;
                               END;
                         'D' : BEGIN
                                    PrioritiesToSend[1][CurrentDirection] := 0;
                                    PrioritiesToSend[2][CurrentDirection] := 1;
                               END;
                         'L' : BEGIN
                                    PrioritiesToSend[1][CurrentDirection] := -1;
                                    PrioritiesToSend[2][CurrentDirection] := 0;
                               END;
                         'R' : BEGIN
                                    PrioritiesToSend[1][CurrentDirection] := 1;
                                    PrioritiesToSend[2][CurrentDirection] := 0;
                               END;
                    END;
               END;

               ReturnVal := FIND_PATH(CurrentEnemy^.X, CurrentEnemy^.Y, XPositionOfPlayer, YPositionOfPlayer,
               PrioritiesToSend[1][1], PrioritiesToSend[2][1], PrioritiesToSend[1][2], PrioritiesToSend[2][2],
               PrioritiesToSend[1][3], PrioritiesToSend[2][3], PrioritiesToSend[1][4], PrioritiesToSend[2][4]);
          END;

          CASE ReturnVal OF
               1 : ENEMY_POS_CHANGE(0, -1, CurrentEnemy);
               2 : ENEMY_POS_CHANGE(0, 1, CurrentEnemy);
               3 : ENEMY_POS_CHANGE(-1, 0, CurrentEnemy);
               4 : ENEMY_POS_CHANGE(1, 0, CurrentEnemy);
          END;
     CurrentEnemy := CurrentEnemy^.Next;
     END;
END;

PROCEDURE SETUP_STANDARD_LEVEL;
BEGIN
     EnemyStack:=CLEAR(EnemyStack);
     EnemyStack:=PUSH(EnemyStack, MAKE_NODE(2, 2)); {add a single enemy}

     XPositionOfPlayer:=39;
     YPositionOfPlayer:=14;
     XPositionOfCherry:=38;
     YPositionOfCherry:=2;
END;

PROCEDURE MAIN_PROGRAM;
VAR UserInput : CHAR;
CONST GameSpeed = 2; {lower number = faster.  Must be an integer}
BEGIN
     EndedGame:=FALSE;
     WHILE EndedGame=FALSE DO
     BEGIN
          IF HOW_MANY_DOTS = 0 THEN
          BEGIN
               YOU_WIN;
               EndedGame:=TRUE;
          END;
          GOTOXY (2, 23);
          DELAY(GameSpeed);
          IF KeyPressed=TRUE THEN
          BEGIN
               UserInput:=ReadKey;

               CASE UPCASE(UserInput) OF

               'T' : PLAYER_POS_CHANGE(0, -1); {up}
               'G' : PLAYER_POS_CHANGE(0, 1); {down}
               'F' : PLAYER_POS_CHANGE(-1, 0); {left}       
               'H' : PLAYER_POS_CHANGE(1, 0); {right}
               'Q' : EndedGame := TRUE; {quit}

               ELSE
                   BEGIN
                        ENEMY_MOVEMENT;
                   END;
               END;

               TEST_POSITION;
               ENEMY_MOVEMENT;
               TEST_POSITION;
          END

          ELSE
          BEGIN
               ENEMY_MOVEMENT;
               TEST_POSITION;
          END;
     END; {end while}

     EnemyStack := CLEAR(EnemyStack);

     {WHILE (EnemyStack <> NIL) DO
     BEGIN
          EnemyStack := POP(EnemyStack);
     END;}
END;

{Loops until the user chooses an option from the main menu}
PROCEDURE MENU_LOOP;
VAR   IsOptionChosen : BOOLEAN;
      OptionChosen : CHAR;

BEGIN
     CurrentDeadEndInteger:=MinInt+1;
     AddedToCurrentDeadEndInteger:=TRUE;
     INTRODUCTION;
     REPEAT
           GOTOXY (50, 20);

           READLN (OptionChosen);
           IF (UPCASE(OptionChosen)='P') THEN
           BEGIN
                IsOptionChosen:=TRUE;
                SETUP_STANDARD_LEVEL;
                DRAW_STANDARD_LEVEL;
                POSITION_OBJECTS;
           END

           ELSE IF (UPCASE(OptionChosen)='E') THEN
           BEGIN
                IsOptionChosen:=TRUE;
                LEVEL_EDITOR;
           END

           ELSE IF (UPCASE(OptionChosen)='A') THEN
           BEGIN
                ABOUT_INFO;
                IsOptionChosen:=FALSE;
           END

           ELSE IF (UPCASE(OptionChosen)='Q') THEN
           BEGIN
                DONEWINCRT;
           END

           ELSE
           BEGIN
                IsOptionChosen:=FALSE;
                GOTOXY (50, 20);
                WRITE('                               '); {30 spaces reaches to end of screen}
           END;

     UNTIL IsOptionChosen=TRUE;

     IsOptionChosen:=FALSE;
     MAIN_PROGRAM;
END;


{The actual program is below}

BEGIN
     RANDOMIZE; {should only be called once.  See http://www.merlyn.demon.co.uk/pas-rand.htm.}
     Path:= 'c:\programming\pascal\windows\programs\pacman\levels\';
     StrCopy(WindowTitle, 'ASCII PACMAN RELEASE 1.1');

     CLRSCR;
     GOTOXY (23,11);
     WRITE ('Please Maximize this window.');
     READLN;
     WHILE 2<3 DO
     BEGIN
          MENU_LOOP;
     END;
END.