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
    category: String,
  )
}

pub type AdminUser {
  AdminUser(id: Int, email: String, display_name: String, is_active: Bool)
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
      let _ = migrate_v2(connection)
      Some(connection)
    }
    Error(_) -> {
      io.println("DATABASE_URL bulunamadı; uygulama veritabanı olmadan başladı")
      None
    }
  }
}

fn migrate_v2(connection: pog.Connection) -> Bool {
  pog.query(
    "ALTER TABLE pages ADD COLUMN IF NOT EXISTS category TEXT NOT NULL DEFAULT 'sayfa'",
  )
  |> pog.execute(on: connection)
  |> result.is_ok
}

fn migrate(connection: pog.Connection) -> Bool {
  pog.query(
    "CREATE TABLE IF NOT EXISTS site_content (content_key TEXT PRIMARY KEY, content_value TEXT NOT NULL, updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS contact_requests (id BIGSERIAL PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL, area TEXT NOT NULL, message TEXT NOT NULL, status TEXT NOT NULL DEFAULT 'new', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS admin_users (id BIGSERIAL PRIMARY KEY, email TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL, display_name TEXT NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS password_reset_tokens (id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE, token_hash TEXT UNIQUE NOT NULL, expires_at TIMESTAMPTZ NOT NULL, used_at TIMESTAMPTZ, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS pages (id BIGSERIAL PRIMARY KEY, title TEXT NOT NULL, slug TEXT UNIQUE NOT NULL, summary TEXT NOT NULL DEFAULT '', body TEXT NOT NULL DEFAULT '', seo_title TEXT NOT NULL DEFAULT '', seo_description TEXT NOT NULL DEFAULT '', is_published BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE TABLE IF NOT EXISTS projects (id BIGSERIAL PRIMARY KEY, title TEXT NOT NULL, slug TEXT UNIQUE NOT NULL, summary TEXT NOT NULL DEFAULT '', body TEXT NOT NULL DEFAULT '', seo_title TEXT NOT NULL DEFAULT '', seo_description TEXT NOT NULL DEFAULT '', is_published BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()); CREATE INDEX IF NOT EXISTS contact_requests_created_at_idx ON contact_requests (created_at DESC); CREATE INDEX IF NOT EXISTS pages_slug_idx ON pages (slug); CREATE INDEX IF NOT EXISTS projects_slug_idx ON projects (slug); CREATE INDEX IF NOT EXISTS password_reset_tokens_hash_idx ON password_reset_tokens (token_hash);",
  )
  |> pog.execute(on: connection)
  |> result.is_ok
}

fn admin_user_decoder() {
  use id <- decode.field(0, decode.int)
  use email <- decode.field(1, decode.string)
  use display_name <- decode.field(2, decode.string)
  use is_active <- decode.field(3, decode.bool)
  decode.success(AdminUser(id, email, display_name, is_active))
}

pub fn admin_count(database: Database) -> Int {
  case database {
    Some(connection) ->
      pog.query("SELECT COUNT(*)::INTEGER FROM admin_users")
      |> pog.returning({
        use count <- decode.field(0, decode.int)
        decode.success(count)
      })
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows |> list.first |> result.unwrap(0) })
      |> result.unwrap(0)
    None -> 0
  }
}

pub fn create_admin(
  database: Database,
  email: String,
  password_hash: String,
  display_name: String,
  active: Bool,
) -> Bool {
  case database {
    Some(connection) ->
      pog.query(
        "INSERT INTO admin_users (email, password_hash, display_name, is_active) SELECT $1, $2, $3, $4 WHERE NOT EXISTS (SELECT 1 FROM admin_users) ON CONFLICT (email) DO NOTHING RETURNING id",
      )
      |> pog.parameter(pog.text(email))
      |> pog.parameter(pog.text(password_hash))
      |> pog.parameter(pog.text(display_name))
      |> pog.parameter(pog.bool(active))
      |> pog.returning({
        use id <- decode.field(0, decode.int)
        decode.success(id)
      })
      |> pog.execute(on: connection)
      |> result.map(fn(data) { list.length(data.rows) == 1 })
      |> result.unwrap(False)
    None -> False
  }
}

