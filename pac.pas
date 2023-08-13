{
This file was based on finished release 1.0.  However, I have now gone through it making various improvements (see below).
It has been "released" as release 1.0a

In time, I will hopefully get the AI from routec.pas working and include it.
}


{
bugs:
=====
no beep produced when cherry eaten (problem with messagebeep call)

improvements done (not a comprehensive list):
==============================================
The method for checking whether in a tunnel has been radically shortened (BIG CHANGE)
EnemyKnowledgeArray now of integers not char (note that -MaxInt-1 is the smallest int, MaxInt is the biggest)
when playing standard level, player now shown on screen even before you start moving
cherry now redrawn when enemy moves over it
stuff level editor cursor moves over is correctly redrawn
now displays the controls on the right when playing a level from the editor
toggling of enemy or cherry looks right in the editor (before the display didn't update correctly)
DELAY procedure improved
various procedures and variables now have more sensible names, and some useful constants added
a few bits of on-screen text modified
}

PROGRAM Pacman;

USES WINCRT, WINPROCS, STRINGS, WINDOS;

CONST
     MinInt = -MaxInt-1; {smallest possible int}

     {various characters}
     LevelEditCaret = '_';
     PlayerCharacter = 'C';
     EnemyCharacter = 'ß';
     EnemyEdibleCharacter = '$';
     CherryCharacter = '∂';
     WallCharacter = 'É'; {setting this to '.' is likely to cause major issues!}

TYPE
    LevelDetails = RECORD
    LevelArray : ARRAY [1..40, 1..15] OF CHAR;
    XEnemy : INTEGER;
    YEnemy : INTEGER;
    XCharacter : INTEGER;
    YCharacter : INTEGER;
    XCherry : INTEGER;
    YCherry : INTEGER;
END;

VAR
   EndedGame : BOOLEAN; {Set when win or lose, checked by the game loop}

   LevelArray : ARRAY [1..40, 1..15] OF CHAR;

   XPositionOfPlayer: INTEGER; {99 used to indicate a non-placed player; was called XPositionOfPlayer}
   YPositionOfPlayer: INTEGER; {was called YPositionOfPlayer}
   XPositionOfEnemy: INTEGER; {99 used to indicate a non-placed or dead enemy}
   YPositionOfEnemy: INTEGER;
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

PROCEDURE POSITION_OBJECTS;
BEGIN
     {This check added in so that we can call this procedure during level editing}
     IF XPositionOfPlayer<>99 THEN
     BEGIN
          GOTOXY (XPositionOfPlayer,YPositionOfPlayer);
          WRITE (PlayerCharacter);
     END;

     IF XPositionOfEnemy<>99 THEN
     BEGIN
          GOTOXY (XPositionOfEnemy, YPositionOfEnemy);
          WRITE (EnemyCharacter);
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
     WRITE ('Welcome to Pac Man.');
     GOTOXY (42, 3);
     WRITE ('Control Pac Man using the');
     GOTOXY (42, 4);
     WRITE ('following keys:');
     GOTOXY (42, 6);
     WRITE ('T: Up, G: Down, F: Left and H: Right.');
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

{moves the level edit caret by XChange in the X Direction and YChange in the Y Direction
Negative numbers used for up / left
Returns true if able to move (i.e. not trying to move outside area), else false}
FUNCTION LEVEL_POS_CHANGE(XChange: INTEGER; YChange: INTEGER) : BOOLEAN;
BEGIN
     IF (CursorPosX+XChange > 1) AND (CursorPosX+XChange < 40) AND
        (CursorPosY+YChange > 1) AND (CursorPosY+YChange < 15) THEN
     BEGIN
          GOTOXY (CursorPosX, CursorPosY);
          WRITE (LevelArray[CursorPosX, CursorPosY]);
          CursorPosX:=CursorPosX+XChange;
          CursorPosY:=CursorPosY+YChange;
          GOTOXY (CursorPosX, CursorPosY);
          WRITE (LevelEditCaret);
          POSITION_OBJECTS;
          LEVEL_POS_CHANGE:=TRUE;
     END
     ELSE LEVEL_POS_CHANGE:=FALSE;
END;

PROCEDURE TOGGLE_WALLS;
BEGIN
     {Check we're not trying to overwrite an object}
     IF ((XPositionOfPlayer<>CursorPosX) OR (YPositionOfPlayer<>CursorPosY))
     AND ((XPositionOfEnemy<>CursorPosX) OR (YPositionOfEnemy<>CursorPosY)) AND
     ((XPositionOfCherry<>CursorPosX) OR (YPositionOfCherry<>CursorPosY)) THEN

     BEGIN
          {draw wall or dot?}
          IF LevelArray[CursorPosX,CursorPosY]=WallCharacter THEN
          BEGIN
               GOTOXY (CursorPosX,CursorPosY);
               WRITE ('.');
               LevelArray[CursorPosX,CursorPosY]:='.';
               GOTOXY (CursorPosX,CursorPosY);
          END
          ELSE
          BEGIN
               GOTOXY (CursorPosX,CursorPosY);
               WRITE (WallCharacter);
               LevelArray[CursorPosX,CursorPosY]:=WallCharacter;
               GOTOXY (CursorPosX,CursorPosY);
          END;
     END;
END;

{
Used in level editing - places the enemy at the current cursor location,
or removes him if he's already there.

Although it says enemIES, we can only place one at present
}
PROCEDURE PLACE_ENEMIES;
BEGIN
     {are we removing an enemy rather than placing one?}
     IF (XPositionOfEnemy=CursorPosX) AND (YPositionOfEnemy=CursorPosY) THEN
     BEGIN
          GOTOXY (CursorPosX,CursorPosY); {so it shows when you toggle the enemy on and off repeatedly in the same spot}
          WRITE (LevelArray[CursorPosX, CursorPosY]);
          XPositionOfEnemy:=99;
          YPositionOfEnemy:=99;
     END

     ELSE IF ((XPositionOfPlayer<>CursorPosX) OR (YPositionOfPlayer<>CursorPosY))
     AND ((XPositionOfCherry<>CursorPosX) OR (YPositionOfCherry<>CursorPosY))
     AND (LevelArray[CursorPosX,CursorPosY]<>WallCharacter) THEN
     BEGIN
          IF XPositionOfEnemy<>99 THEN {since we can only place one, go and overwrite the existing one}
          BEGIN
               GOTOXY (XPositionOfEnemy, YPositionOfEnemy);
               WRITE (LevelArray[XPositionOfEnemy, YPositionOfEnemy]);
          END;
          GOTOXY (CursorPosX, CursorPosY);
          WRITE (EnemyCharacter);
          XPositionOfEnemy:=CursorPosX;
          YPositionOfEnemy:=CursorPosY;
     END;

END;

PROCEDURE PLACE_PLAYER;
BEGIN
     IF (LevelArray[CursorPosX, CursorPosY]<>WallCharacter)
     AND ((XPositionOfCherry<>CursorPosX) OR (YPositionOfCherry<>CursorPosY))
     AND ((XPositionOfEnemy<>CursorPosX) OR (YPositionOfEnemy<>CursorPosY)) THEN
     BEGIN
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
          GOTOXY (CursorPosX,CursorPosY); {so it shows when you toggle the cherry on and off repeatedly in the same spot}
          WRITE (LevelArray[CursorPosX, CursorPosY]);
          XPositionOfCherry:=99;
          YPositionOfCherry:=99;
     END

     ELSE IF (LevelArray[CursorPosX, CursorPosY]<>WallCharacter) AND
     ((XPositionOfPlayer<>CursorPosX) OR (YPositionOfPlayer<>CursorPosY))
     AND ((XPositionOfEnemy<>CursorPosX) OR (YPositionOfEnemy<>CursorPosY)) THEN
     BEGIN
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


BEGIN
     GOTOXY(1,20);
     WRITE ('Save Level (without extension; max 8 chars): ');
     READLN (LevelToSave);
     ASSIGN (LevelFile, Path+LevelToSave+'.dat');
     REWRITE (LevelFile); 
     FOR LinesDrawnX:=1 TO 40 DO
     BEGIN
          FOR LinesDrawnY:=1 TO 15 DO
          BEGIN
               LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY]:=LevelArray[LinesDrawnX, LinesDrawnY];
          END;
     END;
     LevelRecord.XEnemy:=XPositionOfEnemy;
     LevelRecord.YEnemy:=YPositionOfEnemy;
     LevelRecord.XCharacter:=XPositionOfPlayer;
     LevelRecord.YCharacter:=YPositionOfPlayer;
     LevelRecord.XCherry:=XPositionOfCherry;
     LevelRecord.YCherry:=YPositionOfCherry;
     WRITE (LevelFile, LevelRecord);
     CLOSE (LevelFile);
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
           WRITE ('Load Level (without extension; max 8 chars): ');
           READLN (LevelToLoad);
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
                GOTOXY (1, 22);
                WRITE ('                                               ');
                FileExists:=TRUE;
           END;
           {$I+}
     UNTIL FileExists=TRUE;

     {draw out the newly loaded level}
     READ (LevelFile, LevelRecord);
     FOR LinesDrawnX:=1 TO 40 DO
     BEGIN
          FOR LinesDrawnY:=1 TO 15 DO
          BEGIN
               LevelArray[LinesDrawnX, LinesDrawnY]:=LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY];
               GOTOXY (LinesDrawnX, LinesDrawnY);
               WRITE (LevelRecord.LevelArray[LinesDrawnX, LinesDrawnY]);
          END;
     END;
     XPositionOfEnemy:=LevelRecord.XEnemy;
     YPositionOfEnemy:=LevelRecord.YEnemy;
     IF XPositionOfEnemy<>99 THEN
     BEGIN
          GOTOXY(XPositionOfEnemy, YPositionOfEnemy);
          WRITE (EnemyCharacter);
     END;

     XPositionOfPlayer:=LevelRecord.XCharacter;
     YPositionOfPlayer:=LevelRecord.YCharacter;
     IF XPositionOfPlayer<>99 THEN
     BEGIN
          GOTOXY(XPositionOfPlayer, YPositionOfPlayer);
          WRITE (PlayerCharacter);
     END;

     XPositionOfCherry:=LevelRecord.XCherry;
     YPositionOfCherry:=LevelRecord.YCherry;
     IF XPositionOfCherry<>99 THEN
     BEGIN
          GOTOXY(XPositionOfCherry, YPositionOfCherry);
          WRITE (CherryCharacter);
     END;

     CLOSE (LevelFile);
     {overwrite the load level text with spaces and return the cursor to its correct place for editing}
     GOTOXY(1,20);
     WRITE ('                                                                                         ');
     GOTOXY (CursorPosX, CursorPosY);
     WRITE(LevelEditCaret);
