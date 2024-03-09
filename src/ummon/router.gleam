import gleam/http
import ummon/page
import wisp

pub fn service(request: wisp.Request, assets: String) {
  use <- wisp.serve_static(request, under: "/", from: assets)
  use <- wisp.log_request(request)
  use <- wisp.rescue_crashes

  case request.method, wisp.path_segments(request) {
    http.Get, [] -> page.index(request)
    _method, _path -> wisp.not_found()
  }
}
