import gleam/bit_array
import gleam/crypto
import gleam/int
import gleam/string

const iterations = 210_000

@external(erlang, "auth_ffi", "pbkdf2")
fn pbkdf2(password: String, salt: BitArray, iterations: Int) -> BitArray

pub fn hash_password(password: String) -> String {
  let salt = crypto.strong_random_bytes(16)
  let digest = pbkdf2(password, salt, iterations)
  "pbkdf2_sha256$"
  <> int.to_string(iterations)
  <> "$"
  <> bit_array.base64_url_encode(salt, False)
  <> "$"
  <> bit_array.base64_url_encode(digest, False)
}

pub fn verify_password(password: String, encoded: String) -> Bool {
  case string.split(encoded, on: "$") {
    ["pbkdf2_sha256", rounds, salt, expected] -> {
      use rounds <- bool_result(int.parse(rounds))
      use salt <- bool_result(bit_array.base64_url_decode(salt))
      use expected <- bool_result(bit_array.base64_url_decode(expected))
      crypto.secure_compare(pbkdf2(password, salt, rounds), expected)
    }
    _ -> False
  }
}

fn bool_result(value: Result(a, Nil), next: fn(a) -> Bool) -> Bool {
  case value {
    Ok(value) -> next(value)
    Error(_) -> False
  }
}

pub fn random_token() -> String {
  crypto.strong_random_bytes(32)
  |> bit_array.base64_url_encode(False)
}

pub fn token_digest(token: String) -> String {
  crypto.hash(crypto.Sha256, <<token:utf8>>)
  |> bit_array.base64_url_encode(False)
}

pub fn valid_email(email: String) -> Bool {
  let email = string.trim(email)
  string.contains(email, "@")
  && !string.contains(email, "\n")
  && !string.contains(email, "\r")
  && string.length(email) <= 254
}

pub fn valid_password(password: String) -> Bool {
  string.length(password) >= 12
}

pub fn normalize_email(email: String) -> String {
  email |> string.trim |> string.lowercase
}
