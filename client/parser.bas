' DOSCODE response parser and local command dispatcher.

DECLARE SUB UIAddLine (kind$, text$)
DECLARE SUB UIHelp ()
DECLARE SUB UIClearChat ()
DECLARE SUB ReadFileToChat (path$)
DECLARE SUB WriteFileFromAction (path$, body$)
DECLARE SUB RunDosCommand (cmd$)
DECLARE SUB SerialSendPrompt (prompt$)
DECLARE SUB StopProgram ()
DECLARE SUB SetModel (newModel$)
DECLARE FUNCTION ExtractPath$ (line$)
DECLARE SUB ConfirmAndRun (cmd$)
DECLARE FUNCTION IsTurnDone% ()
DECLARE SUB ResetTurnDone ()

DIM SHARED ActionMode$
DIM SHARED ActionPath$
DIM SHARED ActionBody$
DIM SHARED TurnDone%

SUB HandleServerLine (line$)
    IF line$ = "END" THEN EXIT SUB
    IF LEFT$(line$, 5) = "LINE " THEN line$ = MID$(line$, 6)

    IF ActionMode$ = "WRITE" THEN
        IF line$ = "</WRITE>" THEN
            WriteFileFromAction ActionPath$, ActionBody$
            ActionMode$ = ""
            ActionPath$ = ""
            ActionBody$ = ""
        ELSE
            ActionBody$ = ActionBody$ + line$ + CHR$(13) + CHR$(10)
        END IF
        EXIT SUB
    END IF

    IF ActionMode$ = "RUN" THEN
        closeIdx% = INSTR(line$, "</RUN>")
        IF closeIdx% > 0 THEN
            extra$ = LEFT$(line$, closeIdx% - 1)
            IF LEN(extra$) > 0 THEN
                IF ActionBody$ = "" THEN ActionBody$ = extra$ ELSE ActionBody$ = ActionBody$ + " " + extra$
            END IF
            ConfirmAndRun ActionBody$
            ActionMode$ = ""
            ActionBody$ = ""
        ELSE
            IF ActionBody$ = "" THEN ActionBody$ = line$ ELSE ActionBody$ = ActionBody$ + " " + line$
        END IF
        EXIT SUB
    END IF

    IF LEFT$(line$, 6) = "<READ " THEN
        p$ = ExtractPath$(line$)
        UIAddLine "ACT", "READ " + p$
        ReadFileToChat p$
    ELSEIF LEFT$(line$, 7) = "<WRITE " THEN
        p$ = ExtractPath$(line$)
        UIAddLine "ACT", "WRITE " + p$
        ActionMode$ = "WRITE"
        ActionPath$ = p$
        ActionBody$ = ""
    ELSEIF LEFT$(line$, 5) = "<RUN>" THEN
        rest$ = MID$(line$, 6)
        closeIdx% = INSTR(rest$, "</RUN>")
        IF closeIdx% > 0 THEN
            cmd$ = LEFT$(rest$, closeIdx% - 1)
            ConfirmAndRun cmd$
        ELSE
            UIAddLine "ACT", "RUN requested by model"
            ActionMode$ = "RUN"
            ActionBody$ = rest$
        END IF
    ELSE
        UIAddLine "AI", line$
    END IF
END SUB

FUNCTION ExtractPath$ (line$)
    q1% = INSTR(line$, "path=" + CHR$(34))
    IF q1% > 0 THEN
        start% = q1% + 6
        q2% = INSTR(start%, line$, CHR$(34))
        ExtractPath$ = MID$(line$, start%, q2% - start%)
    ELSE
        a% = INSTR(line$, " ")
        b% = INSTR(line$, ">")
        IF a% > 0 AND b% > a% THEN ExtractPath$ = MID$(line$, a% + 1, b% - a% - 1) ELSE ExtractPath$ = ""
    END IF
END FUNCTION

SUB ConfirmAndRun (cmd$)
    IF LEN(cmd$) = 0 THEN
        UIAddLine "SYS", "RUN cancelled: empty command"
        EXIT SUB
    END IF
    UIAddLine "ACT", "RUN: " + cmd$
    UIAddLine "SYS", "Execute? press Y to confirm, any other key to cancel"
    DO
        k$ = INKEY$
    LOOP WHILE k$ = ""
    IF UCASE$(k$) = "Y" THEN
        RunDosCommand cmd$
    ELSE
        UIAddLine "SYS", "RUN cancelled"
    END IF
    TurnDone% = -1
END SUB

FUNCTION IsTurnDone% ()
    IsTurnDone% = TurnDone%
END FUNCTION

SUB ResetTurnDone ()
    TurnDone% = 0
END SUB

SUB ExecuteLocalCommand (cmd$)
    c$ = LCASE$(cmd$)
    IF c$ = "/help" THEN
        UIHelp
    ELSEIF c$ = "/clear" THEN
        UIClearChat
    ELSEIF c$ = "/exit" THEN
        StopProgram
    ELSEIF LEFT$(c$, 6) = "/read " THEN
        ReadFileToChat MID$(cmd$, 7)
    ELSEIF LEFT$(c$, 5) = "/run " THEN
        RunDosCommand MID$(cmd$, 6)
    ELSEIF LEFT$(c$, 7) = "/write " THEN
        UIAddLine "SYS", "type one line to write into " + MID$(cmd$, 8)
        LINE INPUT body$
        WriteFileFromAction MID$(cmd$, 8), body$
    ELSEIF LEFT$(c$, 7) = "/model " THEN
        newModel$ = MID$(cmd$, 8)
        SetModel newModel$
        UIAddLine "SYS", "model set to " + newModel$
    ELSEIF c$ = "/history" OR c$ = "/diff" OR c$ = "/undo" OR c$ = "/apply" THEN
        UIAddLine "SYS", "command reserved for next milestone"
    ELSEIF LEFT$(c$, 5) = "/fix " OR LEFT$(c$, 9) = "/explain " OR LEFT$(c$, 6) = "/plan " THEN
        SerialSendPrompt cmd$
    ELSE
        UIAddLine "ERR", "unknown command: " + cmd$
    END IF
END SUB
