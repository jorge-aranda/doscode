' DOSCODE file and command helpers.

DECLARE SUB UIAddLine (kind$, text$)

FUNCTION CurrentPath$
    CurrentPath$ = CURDIR$
END FUNCTION

SUB ReadFileToChat (path$)
    f% = FREEFILE
    ON ERROR GOTO ReadError
    OPEN path$ FOR INPUT AS #f%
    count% = 0
    DO WHILE NOT EOF(f%) AND count% < 12
        LINE INPUT #f%, line$
        UIAddLine "SYS", LEFT$(line$, 76)
        count% = count% + 1
    LOOP
    CLOSE #f%
    UIAddLine "SYS", CHR$(251) + " read " + LTRIM$(STR$(count%)) + " lines from " + path$
    EXIT SUB
ReadError:
    UIAddLine "ERR", "cannot read " + path$
    RESUME NEXT
END SUB

SUB WriteFileFromAction (path$, body$)
    f% = FREEFILE
    ON ERROR GOTO WriteError
    OPEN path$ FOR OUTPUT AS #f%
    PRINT #f%, body$
    CLOSE #f%
    UIAddLine "SYS", CHR$(251) + " written " + path$
    EXIT SUB
WriteError:
    UIAddLine "ERR", "cannot write " + path$
    RESUME NEXT
END SUB

SUB RunDosCommand (cmd$)
    UIAddLine "ACT", "RUN " + cmd$
    UIAddLine "SYS", "Execute command? [Y/N]"
    DO
        k$ = UCASE$(INKEY$)
    LOOP WHILE k$ <> "Y" AND k$ <> "N"
    IF k$ = "Y" THEN
        SHELL cmd$
        UIAddLine "SYS", CHR$(251) + " command finished"
    ELSE
        UIAddLine "SYS", "command cancelled"
    END IF
END SUB
