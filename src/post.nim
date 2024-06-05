import strformat
import strutils
import options
import sugar
import times
import re
import os

import markdown_parser

type Post* = object
    publish_date*: Option[DateTime]
    filename*: string
    num_words*: int
    title*: string
    body*: string
    desc*: string
    id*: int

proc get_title_and_desc(text: string): seq[string] =
    # Nim's `re` module incorrectly handles capture groups
    # for `findAll`, so we have to work around it here
    # https://forum.nim-lang.org/t/10295
    var title_and_desc = text.findAll(re("=\"(.*)\"\\s"))
    title_and_desc = collect(newSeq):
        for elem in title_and_desc:
            elem.substr(2, len(elem) - 3)
    return title_and_desc

proc create_post*(id: int, dont_parse_markdown: bool = false, can_be_none: bool = false): Option[Post] =
    var post = Post(id: id)
    var post_exists = false
    var raw_filename: string
    let header_split_pattern = re"-\r?\n"

    # Find the post in `raw/`
    for kind, path in walkDir("raw/"):
        if kind == pcFile:
            let id = parseInt(path.substr(4).split('_')[0])
            if id == post.id:
                raw_filename = path
                let text = readFile(path)
                # The body starts after the '-' line
                let split = text.split(header_split_pattern, 1)
                if split.len < 2:
                    raise Defect.newException("Error: Couldn't find the '-' delimiter while parsing \"" & path & "\"")
                post.body = split[1]
                if not dont_parse_markdown:
                    var parser = create_markdown_parser(post.body)
                    post.body = parser.parse()

                let title_and_desc = get_title_and_desc(text)
                post.title = title_and_desc[0]
                post.desc = title_and_desc[1]
                post.filename = splitFile(path).name
                post_exists = true
                break

    if not post_exists:
        if not can_be_none:
            raise Defect.newException(&"Error: Couldn't find a post with number {id}")
        else:
            return none(Post)

    post.num_words = post.body.split(re("\\s")).len
    # If the post was previously published,
    # get its original publication date
    # (Otherwise we won't define `published`
    # until the "p" command is used)
    if fileExists("posts/" & post.filename & ".html"):
        post.publish_date = some(getCreationTime("posts/" & post.filename & ".html").local())
    else:
        post.publish_date = none(DateTime)

    return some(post)