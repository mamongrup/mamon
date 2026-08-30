import gleam/bit_array
import gleam/crypto
import gleam/http/request
import gleam/result
import wisp

pub fn generate_token() -> String {
  crypto.strong_random_bytes(32)
  |> bit_array.base64_url_encode(False)
}

pub fn get_token(req: wisp.Request) -> String {
  case wisp.get_cookie(req, "_csrf_token", wisp.Signed) {
    Error(_) -> generate_token()
    Ok(token) -> token
  }
}

pub fn validate(req: wisp.Request, submitted_token: String) -> Bool {
  case wisp.get_cookie(req, "_csrf_token", wisp.Signed) {
    Error(_) -> False
    Ok(cookie_token) ->
      crypto.secure_compare(<<submitted_token:utf8>>, <<cookie_token:utf8>>)
  }
}

pub fn validate_header(req: wisp.Request) -> Bool {
  case wisp.get_cookie(req, "_csrf_token", wisp.Signed) {
    Error(_) -> False
    Ok(cookie_token) -> {
      let header_token =
        request.get_header(req, "x-csrf-token") |> result.unwrap("")
      crypto.secure_compare(<<header_token:utf8>>, <<cookie_token:utf8>>)
    }
  }
}

pub fn hidden_field(token: String) -> String {
  "<input type='hidden' name='_csrf_token' value='" <> token <> "'>"
}
