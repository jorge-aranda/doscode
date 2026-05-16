' DOSCODE - MS-DOS AI coding agent client
' Main program for QuickBasic 4.5 / QBasic-compatible DOS environments.
' Keep this file small: the real work lives in the companion modules.

DECLARE SUB UIInit ()
DECLARE SUB UIDrawFrame ()
DECLARE SUB UISetStatus (model$, path$)
DECLARE SUB UIAddLine (kind$, text$)
DECLARE SUB UIInput (prompt$)
DECLARE SUB UIHelp ()
DECLARE SUB SerialOpen (portNum%)
DECLARE SUB SerialSendPrompt (prompt$)
DECLARE FUNCTION SerialReadLine$ ()
DECLARE SUB HandleServerLine (line$)
DECLARE SUB ExecuteLocalCommand (cmd$)
DECLARE FUNCTION CurrentPath$ ()

COMMON SHARED Running%, Model$, PortNum%

Running% = -1
Model$ = ENVIRON$("LLM_MODEL")
IF Model$ = "" THEN Model$ = "gpt-5.5"
PortNum% = 1

UIInit
UIDrawFrame
UISetStatus Model$, CurrentPath$
UIAddLine "AI", "DOSCODE ready. Proxy expected on COM1. Press F1 for help."
SerialOpen PortNum%

DO WHILE Running%
    prompt$ = ""
    UIInput prompt$

    IF LEN(prompt$) > 0 THEN
        IF LEFT$(prompt$, 1) = "/" THEN
            ExecuteLocalCommand prompt$
        ELSE
            UIAddLine "YOU", prompt$
            SerialSendPrompt prompt$
            DO
                line$ = SerialReadLine$
                IF line$ = "" THEN EXIT DO
                HandleServerLine line$
                IF line$ = "END" THEN EXIT DO
            LOOP
        END IF
    END IF
LOOP

COLOR 7, 0
CLS
PRINT "DOSCODE terminated."
END