END;

PROCEDURE CHANGE_PATH;

VAR PathExists : BOOLEAN;
    WriteSpacesLoop : INTEGER;

BEGIN
     REPEAT
           GOTOXY(1,20);
           WRITE ('Set Path: ');
           READLN (Path);
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
     UNTIL PathExists=TRUE;

     GOTOXY (1,23);
     FOR WriteSpacesLoop:=1 TO 150 DO
     BEGIN
          WRITE (' ');
     END;
     GOTOXY (1,23);
     WRITE ('Current Path: ', Path);
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

BEGIN
     CLRSCR;
     LAY_BORDER_AND_GRID_OF_DOTS; {also writes to the array}

     XPositionOfEnemy:=99;
     YPositionOfEnemy:=99;
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
     GOTOXY (43,9);
     WRITE ('P : Place the player.');
     GOTOXY (43,10);
     WRITE ('E : Place / remove the enemy.');
     GOTOXY (43,11);
     WRITE ('C : Place / remove the Cherry.');
     GOTOXY (43,13);
     WRITE ('L : Load Level');
     GOTOXY (43,14);
     WRITE ('S : Save Level');
     GOTOXY (43,15);
     WRITE ('A : Change Path');
     GOTOXY (43,17);
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

     REPEAT
     IF KeyPressed=TRUE THEN
     BEGIN
          UserInput:=ReadKey;

          CASE UPCASE(UserInput) OF

          'L' : LOAD_LEVEL_TO_EDIT;
          'S' : SAVE_LEVEL_TO_EDIT;
          'T' : LEVEL_POS_CHANGE(0, -1); {up}
          'G' : LEVEL_POS_CHANGE(0, 1); {down}
          'F' : LEVEL_POS_CHANGE(-1, 0); {left}
          'H' : LEVEL_POS_CHANGE(1, 0); {right}
          'E' : PLACE_ENEMIES;
          'P' : PLACE_PLAYER;
          'C' : PLACE_CHERRY;
          'A' : CHANGE_PATH;
          'Q' : IF XPositionOfPlayer<>99 THEN BEGIN FINISH_EDITING; EXIT; END;
          ' ' : TOGGLE_WALLS;
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
     WRITE ('Release 1.0a');
     GOTOXY (26,20);
     WRITE ('Please select an option.');
     GOTOXY (26,22);
     WRITE ('P - Play Standard Level');
     GOTOXY (26,23);
     WRITE ('E - Edit Level');
     GOTOXY (26,24);
     WRITE ('A - About this program');
     GOTOXY (26,25);
     WRITE ('Q - Quit');
     GOTOXY (50, 20);