pub fn find_admin_by_email(
  database: Database,
  email: String,
) -> Option(#(AdminUser, String)) {
  case database {
    Some(connection) ->
      pog.query(
        "SELECT id, email, display_name, is_active, password_hash FROM admin_users WHERE email = $1 LIMIT 1",
      )
      |> pog.parameter(pog.text(email))
      |> pog.returning({
        use id <- decode.field(0, decode.int)
        use found_email <- decode.field(1, decode.string)
        use display_name <- decode.field(2, decode.string)
        use is_active <- decode.field(3, decode.bool)
        use password_hash <- decode.field(4, decode.string)
        decode.success(#(
          AdminUser(id, found_email, display_name, is_active),
          password_hash,
        ))
      })
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
      |> list.first
      |> option.from_result
    None -> None
  }
}

pub fn find_active_admin(database: Database, id: Int) -> Option(AdminUser) {
  case database {
    Some(connection) ->
      pog.query(
        "SELECT id, email, display_name, is_active FROM admin_users WHERE id = $1 AND is_active = TRUE LIMIT 1",
      )
      |> pog.parameter(pog.int(id))
      |> pog.returning(admin_user_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
      |> list.first
      |> option.from_result
    None -> None
  }
}

pub fn create_password_reset(
  database: Database,
  email: String,
  token_hash: String,
) -> Bool {
  case database {
    Some(connection) ->
      pog.query(
        "INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) SELECT id, $2, NOW() + INTERVAL '30 minutes' FROM admin_users WHERE email = $1 AND is_active = TRUE RETURNING id",
      )
      |> pog.parameter(pog.text(email))
      |> pog.parameter(pog.text(token_hash))
      |> pog.returning({
        use id <- decode.field(0, decode.int)
        decode.success(id)
      })
      |> pog.execute(on: connection)
      |> result.map(fn(data) { list.length(data.rows) == 1 })
      |> result.unwrap(False)
    None -> False
  }
}

pub fn reset_password(
  database: Database,
  token_hash: String,
  password_hash: String,
) -> Bool {
  case database {
    Some(connection) ->
      pog.query(
        "WITH valid AS (DELETE FROM password_reset_tokens WHERE token_hash = $1 AND expires_at > NOW() AND used_at IS NULL RETURNING user_id) UPDATE admin_users SET password_hash = $2 WHERE id IN (SELECT user_id FROM valid) RETURNING id",
      )
      |> pog.parameter(pog.text(token_hash))
      |> pog.parameter(pog.text(password_hash))
      |> pog.returning({
        use id <- decode.field(0, decode.int)
        decode.success(id)
      })
      |> pog.execute(on: connection)
      |> result.map(fn(data) { list.length(data.rows) == 1 })
      |> result.unwrap(False)
    None -> False
  }
}

fn entry_decoder() {
  use id <- decode.field(0, decode.int)
  use title <- decode.field(1, decode.string)
  use slug <- decode.field(2, decode.string)
  use summary <- decode.field(3, decode.string)
  use body <- decode.field(4, decode.string)
  use seo_title <- decode.field(5, decode.string)
  use seo_description <- decode.field(6, decode.string)
  use category <- decode.field(7, decode.string)
  decode.success(Entry(
    id,
    title,
    slug,
    summary,
    body,
    seo_title,
    seo_description,
    category,
  ))
}

pub fn list_entries(database: Database, table: String) -> List(Entry) {
  case database, table {
    Some(connection), "pages" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, COALESCE(category, 'sayfa') FROM pages ORDER BY created_at DESC",
      )
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
    Some(connection), "projects" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, 'projeler' FROM projects ORDER BY created_at DESC",
      )
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
    _, _ -> []
  }
}

