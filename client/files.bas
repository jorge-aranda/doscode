' DOSCODE file and command helpers.

DECLARE SUB UIAddLine (kind$, text$)

FUNCTION CurrentPath$
    CurrentPath$ = CURDIR$
END FUNCTION

SUB ReadFileToChat (path$)
    f% = FREEFILE
    OPEN path$ FOR INPUT AS #f%
    count% = 0
    DO WHILE NOT EOF(f%) AND count% < 12
        LINE INPUT #f%, line$
        UIAddLine "SYS", LEFT$(line$, 76)
        count% = count% + 1
    LOOP
    CLOSE #f%
    UIAddLine "SYS", CHR$(251) + " read " + LTRIM$(STR$(count%)) + " lines from " + path$
END SUB

SUB WriteFileFromAction (path$, body$)
    f% = FREEFILE
    OPEN path$ FOR OUTPUT AS #f%
    PRINT #f%, body$
    CLOSE #f%
    UIAddLine "SYS", CHR$(251) + " written " + path$
END SUB

SUB RunDosCommand (cmd$)
    SHELL cmd$
    UIAddLine "SYS", CHR$(251) + " command finished"
END SUB