END;

{The grid is 40 by 15.  The standard level looks as follows:

ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ
É                                      É
ÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉ
ÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉ
É                                      É
ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ                    
ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ
É                                      É
ÉÉ  ÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉ
ÉÉ  ÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉ
É                                      É
ÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉ
ÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ  ÉÉÉÉÉÉÉÉÉÉ
É                                      É
ÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉÉ}


PROCEDURE ABOUT_INFO;
BEGIN
     CLRSCR;
     GOTOXY (28, 3);
     WRITE ('ASCII PACMAN RELEASE 1.0a');
     GOTOXY (1,5);
     WRITELN ('This version is Release 1.0a.  Please report any bugs and comments to');
     WRITE ('samATsamsolutions.co.uk (replace AT with @)');
     GOTOXY (1,8);
     WRITELN ('This game was created because I wanted to see what could be done with Windows ');
     WRITELN ('Pascal and to do something fun with it.  Judging by the example files that ');
     WRITELN ('came with TPW I''m not exactly pushing back the boundaries but this is more');
     WRITELN ('difficult pascal than that we learnt at college :-)');
     WRITELN;
     WRITELN ('The AI is relatively limited but not too bad and I plan to improve it.  The ');
     WRITELN ('enemy will try and move towards the player if he''s not blocked by a wall.  ');
     WRITELN ('If he finds a dead end (tunnel) the he''ll get out and shouldn''t go back in ');
     WRITELN ('the tunnel unless the player is in there');
     WRITELN;
     WRITELN ('Control Pacman / the cursor using the following keys:');
     WRITELN ('T: Up, G: Down, F: Left and H: Right.');
     WRITELN;
     WRITELN ('You complete a level by removing all dots (.) from that level.  If an enemy ');
     WRITELN ('(' + EnemyCharacter + ') manages to touch you then it''s GAME OVER but once you have the cherry');
     WRITE ('(' + CherryCharacter + ') you can eat the enemy (the enemy changes to "' + EnemyEdibleCharacter + '" once you');
     WRITELN (' have the cherry).');
     WRITELN;
     WRITE ('Press RETURN to continue');
     READLN;
     INTRODUCTION; {so the introductory text is rewritten}
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
     IF (XPositionOfPlayer=XPositionOfEnemy) AND (YPositionOfPlayer=YPositionOfEnemy) AND (GotCherry=FALSE) THEN
     BEGIN
          GAME_OVER;
     END

     ELSE IF (XPositionOfPlayer=XPositionOfEnemy) AND (YPositionOfPlayer=YPositionOfEnemy) AND (GotCherry=TRUE) THEN
     BEGIN
          XPositionOfEnemy:=99;
          YPositionOfEnemy:=99;
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