pub fn list_published_entries(
  database: Database,
  table: String,
) -> List(Entry) {
  case database, table {
    Some(connection), "pages" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, COALESCE(category, 'sayfa') FROM pages WHERE is_published = TRUE ORDER BY created_at DESC",
      )
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
    Some(connection), "projects" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, 'projeler' FROM projects WHERE is_published = TRUE ORDER BY created_at DESC",
      )
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
    _, _ -> []
  }
}

pub fn list_entries_by_category(
  database: Database,
  category: String,
) -> List(Entry) {
  case database {
    Some(connection) ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, COALESCE(category, 'sayfa') FROM pages WHERE category = $1 AND is_published = TRUE ORDER BY created_at DESC",
      )
      |> pog.parameter(pog.text(category))
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
    None -> []
  }
}

pub fn list_all_pages(database: Database) -> List(Entry) {
  case database {
    Some(connection) ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, COALESCE(category, 'sayfa') FROM pages ORDER BY category, created_at DESC",
      )
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
    None -> []
  }
}

pub fn find_entry(
  database: Database,
  table: String,
  slug: String,
) -> Option(Entry) {
  case database, table {
    Some(connection), "pages" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, COALESCE(category, 'sayfa') FROM pages WHERE slug = $1 AND is_published = TRUE LIMIT 1",
      )
      |> pog.parameter(pog.text(slug))
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
      |> list.first
      |> option.from_result
    Some(connection), "projects" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, 'projeler' FROM projects WHERE slug = $1 AND is_published = TRUE LIMIT 1",
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

pub fn find_entry_by_id(
  database: Database,
  table: String,
  id: Int,
) -> Option(Entry) {
  case database, table {
    Some(connection), "pages" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, COALESCE(category, 'sayfa') FROM pages WHERE id = $1 LIMIT 1",
      )
      |> pog.parameter(pog.int(id))
      |> pog.returning(entry_decoder())
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows })
      |> result.unwrap([])
      |> list.first
      |> option.from_result
    Some(connection), "projects" ->
      pog.query(
        "SELECT id, title, slug, summary, body, seo_title, seo_description, 'projeler' FROM projects WHERE id = $1 LIMIT 1",
      )
      |> pog.parameter(pog.int(id))
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
    Some(connection), "pages" ->
      pog.query(
        "INSERT INTO pages (title, slug, summary, body, seo_title, seo_description, category) VALUES ($1, $2, $3, $4, $5, $6, $7)",
      )
      |> pog.parameter(pog.text(title))
      |> pog.parameter(pog.text(slug))
      |> pog.parameter(pog.text(summary))
      |> pog.parameter(pog.text(body))
      |> pog.parameter(pog.text(seo_title))
      |> pog.parameter(pog.text(seo_description))
      |> pog.parameter(pog.text("sayfa"))
      |> pog.execute(on: connection)
      |> result.is_ok
    Some(connection), "projects" ->
      pog.query(
        "INSERT INTO projects (title, slug, summary, body, seo_title, seo_description) VALUES ($1, $2, $3, $4, $5, $6)",
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

pub fn create_page(
  database: Database,
  title: String,
  slug: String,
  summary: String,
  body: String,
  seo_title: String,
  seo_description: String,
  category: String,
) -> Bool {
  case database {
    Some(connection) ->
      pog.query(
        "INSERT INTO pages (title, slug, summary, body, seo_title, seo_description, category) VALUES ($1, $2, $3, $4, $5, $6, $7)",
      )
      |> pog.parameter(pog.text(title))
      |> pog.parameter(pog.text(slug))
      |> pog.parameter(pog.text(summary))
      |> pog.parameter(pog.text(body))
      |> pog.parameter(pog.text(seo_title))
      |> pog.parameter(pog.text(seo_description))
      |> pog.parameter(pog.text(category))
      |> pog.execute(on: connection)
      |> result.is_ok
    None -> False
  }
}

pub fn update_entry(
  database: Database,
  table: String,
  id: Int,
  title: String,
  slug: String,
  summary: String,
  body: String,
  seo_title: String,
  seo_description: String,
) -> Bool {
  case database, table {
    Some(connection), "pages" ->
      pog.query(
        "UPDATE pages SET title = $2, slug = $3, summary = $4, body = $5, seo_title = $6, seo_description = $7, updated_at = NOW() WHERE id = $1",
      )
      |> pog.parameter(pog.int(id))
      |> pog.parameter(pog.text(title))
      |> pog.parameter(pog.text(slug))
      |> pog.parameter(pog.text(summary))
      |> pog.parameter(pog.text(body))
      |> pog.parameter(pog.text(seo_title))
      |> pog.parameter(pog.text(seo_description))
      |> pog.execute(on: connection)
      |> result.is_ok
    Some(connection), "projects" ->
      pog.query(
        "UPDATE projects SET title = $2, slug = $3, summary = $4, body = $5, seo_title = $6, seo_description = $7, updated_at = NOW() WHERE id = $1",
      )
      |> pog.parameter(pog.int(id))
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

pub fn update_page(
  database: Database,
  id: Int,
  title: String,
  slug: String,
  summary: String,
  body: String,
  seo_title: String,
  seo_description: String,
  category: String,
) -> Bool {
  case database {
    Some(connection) ->
      pog.query(
        "UPDATE pages SET title = $2, slug = $3, summary = $4, body = $5, seo_title = $6, seo_description = $7, category = $8, updated_at = NOW() WHERE id = $1",
      )
      |> pog.parameter(pog.int(id))
      |> pog.parameter(pog.text(title))
      |> pog.parameter(pog.text(slug))
      |> pog.parameter(pog.text(summary))
      |> pog.parameter(pog.text(body))
      |> pog.parameter(pog.text(seo_title))
      |> pog.parameter(pog.text(seo_description))
      |> pog.parameter(pog.text(category))
      |> pog.execute(on: connection)
      |> result.is_ok
    None -> False
  }
}

pub fn seed_page(
  database: Database,
  title: String,
  slug: String,
  summary: String,
  body: String,
  seo_title: String,
  seo_description: String,
  category: String,
) -> Bool {
  case database {
    Some(connection) ->
      pog.query(
        "INSERT INTO pages (title, slug, summary, body, seo_title, seo_description, category) VALUES ($1, $2, $3, $4, $5, $6, $7) ON CONFLICT (slug) DO NOTHING",
      )
      |> pog.parameter(pog.text(title))
      |> pog.parameter(pog.text(slug))
      |> pog.parameter(pog.text(summary))
      |> pog.parameter(pog.text(body))
      |> pog.parameter(pog.text(seo_title))
      |> pog.parameter(pog.text(seo_description))
      |> pog.parameter(pog.text(category))
      |> pog.execute(on: connection)
      |> result.is_ok
    None -> False
  }
}

pub fn delete_entry(database: Database, table: String, id: Int) -> Bool {
  case database, table {
    Some(connection), "pages" ->
      pog.query("DELETE FROM pages WHERE id = $1")
      |> pog.parameter(pog.int(id))
      |> pog.execute(on: connection)
      |> result.is_ok
    Some(connection), "projects" ->
      pog.query("DELETE FROM projects WHERE id = $1")
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

pub fn get_content(database: Database, key: String) -> String {
  case database {
    Some(connection) ->
      pog.query(
        "SELECT content_value FROM site_content WHERE content_key = $1 LIMIT 1",
      )
      |> pog.parameter(pog.text(key))
      |> pog.returning({
        use val <- decode.field(0, decode.string)
        decode.success(val)
      })
      |> pog.execute(on: connection)
      |> result.map(fn(data) { data.rows |> list.first |> result.unwrap("") })
      |> result.unwrap("")
    None -> ""
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

pub fn save_content(database: Database, key: String, value: String) -> Bool {
  case database {
    None -> False
    Some(connection) ->
      pog.query(
        "INSERT INTO site_content (content_key, content_value) VALUES ($1, $2) ON CONFLICT (content_key) DO UPDATE SET content_value = EXCLUDED.content_value, updated_at = NOW()",
      )
      |> pog.parameter(pog.text(key))
      |> pog.parameter(pog.text(value))
      |> pog.execute(on: connection)
      |> result.is_ok
  }
}
