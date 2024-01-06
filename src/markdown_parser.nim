import std/strutils

# World's simplest, most incomplete Markdown parser
type MarkdownParser* = object
    src*: string
    len: int
    pos: int

proc create_markdown_parser*(src: string): MarkdownParser =
    return MarkdownParser(src: src, len: src.len, pos: 0)

proc next(self: var MarkdownParser): char =
    if self.pos + 1 >= self.len:
        raise IndexDefect.newException("Tried to read past end of text")
    else:
        inc self.pos
    return self.src[self.pos]

proc peek(self: MarkdownParser): char =
    return self.src[self.pos]

proc prev(self: var MarkdownParser): char =
    if self.pos - 1 < 0:
        raise IndexDefect.newException("Tried to read before beginning of text")
    else:
        dec self.pos
    return self.src[self.pos]

proc parse*(self: var MarkdownParser): string =
    var lines = self.src.splitLines()
    for line in lines:
        for character in line:
            echo character
    return ""