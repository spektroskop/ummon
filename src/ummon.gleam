import gleam/erlang/process
import gleam/io
import gleam/result
import mist
import ummon/router
import ummon/web
import wisp

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = wisp.random_string(64)
  let assert Ok(assets) = wisp.priv_directory("ummon")
  let router = router.service(_, assets)

  wisp.mist_handler(router, secret_key_base)
  |> mist.new
  |> mist.port(7788)
  |> mist.start_http

  io.debug({
    use request <- result.try(web.request("http://localhost:7788"))
    use response <- result.try(
      web.send(request, [
        web.ca_certs("/etc/ssl/cert.pem"),
        web.timeout(web.Millis(1000)),
      ]),
    )

    web.string(response)
  })

  process.sleep_forever()
}
