import extra
import gleam/bit_array
import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/uri

const default_config = Config(
  auto_redirect: True,
  ca_certs: option.None,
  timeout: Millis(10_000),
)

pub type Request(body) =
  request.Request(option.Option(body))

pub type Response =
  response.Response(BitArray)

pub opaque type Error {
  BodyError(BitArray)
  JsonError(json.DecodeError)
  RequestError(Dynamic)
  StatusError(Int, BitArray)
  UriError(String)
}

pub type Timeout {
  Infinity
  Millis(Int)
}

pub opaque type Config {
  Config(auto_redirect: Bool, ca_certs: option.Option(String), timeout: Timeout)
}

pub type Option =
  fn(Config) -> Config

pub fn auto_redirect(enabled: Bool) -> Option {
  fn(config) { Config(..config, auto_redirect: enabled) }
}

pub fn ca_certs(path: String) -> Option {
  fn(config) { Config(..config, ca_certs: option.Some(path)) }
}

pub fn timeout(timeout: Timeout) -> Option {
  fn(config) { Config(..config, timeout: timeout) }
}

pub fn request(uri: String) -> Result(Request(a), Error) {
  use <- extra.return(result.replace_error(_, UriError(uri)))
  use uri <- result.try(uri.parse(uri))
  use request <- result.map(request.from_uri(uri))
  request.set_body(request, option.None)
}

pub fn send(
  request: Request(BitArray),
  options: List(Option),
) -> Result(Response, Error) {
  use response <- result.try(
    glue_send(request, options)
    |> result.map_error(RequestError),
  )

  use <- bool.guard(
    response.status < 200 || response.status >= 300,
    Error(StatusError(response.status, response.body)),
  )

  Ok(response)
}

pub fn bits(response: Response) -> Result(BitArray, Error) {
  Ok(response.body)
}

pub fn try_bits(response: Result(Response, Error)) -> Result(BitArray, Error) {
  result.try(response, bits)
}

pub fn string(response: Response) -> Result(String, Error) {
  bit_array.to_string(response.body)
  |> result.replace_error(BodyError(response.body))
}

pub fn try_string(response: Result(Response, Error)) -> Result(String, Error) {
  result.try(response, string)
}

pub fn json(response: Response, decoder: dynamic.Decoder(v)) -> Result(v, Error) {
  json.decode_bits(response.body, decoder)
  |> result.map_error(JsonError)
}

pub fn try_json(
  response: Result(Response, Error),
  decoder: dynamic.Decoder(v),
) -> Result(v, Error) {
  result.try(response, json(_, decoder))
}

@external(erlang, "glue", "request")
fn glue_request(
  config: Config,
  method: http.Method,
  uri: String,
  headers: List(#(String, String)),
) -> Result(a, Dynamic)

@external(erlang, "glue", "request")
fn glue_request_with_body(
  config: Config,
  method: http.Method,
  uri: String,
  headers: List(#(String, String)),
  content_type: String,
  body: BitArray,
) -> Result(a, Dynamic)

fn glue_send(
  request: Request(BitArray),
  options: List(Option),
) -> Result(response.Response(_), Dynamic) {
  let config =
    list.fold(options, default_config, fn(config, update) { update(config) })
  let uri = uri.to_string(request.to_uri(request))

  case request.body {
    option.None -> glue_request(config, request.method, uri, request.headers)
    option.Some(body) -> {
      let content_type =
        request.get_header(request, "content-type")
        |> result.unwrap("application/octet-stream")
      glue_request_with_body(
        config,
        request.method,
        uri,
        request.headers,
        content_type,
        body,
      )
    }
  }
}
