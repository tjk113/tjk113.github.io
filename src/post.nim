import strformat
import strutils
import options
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

proc get_title_and_desc(text: string): (string, string) =
    var title_and_desc: array[2, string]
    discard text.find(re("=\"(.*)\""), title_and_desc)
    return (title_and_desc[0], title_and_desc[1])

proc parse_markdown(text: string): string =
    var parser = create_markdown_parser(text)
    return parser.parse()

proc create_post*(id: int): Option[Post] =
    var post = Post(id: id)
    var post_exists = false

    # Find the post in `raw/`
    for kind, path in walkDir("raw/"):
        if kind == pcFile:
            let id = parseInt(path.substr(4).split('_')[0])
            if id == post.id:
                let text = readFile(path)
                # The body starts after the first blank line
                let split = text.split(re("-[\\s]*"), 1)
                if split.len < 2:
                    raise Defect.newException("Couldn't find the '-' delimiter while parsing \"" & path & "\"")
                post.body = split[1]
                # # Parse the Markdown right away
                # post.body = 
                let title_and_desc = get_title_and_desc(text)
                post.title = title_and_desc[0]
                post.desc = title_and_desc[1]
                # echo &"{post.title}, {post.desc}"
                post.filename = splitFile(path).name
                post_exists = true
                break

    if not post_exists:
        return none(Post)

    post.num_words = post.body.split(re("\\s")).len
    # If the post was previously published,
    # get its original publication date
    # (Otherwise we won't define `published`
    # until the "p" command is used)
    if fileExists("posts/" & post.filename & ".html"):
        let file = open("posts/" & post.filename & ".html")
        post.publish_date = some(file.getFileInfo().lastWriteTime.local())
        file.close()
    else:
        post.publish_date = none(DateTime)

    return some(post)