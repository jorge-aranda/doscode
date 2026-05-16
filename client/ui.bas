' DOSCODE user interface module.
' Uses SCREEN 0 and CP437 box characters for an authentic 80x25 DOS TUI.

DECLARE SUB UIDrawFrame ()
DECLARE SUB UISetStatus (model$, path$)
DECLARE SUB UIAddLine (kind$, text$)
DECLARE SUB UIInput (prompt$)
DECLARE SUB UIHelp ()
DECLARE SUB UIClearChat ()
DECLARE FUNCTION KeyLine$ ()

CONST C_NORMAL = 7
CONST C_AI = 10
CONST C_USER = 14
CONST C_TITLE = 11
CONST C_ERROR = 12
CONST C_ACTION = 13
CONST CHAT_TOP = 4
CONST CHAT_BOTTOM = 21
CONST INPUT_ROW = 23

COMMON SHARED ChatRow%
COMMON SHARED Running%, Model$

SUB UIInit
    SCREEN 0
    WIDTH 80, 25
    COLOR C_NORMAL, 0
    CLS
    ChatRow% = CHAT_TOP
END SUB

SUB UIDrawFrame
    COLOR C_TITLE, 0
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
    ChatRow% = CHAT_TOP
END SUB

SUB UISetStatus (model$, path$)
    COLOR C_NORMAL, 0
    LOCATE 2, 3
    PRINT "model: "; model$; SPACE$(18 - LEN(model$)); " path: "; LEFT$(path$, 36); SPACE$(20);
END SUB

SUB UIScrollIfNeeded
    IF ChatRow% > CHAT_BOTTOM THEN
        FOR r% = CHAT_TOP TO CHAT_BOTTOM
            LOCATE r%, 2: PRINT SPACE$(78);
        NEXT r%
        ChatRow% = CHAT_TOP
        UIAddLine "SYS", "-- screen cleared for RAM-friendly scroll --"
    END IF
END SUB

SUB UIAddLine (kind$, text$)
    CALL UIScrollIfNeeded
    IF kind$ = "AI" THEN COLOR C_AI, 0 ELSE IF kind$ = "YOU" THEN COLOR C_USER, 0 ELSE IF kind$ = "ERR" THEN COLOR C_ERROR, 0 ELSE IF kind$ = "ACT" THEN COLOR C_ACTION, 0 ELSE COLOR C_NORMAL, 0
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
    COLOR C_NORMAL, 0
    LOCATE INPUT_ROW, 2: PRINT SPACE$(78);
    LOCATE INPUT_ROW, 3: PRINT "> ";
    prompt$ = KeyLine$
END SUB

FUNCTION KeyLine$
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
                    LOCATE INPUT_ROW, 5 + LEN(line$): PRINT " ";
                    LOCATE INPUT_ROW, 5 + LEN(line$)
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

SUB UIHelp
    UIAddLine "SYS", "/help /clear /history /model /exit /read /write /run /fix /explain /plan /apply /diff /undo"
END SUB

SUB UIClearChat
    FOR r% = CHAT_TOP TO CHAT_BOTTOM
        LOCATE r%, 2: PRINT SPACE$(78);
    NEXT r%
    ChatRow% = CHAT_TOP
END SUB