FUNCTION IN_TUNNEL(XPoint : INTEGER; YPoint : INTEGER) : BOOLEAN;
BEGIN
     {It is important to note that a point which has, for example, a block above it and a tunnel to its left and
     below it i.e.

     UDL
     ÉXX

     is NOT counted as a tunnel.  It's an entrance point to two different tunnels!}

     {for the old, LONG way of doing this, see the file intunnel.old.
     Note that with this new method, we can't replace the IFs with ELSE IFs -- one of the first
     conditions may be true but not what actually makes it a tunnel.}

     {DOWN is BLOCKED_OR_TUNNEL [BoT]}
     IN_TUNNEL:=FALSE;

     IF IS_BLOCKED_OR_TUNNEL(XPoint, YPoint+1) THEN
     BEGIN
          IF (LevelArray[XPoint+1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint-1, YPoint]=WallCharacter) THEN IN_TUNNEL:=TRUE {R&L}

          ELSE IF (LevelArray[XPoint+1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint, YPoint-1]=WallCharacter) THEN IN_TUNNEL:=TRUE {R&U}

          ELSE IF (LevelArray[XPoint, YPoint-1]=WallCharacter)
          AND (LevelArray[XPoint-1, YPoint]=WallCharacter) THEN IN_TUNNEL:=TRUE {U&L}
     END;

     {UP is BoT}
     IF IS_BLOCKED_OR_TUNNEL(XPoint, YPoint-1) THEN
     BEGIN
          IF (LevelArray[XPoint+1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint-1, YPoint]=WallCharacter) THEN IN_TUNNEL:=TRUE {R&L}

          ELSE IF (LevelArray[XPoint+1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint, YPoint+1]=WallCharacter) THEN IN_TUNNEL:=TRUE {R&D}

          ELSE IF (LevelArray[XPoint, YPoint+1]=WallCharacter)
          AND (LevelArray[XPoint-1, YPoint]=WallCharacter) THEN IN_TUNNEL:=TRUE {D&L}
     END;

     {LEFT is BoT}
     IF IS_BLOCKED_OR_TUNNEL(XPoint-1, YPoint) THEN
     BEGIN
          IF (LevelArray[XPoint+1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint, YPoint+1]=WallCharacter) THEN IN_TUNNEL:=TRUE {R&D}

          ELSE IF (LevelArray[XPoint+1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint, YPoint-1]=WallCharacter) THEN IN_TUNNEL:=TRUE {R&U}

          ELSE IF (LevelArray[XPoint, YPoint-1]=WallCharacter)
          AND (LevelArray[XPoint, YPoint+1]=WallCharacter) THEN IN_TUNNEL:=TRUE {U&D}
     END;

     {RIGHT is BoT}
     IF IS_BLOCKED_OR_TUNNEL(XPoint+1, YPoint) THEN
     BEGIN
          IF (LevelArray[XPoint-1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint, YPoint+1]=WallCharacter) THEN IN_TUNNEL:=TRUE {L&D}

          ELSE IF (LevelArray[XPoint-1, YPoint]=WallCharacter)
          AND (LevelArray[XPoint, YPoint-1]=WallCharacter) THEN IN_TUNNEL:=TRUE {L&U}

          ELSE IF (LevelArray[XPoint, YPoint-1]=WallCharacter)
          AND (LevelArray[XPoint, YPoint+1]=WallCharacter) THEN IN_TUNNEL:=TRUE {U&D}
     END;
END;

{moves the enemy by XChange in the X Direction and YChange in the Y Direction
Negative numbers used for up / left}
PROCEDURE ENEMY_POS_CHANGE(XChange: INTEGER; YChange: INTEGER);
BEGIN
     GOTOXY (XPositionOfEnemy, YPositionOfEnemy);
     IF (XPositionOfCherry = XPositionOfEnemy) AND (YPositionOfCherry = YPositionOfEnemy) AND (GotCherry = FALSE) THEN
     BEGIN
          WRITE (CherryCharacter);
     END
     ELSE IF LevelArray[XPositionOfEnemy, YPositionOfEnemy]='.' THEN WRITE ('.')
     ELSE IF LevelArray[XPositionOfEnemy, YPositionOfEnemy]=' ' THEN WRITE (' ');

     GOTOXY (XPositionOfEnemy+XChange, YPositionOfEnemy+YChange);
     XPositionOfEnemy:=XPositionOfEnemy+XChange;
     YPositionOfEnemy:=YPositionOfEnemy+YChange;
     IF GotCherry=FALSE THEN WRITE (EnemyCharacter)
     ELSE IF GotCherry=TRUE THEN WRITE ('$');
END;

PROCEDURE ENEMY_MOVEMENT;
VAR InTunnel : BOOLEAN;

BEGIN
     IF (XPositionOfEnemy<>99) THEN
     BEGIN

          InTunnel:=IN_TUNNEL(XPositionOfEnemy, YPositionOfEnemy);

          {The CurrentDeadEnd integer is the integer which will be written into the knowledge array.
          When no longer in a tunnel we increment it, so that the next tunnel will have a different number
          to the previous one (if one existed) and to the not-tunnel number (MinInt).d


          We then use these numbers to determine whether a given square is in a tunnel, and only go in to it
          if the player is in the same tunnel.}


          {Update the CurrentDeadEndInteger and fill in out enemyknowledgearray, if necessary}
          IF InTunnel=FALSE THEN
          BEGIN
               IF (AddedtoCurrentDeadEndInteger=FALSE) THEN
               BEGIN
                    INC(CurrentDeadEndInteger);
                    AddedtoCurrentDeadEndInteger:=TRUE;
               END;
          END

          ELSE IF (InTunnel=TRUE) AND (EnemyKnowledgeArray[XPositionOfEnemy, YPositionOfEnemy]=MinInt) THEN
          BEGIN
               AddedtoCurrentDeadEndInteger:=FALSE;
               EnemyKnowledgeArray[XPositionOfEnemy, YPositionOfEnemy]:=CurrentDeadEndInteger;
          END;

          {work out movement}
          IF (InTunnel=FALSE) OR (EnemyKnowledgeArray[XPositionOfEnemy, YPositionOfEnemy]=
             EnemyKnowledgeArray[XPositionOfPlayer, YPositionOfPlayer])THEN
          BEGIN
               IF (YPositionOfPlayer>YPositionOfEnemy)
               AND (LevelArray [XPositionOfEnemy, YPositionOfEnemy+1] <> (WallCharacter))
               AND ((EnemyKnowledgeArray[XPositionOfEnemy, YPositionOfEnemy+1]=MinInt)
               OR (EnemyKnowledgeArray[XPositionOfEnemy, YPositionOfEnemy+1]=
               EnemyKnowledgeArray[XPositionOfPlayer, YPositionOfPlayer])) THEN ENEMY_POS_CHANGE(0, 1)

               ELSE IF (YPositionOfPlayer<YPositionOfEnemy)
               AND (LevelArray [XPositionOfEnemy, YPositionOfEnemy-1] <> (WallCharacter))
               AND ((EnemyKnowledgeArray[XPositionOfEnemy, YPositionOfEnemy-1]=MinInt)
               OR (EnemyKnowledgeArray[XPositionOfEnemy, YPositionOfEnemy-1]=
               EnemyKnowledgeArray[XPositionOfPlayer, YPositionOfPlayer])) THEN ENEMY_POS_CHANGE(0, -1)

               ELSE IF (XPositionOfPlayer>XPositionOfEnemy)
               AND (LevelArray [XPositionOfEnemy+1, YPositionOfEnemy] <> (WallCharacter))
               AND ((EnemyKnowledgeArray[XPositionOfEnemy+1, YPositionOfEnemy]=MinInt)
               OR (EnemyKnowledgeArray[XPositionOfEnemy+1, YPositionOfEnemy]=
               EnemyKnowledgeArray[XPositionOfPlayer, YPositionOfPlayer])) THEN ENEMY_POS_CHANGE(1, 0)

               ELSE IF (XPositionOfPlayer<XPositionOfEnemy)
               AND (LevelArray [XPositionOfEnemy-1, YPositionOfEnemy] <> (WallCharacter))
               AND ((EnemyKnowledgeArray[XPositionOfEnemy-1, YPositionOfEnemy]=MinInt)
               OR (EnemyKnowledgeArray[XPositionOfEnemy-1, YPositionOfEnemy]=
               EnemyKnowledgeArray[XPositionOfPlayer, YPositionOfPlayer])) THEN ENEMY_POS_CHANGE(-1, 0)
          END

          ELSE IF InTunnel=TRUE THEN
          BEGIN
               IF NOT IS_BLOCKED_OR_TUNNEL(XPositionOfEnemy+1, YPositionOfEnemy) THEN ENEMY_POS_CHANGE(1, 0)
               ELSE IF NOT IS_BLOCKED_OR_TUNNEL(XPositionOfEnemy-1, YPositionOfEnemy) THEN ENEMY_POS_CHANGE(-1, 0)
               ELSE IF NOT IS_BLOCKED_OR_TUNNEL(XPositionOfEnemy, YPositionOfEnemy+1) THEN ENEMY_POS_CHANGE(0, 1)
               ELSE IF NOT IS_BLOCKED_OR_TUNNEL(XPositionOfEnemy, YPositionOfEnemy-1) THEN ENEMY_POS_CHANGE(0, -1)
          END;
     END; {matches IF (XPositionOfEnemy<>99) THEN}

END;

PROCEDURE SETUP_STANDARD_LEVEL;
BEGIN
     XPositionOfEnemy:=2;
     YPositionOfEnemy:=2;
     XPositionOfPlayer:=39;
     YPositionOfPlayer:=14;
     XPositionOfCherry:=38;
     YPositionOfCherry:=2;
END;

PROCEDURE MAIN_PROGRAM;
VAR UserInput : CHAR;
    RandomNumber : INTEGER;
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
          DELAY(2);
          IF KeyPressed=TRUE THEN
          BEGIN
               UserInput:=ReadKey;

               CASE UPCASE(UserInput) OF

               'T' : PLAYER_POS_CHANGE(0, -1); {up}
               'G' : PLAYER_POS_CHANGE(0, 1); {down}
               'F' : PLAYER_POS_CHANGE(-1, 0); {left}       
               'H' : PLAYER_POS_CHANGE(1, 0); {right}

               ELSE
                   BEGIN
                        RANDOMIZE;
                        RandomNumber:=RANDOM(2);
                        IF ((RandomNumber=1) OR (RandomNumber=2)) AND (XPositionOfEnemy<>99) THEN ENEMY_MOVEMENT;
                   END;
               END;

               TEST_POSITION;
               RANDOMIZE;
               RandomNumber:=RANDOM(3);
               IF ((RandomNumber=1) OR (RandomNumber=2)) AND (XPositionOfEnemy<>99)THEN ENEMY_MOVEMENT;
               TEST_POSITION;
          END

          ELSE
          BEGIN
               RANDOMIZE;
               RandomNumber:=RANDOM(3);
               IF ((RandomNumber=1) OR (RandomNumber=2)) AND (XPositionOfEnemy<>99)THEN ENEMY_MOVEMENT;
               TEST_POSITION;
          END;
     END; {end while}
END;

PROCEDURE MENU_LOOP;
VAR   IsOptionChosen : BOOLEAN;
      OptionChosen : CHAR;

BEGIN
     CurrentDeadEndInteger:=MinInt+1;
     AddedToCurrentDeadEndInteger:=TRUE;
     INTRODUCTION;
     REPEAT
           READLN (OptionChosen);
           IF (UPCASE(OptionChosen)='P') THEN
           BEGIN
                IsOptionChosen:=TRUE;
                SETUP_STANDARD_LEVEL;
                DRAW_STANDARD_LEVEL;
                POSITION_OBJECTS;
           END;

           IF (UPCASE(OptionChosen)='E') THEN
           BEGIN
                IsOptionChosen:=TRUE;
                LEVEL_EDITOR;
           END;

           IF (UPCASE(OptionChosen)='A') THEN
           BEGIN
                ABOUT_INFO;
                IsOptionChosen:=FALSE;
           END;

           IF (UPCASE(OptionChosen)='Q') THEN
              DONEWINCRT;

     UNTIL IsOptionChosen=TRUE;

     IsOptionChosen:=FALSE;
     MAIN_PROGRAM;
END;


{The actual program is below}

BEGIN
     Path:= 'c:\progra~1\turbop~1\windows\programs\pacman\redo\levels\';
     StrCopy(WindowTitle, 'ASCII PACMAN RELEASE 1.0a');

     CLRSCR;
     GOTOXY (23,11);
     WRITE ('Please Maximize this window.');
     READLN;
     WHILE 2<3 DO
     BEGIN
          MENU_LOOP;
     END;

END.