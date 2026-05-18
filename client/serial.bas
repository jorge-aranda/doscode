' DOSCODE serial transport module.
' Plain text protocol over COM1/COM2. No binary framing and no JSON.

DECLARE SUB SerialOpen (portNum%)
DECLARE SUB SerialSendPrompt (prompt$)
DECLARE FUNCTION SerialReadLine$ ()
DECLARE FUNCTION SerialIsReady% ()
DECLARE FUNCTION SerialLastError% ()

DIM SHARED SerialFile%
DIM SHARED SerialReady%
DIM SHARED SerialError%

SUB SerialOpen (portNum%)
    SerialFile% = FREEFILE
    SerialError% = 0
    port$ = "COM" + LTRIM$(STR$(portNum%)) + ":9600,N,8,1,CS0,DS0,CD0,RS"
    OPEN port$ FOR RANDOM AS #SerialFile% LEN = 1
    SerialReady% = -1
END SUB

SUB SerialSendPrompt (prompt$)
    IF SerialReady% = 0 THEN EXIT SUB
    header$ = "PROMPT " + LTRIM$(STR$(LEN(prompt$))) + CHR$(13) + CHR$(10)
    body$ = prompt$ + CHR$(13) + CHR$(10)
    FOR i% = 1 TO LEN(header$)
        PRINT #SerialFile%, MID$(header$, i%, 1);
    NEXT i%
    FOR i% = 1 TO LEN(body$)
        PRINT #SerialFile%, MID$(body$, i%, 1);
    NEXT i%
END SUB

FUNCTION SerialReadLine$
    IF SerialReady% = 0 THEN SerialReadLine$ = "": EXIT FUNCTION
    IF LOC(SerialFile%) > 0 THEN
        LINE INPUT #SerialFile%, line$
        SerialReadLine$ = line$
    ELSE
        SerialReadLine$ = ""
    END IF
END FUNCTION

FUNCTION SerialIsReady% ()
    SerialIsReady% = SerialReady%
END FUNCTION

FUNCTION SerialLastError% ()
    SerialLastError% = SerialError%
END FUNCTION
