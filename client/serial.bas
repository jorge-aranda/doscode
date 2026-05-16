' DOSCODE serial transport module.
' Plain text protocol over COM1/COM2. No binary framing and no JSON.

DECLARE SUB SerialOpen (portNum%)
DECLARE SUB SerialSendPrompt (prompt$)
DECLARE FUNCTION SerialReadLine$ ()

COMMON SHARED SerialFile%, SerialReady%

SUB SerialOpen (portNum%)
    SerialFile% = FREEFILE
    port$ = "COM" + LTRIM$(STR$(portNum%)) + ":9600,N,8,1,CS0,DS0,CD0,RS"
    ON ERROR GOTO SerialOpenError
    OPEN port$ FOR RANDOM AS #SerialFile%
    SerialReady% = -1
    EXIT SUB
SerialOpenError:
    SerialReady% = 0
    RESUME NEXT
END SUB

SUB SerialSendPrompt (prompt$)
    IF SerialReady% = 0 THEN EXIT SUB
    PRINT #SerialFile%, "PROMPT"; STR$(LEN(prompt$))
    PRINT #SerialFile%, prompt$
END SUB

FUNCTION SerialReadLine$
    IF SerialReady% = 0 THEN SerialReadLine$ = "": EXIT FUNCTION
    ON ERROR GOTO SerialReadError
    IF LOC(SerialFile%) >= 0 THEN
        LINE INPUT #SerialFile%, line$
        SerialReadLine$ = line$
    ELSE
        SerialReadLine$ = ""
    END IF
    EXIT FUNCTION
SerialReadError:
    SerialReadLine$ = ""
    RESUME NEXT
END FUNCTION
