import gleam/string
import gleam/string_builder
import lustre/attribute.{attribute, class, href, name, rel, src, type_}
import lustre/element
import lustre/element/html.{
  body, div, head, html, link, meta, script, text, title,
}
import wisp

pub fn style(classes: List(String)) {
  class(string.join(classes, " "))
}

pub fn index(_request: wisp.Request) -> wisp.Response {
  let page =
    html([], [
      head([], [
        title([], "index"),
        meta([attribute("charset", "utf-8")]),
        meta([
          name("viewport"),
          attribute("content", "width=device-width, initial-scale=1"),
        ]),
        link([rel("stylesheet"), href("/app.css")]),
        script([type_("module"), src("/app.js")], ""),
      ]),
      body([style(["p-4"])], [div([style(["text-rose-800"])], [text("Hei")])]),
    ])

  let rendered =
    element.to_string_builder(page)
    |> string_builder.prepend("<!DOCTYPE html>")

  wisp.ok()
  |> wisp.html_body(rendered)
}
