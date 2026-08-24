import envoy
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/result

pub fn ask(message: String) -> Result(String, Nil) {
  use api_key <- result.try(envoy.get("DEEPSEEK_API_KEY"))
  let payload =
    json.object([
      #("model", json.string("deepseek-chat")),
      #(
        "messages",
        json.array(
          [
            #(
              "system",
              "Sen Mamon şirketinin turizm, emlak ve inşaat asistanısın. Kısa, profesyonel ve Türkçe yanıt ver. Bilmediğin fiyat, proje veya müsaitlik bilgisini uydurma; kullanıcıyı iletişim formuna yönlendir.",
            ),
            #("user", message),
          ],
          fn(item) {
            json.object([
              #("role", json.string(item.0)),
              #("content", json.string(item.1)),
            ])
          },
        ),
      ),
      #("temperature", json.float(0.3)),
      #("max_tokens", json.int(450)),
    ])
  use base <- result.try(request.to("https://api.deepseek.com/chat/completions"))
  let req =
    base
    |> request.set_method(Post)
    |> request.set_header("authorization", "Bearer " <> api_key)
    |> request.set_header("content-type", "application/json")
    |> request.set_body(json.to_string(payload))
  use response <- result.try(httpc.send(req) |> result.map_error(fn(_) { Nil }))
  use _ <- result.try(case response.status == 200 {
    True -> Ok(Nil)
    False -> Error(Nil)
  })
  let message_decoder = {
    use content <- decode.field("content", decode.string)
    decode.success(content)
  }
  let choice_decoder = {
    use content <- decode.field("message", message_decoder)
    decode.success(content)
  }
  let response_decoder = {
    use choices <- decode.field("choices", decode.list(choice_decoder))
    decode.success(choices)
  }
  use choices <- result.try(
    json.parse(response.body, response_decoder)
    |> result.map_error(fn(_) { Nil }),
  )
  list.first(choices) |> result.map_error(fn(_) { Nil })
}
