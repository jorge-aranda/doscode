' DOSCODE user interface module.
' Uses SCREEN 0 and CP437 box characters for an authentic 80x25 DOS TUI.

DECLARE SUB UIDrawFrame ()
DECLARE SUB UISetStatus (model$, path$)
DECLARE SUB UIAddLine (kind$, text$)
DECLARE SUB UIInput (prompt$)
DECLARE SUB UIHelp ()
DECLARE SUB UIClearChat ()
DECLARE SUB UIInit ()
DECLARE SUB UIScrollIfNeeded ()
DECLARE FUNCTION KeyLine$ ()

DIM SHARED CNormal%
DIM SHARED CAI%
DIM SHARED CUser%
DIM SHARED CTitle%
DIM SHARED CError%
DIM SHARED CAction%
DIM SHARED ChatTop%
DIM SHARED ChatBottom%
DIM SHARED InputRow%
DIM SHARED ChatRow%

SUB UIInit ()
    CNormal% = 7
    CAI% = 10
    CUser% = 14
    CTitle% = 11
    CError% = 12
    CAction% = 13
    ChatTop% = 4
    ChatBottom% = 21
    InputRow% = 23
    SCREEN 0
    WIDTH 80, 25
    COLOR CNormal%, 0
    CLS
    ChatRow% = ChatTop%
END SUB

SUB UIDrawFrame ()
    COLOR CTitle%, 0
    CLS
    LOCATE 1, 1: PRINT CHR$(218); STRING$(2, CHR$(196)); " DOSCODE "; STRING$(66, CHR$(196)); CHR$(191);
    LOCATE 2, 1: PRINT CHR$(179); SPACE$(78); CHR$(179);
    LOCATE 3, 1: PRINT CHR$(195); STRING$(78, CHR$(196)); CHR$(180);
    FOR r% = 4 TO 21
        LOCATE r%, 1: PRINT CHR$(179); SPACE$(78); CHR$(179);
    NEXT r%
    LOCATE 22, 1: PRINT CHR$(195); STRING$(78, CHR$(196)); CHR$(180);
    LOCATE 23, 1: PRINT CHR$(179); SPACE$(78); CHR$(179);
    LOCATE 24, 1: PRINT CHR$(179); " F1 Help  F2 Files  F3 Retry  F4 Clear  F5 Model  TAB Commands           "; CHR$(179);
    LOCATE 25, 1: PRINT CHR$(192); STRING$(78, CHR$(196)); CHR$(217);
    ChatRow% = ChatTop%
END SUB

SUB UISetStatus (model$, path$)
    COLOR CNormal%, 0
    LOCATE 2, 3
    PRINT "model: "; model$; SPACE$(18 - LEN(model$)); " path: "; LEFT$(path$, 36); SPACE$(20);
END SUB

SUB UIScrollIfNeeded ()
    IF ChatRow% > ChatBottom% THEN
        FOR r% = ChatTop% TO ChatBottom%
            LOCATE r%, 2: PRINT SPACE$(78);
        NEXT r%
        ChatRow% = ChatTop%
        UIAddLine "SYS", "-- screen cleared for RAM-friendly scroll --"
    END IF
END SUB

SUB UIAddLine (kind$, text$)
    CALL UIScrollIfNeeded
    IF kind$ = "AI" THEN
        COLOR CAI%, 0
    ELSEIF kind$ = "YOU" THEN
        COLOR CUser%, 0
    ELSEIF kind$ = "ERR" THEN
        COLOR CError%, 0
    ELSEIF kind$ = "ACT" THEN
        COLOR CAction%, 0
    ELSE
        COLOR CNormal%, 0
    END IF
    LOCATE ChatRow%, 3
    IF kind$ = "YOU" THEN
        PRINT "You > "; LEFT$(text$, 70);
    ELSEIF kind$ = "AI" THEN
        PRINT "AI  > "; LEFT$(text$, 70);
    ELSEIF kind$ = "ACT" THEN
        PRINT CHR$(4); " "; LEFT$(text$, 74);
    ELSE
        PRINT LEFT$(text$, 76);
    END IF
    ChatRow% = ChatRow% + 1
END SUB

SUB UIInput (prompt$)
    COLOR CNormal%, 0
    LOCATE InputRow%, 2: PRINT SPACE$(78);
    LOCATE InputRow%, 3: PRINT "> ";
    prompt$ = KeyLine$
END SUB

FUNCTION KeyLine$ ()
    line$ = ""
    DO
        k$ = INKEY$
        IF k$ <> "" THEN
            IF LEN(k$) = 2 THEN
                code% = ASC(RIGHT$(k$, 1))
                IF code% = 59 THEN UIHelp
                IF code% = 62 THEN UIClearChat
            ELSEIF ASC(k$) = 13 THEN
                EXIT DO
            ELSEIF ASC(k$) = 8 THEN
                IF LEN(line$) > 0 THEN
                    line$ = LEFT$(line$, LEN(line$) - 1)
                    LOCATE InputRow%, 5 + LEN(line$): PRINT " ";
                    LOCATE InputRow%, 5 + LEN(line$)
                END IF
            ELSEIF ASC(k$) >= 32 THEN
                IF LEN(line$) < 72 THEN
                    line$ = line$ + k$
                    PRINT k$;
                END IF
            END IF
        END IF
    LOOP
    KeyLine$ = line$
END FUNCTION

SUB UIHelp ()
    UIAddLine "SYS", "/help /clear /history /model /exit /read /write /run /fix /explain /plan /apply /diff /undo"
END SUB

SUB UIClearChat ()
    FOR r% = ChatTop% TO ChatBottom%
        LOCATE r%, 2: PRINT SPACE$(78);
    NEXT r%
    ChatRow% = ChatTop%
END SUB
