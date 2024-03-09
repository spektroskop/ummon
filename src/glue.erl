-module(glue).

-export([request/4, request/6]).

request(Config, Method, Url, Headers) ->
    Url2 = binary_to_list(Url),
    Headers2 = [{binary_to_list(K), binary_to_list(V)} || {K, V} <- Headers],
    httpc_request(Config, Method, {Url2, Headers2}).

request(Config, Method, Url, Headers, ContentType, Body) ->
    Url2 = binary_to_list(Url),
    Headers2 = [{binary_to_list(K), binary_to_list(V)} || {K, V} <- Headers],
    ContentType2 = binary_to_list(ContentType),
    httpc_request(Config, Method, {Url2, Headers2, ContentType2, Body}).

httpc_request(Config, Method, Request) ->
    {config, Redirect, Certs, Timeout} = Config,
    Options = [{body_format, binary}],
    HttpOptions = [{autoredirect, Redirect}, {ssl, ssl_options(Certs)}, timeout(Timeout)],
    case httpc:request(Method, Request, HttpOptions, Options) of
        {ok, {{_Version, Code, _Status}, Headers, Body}} ->
            Headers2 = [{list_to_binary(string:lowercase(K)),
                list_to_binary(V)} || {K, V} <- Headers],
            {ok, {response, Code, Headers2, Body}};
        {error, Error} -> {error, Error}
    end.

timeout({millis, Millis}) -> {timeout, Millis};
timeout(infinity) -> {timeout, infinity}.

ssl_options(Certs) ->
    Common = [{verify, verify_peer}, {customize_hostname_check, [
        {match_fun, public_key:pkix_verify_hostname_match_fun(https)}
    ]}],
    case Certs of
        none -> [{cacerts, public_key:cacerts_get()} | Common];
        {some, Path} -> [{cacertfile, Path} | Common]
    end.
