REM screens.bas
MODE 9
VDU 23,0,1,0;0;0;0;
PROCscreen(1)
PROCscreen(2)
PROCscreen(3)
END
DEF PROCscreen(scr)
CLS:COLOUR 15
FOR I%=0 TO 31
READ S$
PRINT TAB(0,I%);S$;
VDU 30
NEXT
OSCLI "SAVE SCR"+STR$(scr)+" 1FE8000+A000"
ENDPROC
:
DATA "+--------------------------------------+"
DATA "|                                      |"
DATA "|                                      |"
DATA "|           CHECK THIS OUT!            |"
DATA "|           ~~~~~~~~~~~~~~~            |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|       A DEMO BY                      |"
DATA "|                                      |"
DATA "|        >>>>> BITSHIFTERS             |"
DATA "|                                      |"
DATA "|                AND                   |"
DATA "|                                      |"
DATA "|                TORMENT <<<<<         |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|    -=# RELEASED AT NOVA 2023 #=-     |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|               CREDITS                |"
DATA "|     code..................kieran     |"
DATA "|     music..................rhino     |"
DATA "|     qtm by.......phoenix^quantum     |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|     Special thanks to:               |"
DATA "|                                      |"
DATA "|     Progen^DESiRE                    |"
DATA "|                Blueberry^Loonies     |"
DATA "|                                      |"
DATA "|                                      |"
DATA "+--------------------------------------+"
:
DATA "+--------------------------------------+"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                GREETS                |"
DATA "|                ~~~~~~                |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|     Ate-Bit       AttentionWhore     |"
DATA "|                                      |"
DATA "|     CRTC                  DESiRE     |"
DATA "|                                      |"
DATA "|     Hooy Program   Inverse Phase     |"
DATA "|                                      |"
DATA "|     Lemon.              Logicoma     |"
DATA "|                                      |"
DATA "|     Loonies              Proxima     |"
DATA "|                                      |"
DATA "|     Rabenauge               RiFT     |"
DATA "|                                      |"
DATA "|     Slipstream        YM Rockerz     |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|     ~ And everyone at the party!     |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "+--------------------------------------+"
:
DATA "+--------------------------------------+"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|     Only five years late for         |"
DATA "|     Blueberry's Checkerboard         |"
DATA "|     Challenge at GERP 2018.. :)      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|     Party version is 8 layers        |"
DATA "|         on ARM250 (12MHz) only..     |"
DATA "|                                      |"
DATA "|     Final version will support       |"
DATA "|        6 layers on ARM2 (8MHz)..     |"
DATA "|                                      |"
DATA "|     Not as many as Amiga or STe      |"
DATA "|         but Archimedes has..         |"
DATA "|                                      |"
DATA "|     No Copper.. no Blitter..         |"
DATA "|                                      |"
DATA "|     and most importantly...          |"
DATA "|                 NO BITPLANES!!!!     |"
DATA "|                                      |"
DATA "|     Only ARM CPU power. :)           |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|     We tried, can you do better?     |"
DATA "|                                      |"
DATA "|                                      |"
DATA "|                                      |"
DATA "+--------------------------------------+"
:
