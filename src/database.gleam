import envoy
import gleam/erlang/process
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import pog

pub type Database =
  Option(pog.Connection)

pub fn connect() -> Database {
  let connection = {
    use url <- result.try(envoy.get("DATABASE_URL"))
    let name = process.new_name("mamon_postgres")
    use config <- result.try(pog.url_config(name, url))
    use started <- result.try(
      pog.start(pog.pool_size(config, 10)) |> result.map_error(fn(_) { Nil }),
    )
    let actor.Started(_, connection) = started
    Ok(connection)
  }
  case connection {
    Ok(connection) -> {
      io.println("PostgreSQL bağlantı havuzu hazır")
      let _ = migrate(connection)
      Some(connection)
    }
    Error(_) -> {
      io.println("DATABASE_URL bulunamadı; uygulama veritabanı olmadan başladı")
      None
    }
  }
}

fn migrate(connection: pog.Connection) -> Bool {
  pog.query(
    "CREATE TABLE IF NOT EXISTS site_content (content_key TEXT PRIMARY KEY, content_value TEXT NOT NULL, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS contact_requests (id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL, area TEXT NOT NULL, message TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'new', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS admin_users (id BIGSERIAL PRIMARY KEY, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, display_name TEXT NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE INDEX IF NOT EXISTS contact_requests_created_at_idx ON contact_requests (created_at DESC);",
  )
  |> pog.execute(on: connection)
  |> result.is_ok
}

pub fn save_contact(
  database: Database,
  name: String,
  email: String,
  area: String,
  message: String,
) -> Bool {
  case database {
    None -> False
    Some(connection) ->
      pog.query(
        "INSERT INTO contact_requests (name, email, area, message) VALUES ($1, $2, $3, $4)",
      )
      |> pog.parameter(pog.text(name))
      |> pog.parameter(pog.text(email))
      |> pog.parameter(pog.text(area))
      |> pog.parameter(pog.text(message))
      |> pog.execute(on: connection)
      |> result.is_ok
  }
}

pub fn save_home_content(
  database: Database,
  eyebrow: String,
  title: String,
  description: String,
  cta: String,
  url: String,
) -> Bool {
  case database {
    None -> False
    Some(connection) ->
      pog.query(
        "INSERT INTO site_content (content_key, content_value) VALUES ('home.eyebrow', $1), ('home.title', $2), ('home.description', $3), ('home.cta', $4), ('home.url', $5) ON CONFLICT (content_key) DO UPDATE SET content_value = EXCLUDED.content_value, updated_at = NOW()",
      )
      |> pog.parameter(pog.text(eyebrow))
      |> pog.parameter(pog.text(title))
      |> pog.parameter(pog.text(description))
      |> pog.parameter(pog.text(cta))
      |> pog.parameter(pog.text(url))
      |> pog.execute(on: connection)
      |> result.is_ok
  }
}
