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
DECLARE FUNCTION SerialIsReady% ()
DECLARE FUNCTION SerialLastError% ()
DECLARE SUB HandleServerLine (line$)
DECLARE SUB ExecuteLocalCommand (cmd$)
DECLARE FUNCTION CurrentPath$ ()
DECLARE SUB StopProgram ()
DECLARE SUB SetModel (newModel$)

DIM SHARED Running%
DIM SHARED Model$
DIM SHARED PortNum%

Running% = -1
Model$ = ENVIRON$("LLM_MODEL")
IF Model$ = "" THEN Model$ = "claude-3-5-haiku-20241022"
PortNum% = 1

UIInit
UIDrawFrame
UISetStatus Model$, CurrentPath$
UIAddLine "AI", "DOSCODE ready. Proxy expected on COM1. Press F1 for help."
SerialOpen PortNum%
IF SerialIsReady% = 0 THEN
    UIAddLine "ERR", "Cannot open COM1. Check DOSBox serial config. ERR=" + LTRIM$(STR$(SerialLastError%))
ELSE
    UIAddLine "SYS", "Serial COM1 ready."
END IF

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
                IF line$ <> "" THEN
                    ' Trim trailing CR/LF/space residue from serial buffer
                    DO WHILE LEN(line$) > 0
                        last$ = RIGHT$(line$, 1)
                        IF last$ = CHR$(13) OR last$ = CHR$(10) OR last$ = " " THEN
                            line$ = LEFT$(line$, LEN(line$) - 1)
                        ELSE
                            EXIT DO
                        END IF
                    LOOP
                    IF line$ = "END" THEN EXIT DO
                    HandleServerLine line$
                ELSE
                    k$ = INKEY$
                END IF
            LOOP
        END IF
    END IF
LOOP

SUB StopProgram ()
    Running% = 0
END SUB

SUB SetModel (newModel$)
    Model$ = newModel$
    UISetStatus Model$, CurrentPath$
END SUB

COLOR 7, 0
CLS
PRINT "DOSCODE terminated."
END
