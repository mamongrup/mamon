import envoy
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import pog

pub type Database =
  Option(pog.Connection)

pub type Entry {
  Entry(
    id: Int,
    title: String,
    slug: String,
    summary: String,
    body: String,
    seo_title: String,
    seo_description: String,
  )
}

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
    "CREATE TABLE IF NOT EXISTS site_content (content_key TEXT PRIMARY KEY, content_value TEXT NOT NULL, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS contact_requests (id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL, area TEXT NOT NULL, message TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'new', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS admin_users (id BIGSERIAL PRIMARY KEY, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, display_name TEXT NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS pages (id BIGSERIAL PRIMARY KEY, title TEXT NOT NULL, slug TEXT UNIQUE NOT NULL, summary TEXT NOT NULL DEFAULT '', body TEXT NOT NULL DEFAULT '', seo_title TEXT NOT NULL DEFAULT '', seo_description TEXT NOT NULL DEFAULT '', is_published BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS projects (id BIGSERIAL PRIMARY KEY, title TEXT NOT NULL, slug TEXT UNIQUE NOT NULL, summary TEXT NOT NULL DEFAULT '', body TEXT NOT NULL DEFAULT '', seo_title TEXT NOT NULL DEFAULT '', seo_description TEXT NOT NULL DEFAULT '', is_published BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE INDEX IF NOT EXISTS contact_requests_created_at_idx ON contact_requests (created_at DESC); CREATE INDEX IF NOT EXISTS pages_slug_idx ON pages (slug); CREATE INDEX IF NOT EXISTS projects_slug_idx ON projects (slug);",
  )
  |> pog.execute(on: connection)
  |> result.is_ok
}

fn entry_decoder() {
  use id <- decode.field(0, decode.int)
  use title <- decode.field(1, decode.string)
  use slug <- decode.field(2, decode.string)
  use summary <- decode.field(3, decode.string)
  use body <- decode.field(4, decode.string)
  use seo_title <- decode.field(5, decode.string)
  use seo_description <- decode.field(6, decode.string)
  decode.success(Entry(
    id,
    title,
    slug,
    summary,
    body,
    seo_title,
    seo_description,
  ))
}

pub fn list_entries(database: Database, table: String) -> List(Entry) {
  case database, table {
    Some(connection), "pages" | Some(connection), "projects" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description FROM "
        <> table
        <> " ORDER BY created_at DESC",
      )
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
    _, _ -> []
  }
}

pub fn find_entry(
  database: Database,
  table: String,
  slug: String,
) -> Option(Entry) {
  case database, table {
    Some(connection), "pages" | Some(connection), "projects" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description FROM "
        <> table
        <> " WHERE slug = $1 AND is_published = TRUE LIMIT 1",
      )
      |> pog.parameter(pog.text(slug))
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
      |> list.first
      |> option.from_result
    _, _ -> None
  }
}

pub fn create_entry(
  database: Database,
  table: String,
  title: String,
  slug: String,
  summary: String,
  body: String,
  seo_title: String,
  seo_description: String,
) -> Bool {
  case database, table {
    Some(connection), "pages" | Some(connection), "projects" ->
      pog.query(
        "INSERT INTO "
        <> table
        <> " (title, slug, summary, body, seo_title, seo_description) VALUES ($1, $2, $3, $4, $5, $6)",
      )
      |> pog.parameter(pog.text(title))
      |> pog.parameter(pog.text(slug))
      |> pog.parameter(pog.text(summary))
      |> pog.parameter(pog.text(body))
      |> pog.parameter(pog.text(seo_title))
      |> pog.parameter(pog.text(seo_description))
      |> pog.execute(on: connection)
      |> result.is_ok
    _, _ -> False
  }
}

pub fn delete_entry(database: Database, table: String, id: Int) -> Bool {
  case database, table {
    Some(connection), "pages" | Some(connection), "projects" ->
      pog.query("DELETE FROM " <> table <> " WHERE id = $1")
      |> pog.parameter(pog.int(id))
      |> pog.execute(on: connection)
      |> result.is_ok
    _, _ -> False
  }
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
