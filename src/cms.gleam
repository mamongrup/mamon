import database.{type Database, type Entry, Entry}
import gleam/int
import gleam/list
import gleam/string

pub fn escape(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
  |> string.replace("'", "&#39;")
}

pub fn entry_page(entry: Entry, kind: String) -> String {
  let Entry(_, title, slug, summary, body, seo_title, seo_description) = entry
  let final_title = case seo_title {
    "" -> title <> " | Mamon"
    _ -> seo_title
  }
  let final_description = case seo_description {
    "" -> summary
    _ -> seo_description
  }
  "<!doctype html><html lang='tr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>"
  <> escape(final_title)
  <> "</title><meta name='description' content='"
  <> escape(final_description)
  <> "'><link rel='canonical' href='https://mamon.tr/"
  <> kind
  <> "/"
  <> escape(slug)
  <> "'><meta property='og:type' content='article'><meta property='og:title' content='"
  <> escape(final_title)
  <> "'><meta property='og:description' content='"
  <> escape(final_description)
  <> "'><meta property='og:url' content='https://mamon.tr/"
  <> kind
  <> "/"
  <> escape(slug)
  <> "'><link rel='stylesheet' href='/static/styles.css'></head><body><header class='top'><a class='brand' href='/'><i>M</i>MAMON</a><a class='top-cta' href='/#contact'>Bizimle konuşun ↗</a></header><main class='detail'><span>"
  <> escape(kind)
  <> "</span><h1>"
  <> escape(title)
  <> "</h1><p class='lead'>"
  <> escape(summary)
  <> "</p><article>"
  <> escape(body)
  <> "</article><a class='btn dark' href='/'>← Ana sayfa</a></main></body></html>"
}

pub fn admin_entries(database: Database, table: String) -> String {
  let label = case table {
    "pages" -> "Sayfalar"
    _ -> "Projeler"
  }
  let rows =
    database.list_entries(database, table)
    |> list.map(fn(entry) {
      let Entry(id, title, slug, _, _, _, _) = entry
      "<tr id='entry-"
      <> int.to_string(id)
      <> "'><td><b>"
      <> escape(title)
      <> "</b><small>/"
      <> escape(slug)
      <> "</small></td><td><span class='status'>● YAYINDA</span></td><td><button class='delete' hx-post='/admin/"
      <> table
      <> "/"
      <> int.to_string(id)
      <> "/delete' hx-target='#entry-"
      <> int.to_string(id)
      <> "' hx-swap='outerHTML' hx-confirm='Bu kaydı silmek istediğinize emin misiniz?'>Sil</button></td></tr>"
    })
    |> string.join("")
  "<!doctype html><html lang='tr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Mamon Yönetim — "
  <> label
  <> "</title><link rel='stylesheet' href='/static/styles.css'><link rel='stylesheet' href='/static/admin.css'><script src='https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js' defer></script></head><body class='admin-body'><aside><a class='brand' href='/'><i>M</i>MAMON</a><small>YÖNETİM PANELİ</small><nav><a href='/admin'>⌂ Genel Bakış</a><a href='/admin/pages'>▤ Sayfalar</a><a href='/admin/projects'>◈ Projeler</a></nav><form class='logout-form' method='post' action='/admin/logout'><button>Oturumu kapat</button></form><a class='back' href='/'>← Siteye dön</a></aside><main class='admin-main'><header><div><small>İÇERİK YÖNETİMİ</small><h1>"
  <> label
  <> "</h1></div></header><section class='admin-grid cms-grid'><div class='panel'><header><div><small>YAYINDAKİ KAYITLAR</small><h2>"
  <> label
  <> "</h2></div></header><table class='cms-table'><tbody>"
  <> rows
  <> "</tbody></table></div><div class='panel'><header><div><small>YENİ KAYIT</small><h2>"
  <> label
  <> " oluştur</h2></div></header><form class='cms-form' hx-post='/admin/"
  <> table
  <> "' hx-target='body' hx-push-url='true'><label>Başlık<input required name='title'></label><label>URL kısa adı<input required name='slug' placeholder='ornek-sayfa'></label><label>Kısa açıklama<textarea name='summary'></textarea></label><label>İçerik<textarea name='body'></textarea></label><label>SEO başlığı<input name='seo_title'></label><label>Meta açıklaması<textarea name='seo_description' maxlength='160'></textarea></label><button class='btn accent'>Kaydet ve yayınla</button></form></div></section></main></body></html>"
}

pub fn sitemap(database: Database) -> String {
  let urls =
    [#("pages", "sayfa"), #("projects", "projeler")]
    |> list.flat_map(fn(pair) {
      database.list_entries(database, pair.0)
      |> list.map(fn(entry) {
        let Entry(_, _, slug, _, _, _, _) = entry
        "<url><loc>https://mamon.tr/"
        <> pair.1
        <> "/"
        <> escape(slug)
        <> "</loc><changefreq>weekly</changefreq></url>"
      })
    })
    |> string.join("")
  "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'><url><loc>https://mamon.tr/</loc><changefreq>weekly</changefreq><priority>1.0</priority></url>"
  <> urls
  <> "</urlset>"
}
