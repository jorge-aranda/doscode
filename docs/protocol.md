# DOSCODE Serial Protocol

The protocol is plain text over a serial line. It is designed for simple BASIC
parsing on real DOS machines.

## Transport

Default settings:

```text
port: COM1
baud: 9600
data: 8 bits
parity: none
stop: 1 bit
encoding: CP437-compatible text
```

No binary frames are used.

## Client request

The DOS client sends one prompt frame:

```text
PROMPT length
prompt text
```

Example:

```text
PROMPT 18
fix CONFIG.SYS
```

The length is advisory. The proxy accepts the next line as the prompt body.

## Server response

The proxy streams response lines as soon as they are available:

```text
LINE analyzing...
LINE found one problem
LINE <READ path="CONFIG.SYS">
END
```

Rules:

- each visible assistant line starts with `LINE `
- each assistant turn ends with `END`
- the client should render each `LINE` immediately
- the proxy should flush after each line

## Tool actions

Tool actions are simple tags embedded in streamed lines.

### Read

```text
<READ path="AUTOEXEC.BAT">
```

The DOS client reads the file locally and displays or returns the result.

### Write

```text
<WRITE path="TEST.TXT">
new content
</WRITE>
```

The DOS client writes local content. Full multi-line automatic writes are a
post-MVP enhancement; the parser already recognizes the opening tag.

### Run

```text
<RUN>
DIR
</RUN>
```

The DOS client must ask for confirmation before executing the command:

```text
Execute command? [Y/N]
```

## Diff mode

Diffs use classic unified-style markers:

```diff
- old line
+ new line
```

The DOS UI should render removed lines in red and added lines in green.
