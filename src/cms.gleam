import database.{type Database, type Entry, Entry}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string

pub fn escape(value: String) -> String {
  value
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\\\"", "&quot;")
  |> string.replace("'", "&#39;")
}

// --- Corporate site templates ---

fn active(current: String, path: String) -> String {
  case current == path {
    True -> " class='active'"
    False -> ""
  }
}

pub fn nav(current: String) -> String {
  "<header class='header'><a class='logo' href='/'><span class='logo-mark'><img src='/static/logo-icon.png' alt=''></span>MAMON</a><nav class='nav'><a"
  <> active(current, "/")
  <> " href='/'>Ana Sayfa</a><a"
  <> active(current, "/kurumsal/")
  <> " href='/kurumsal/'>Kurumsal</a><a"
  <> active(current, "/turizm/")
  <> " href='/turizm/'>Turizm</a><a"
  <> active(current, "/emlak/")
  <> " href='/emlak/'>Emlak</a><a"
  <> active(current, "/insaat/")
  <> " href='/insaat/'>İnşaat</a><a"
  <> active(current, "/projeler/")
  <> " href='/projeler/'>Projeler</a><a"
  <> active(current, "/iletisim/")
  <> " href='/iletisim/'>İletişim</a><a class='language' href='/en/'>EN</a></nav></header>"
}

const corporate_head = "<meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><link rel='icon' type='image/png' href='/static/favicon.png'><link rel='apple-touch-icon' href='/static/favicon.png'><link rel='manifest' href='/static/site.webmanifest'><meta name='theme-color' content='#06444c'><link rel='stylesheet' href='/static/corporate.css'><link rel='stylesheet' href='/static/logo.css'>"

pub const corporate_footer = "<footer class='footer'><div class='footer-grid'><div><a class='logo' href='/'><span class='logo-mark'><img src='/static/logo-icon.png' alt=''></span>MAMON</a><p>Turizm, emlak ve inşaatta köklü deneyim; güvenilir ortaklıklar.</p></div><div><h4>KURUMSAL</h4><nav><a href='/kurumsal/'>Hakkımızda</a><a href='/projeler/'>Projeler</a></nav></div><div><h4>FAALİYETLER</h4><nav><a href='/turizm/'>Turizm</a><a href='/emlak/'>Emlak</a><a href='/insaat/'>İnşaat</a></nav></div><div><h4>İLETİŞİM</h4><p>info@mamon.com.tr<br>Antalya, Türkiye</p></div></div><div class='footer-bottom'>© 2026 Mamon. Tüm hakları saklıdır.</div></footer>"

pub fn en_nav(current: String) -> String {
  "<header class='header'><a class='logo' href='/en/'><span class='logo-mark'><img src='/static/logo-icon.png' alt=''></span>MAMON</a><nav class='nav'><a"
  <> active(current, "/en/")
  <> " href='/en/'>Home</a><a"
  <> active(current, "/en/#about")
  <> " href='/en/#about'>Corporate</a><a"
  <> active(current, "/turizm/")
  <> " href='/turizm/'>Tourism</a><a"
  <> active(current, "/emlak/")
  <> " href='/emlak/'>Real Estate</a><a"
  <> active(current, "/insaat/")
  <> " href='/insaat/'>Construction</a><a"
  <> active(current, "/projeler/")
  <> " href='/projeler/'>Projects</a><a"
  <> active(current, "/iletisim/")
  <> " href='/iletisim/'>İletişim</a><a class='language' href='/'>TR</a></nav></header>"
}

pub const en_footer = "<footer class='footer'><div class='footer-grid'><div><a class='logo' href='/en/'><span class='logo-mark'><img src='/static/logo-icon.png' alt=''></span>MAMON</a><p>Tourism • Real Estate • Construction</p></div><div><h4>LANGUAGE</h4><nav><a href='/'>Türkçe</a><a href='/en/'>English</a></nav></div><div><h4>CONTACT</h4><p>info@mamon.com.tr<br>Antalya, Türkiye</p></div></div><div class='footer-bottom'>© 2026 Mamon</div></footer>"

pub fn page_template(
  entry: Entry,
  nav_html: String,
  footer_html: String,
) -> String {
  let Entry(
    _,
    title,
    _slug,
    summary,
    body,
    seo_title,
    seo_description,
    category,
  ) = entry
  let final_title = case seo_title {
    "" -> title <> " | Mamon"
    _ -> seo_title
  }
  let final_description = case seo_description {
    "" -> summary
    _ -> seo_description
  }
  let lang = case category {
    "en" -> "en"
    _ -> "tr"
  }
  let canonical_kind = case category {
    "anasayfa" -> ""
    other -> other
  }
  "<!doctype html><html lang='"
  <> lang
  <> "'><head>"
  <> corporate_head
  <> "<title>"
  <> escape(final_title)
  <> "</title><meta name='description' content='"
  <> escape(final_description)
  <> "'><link rel='canonical' href='https://mamon.tr/"
  <> canonical_kind
  <> case canonical_kind {
    "" -> ""
    _ -> "/"
  }
  <> "'></head><body>"
  <> nav_html
  <> "<main>"
  <> case category {
    "anasayfa" | "en" -> body
    _ ->
      "<section class='page-hero'><span class='overline'>"
      <> escape(string.uppercase(title))
      <> "</span><h1>"
      <> escape(title)
      <> "</h1>"
      <> case summary {
        "" -> ""
        _ -> "<p>" <> escape(summary) <> "</p>"
      }
      <> "</section><section class='content'>"
      <> body
      <> "</section>"
  }
  <> "</main>"
  <> footer_html
  <> "</body></html>"
}

pub fn entry_page(entry: Entry, kind: String) -> String {
  let Entry(
    _,
    title,
    slug,
    summary,
    body,
    seo_title,
    seo_description,
    _category,
  ) = entry
  let final_title = case seo_title {
    "" -> title <> " | Mamon"
    _ -> seo_title
  }
  let final_description = case seo_description {
    "" -> summary
    _ -> seo_description
  }
  let footer_html = case kind {
    "en" -> en_footer
    _ -> corporate_footer
  }
  let nav_html = case kind {
    "en" -> en_nav("/" <> kind <> "/" <> slug)
    _ -> nav("/" <> kind <> "/" <> slug)
  }
  "<!doctype html><html lang='tr'><head>"
  <> corporate_head
  <> "<title>"
  <> escape(final_title)
  <> "</title><meta name='description' content='"
  <> escape(final_description)
  <> "'><link rel='canonical' href='https://mamon.tr/"
  <> kind
  <> "/"
  <> escape(slug)
  <> "/'><meta property='og:type' content='article'><meta property='og:title' content='"
  <> escape(final_title)
  <> "'><meta property='og:description' content='"
  <> escape(final_description)
  <> "'><meta property='og:url' content='https://mamon.tr/"
  <> kind
  <> "/"
  <> escape(slug)
  <> "/'></head><body>"
  <> nav_html
  <> "<main class='detail'><span>"
  <> escape(kind)
  <> "</span><h1>"
  <> escape(title)
  <> "</h1><p class='lead'>"
  <> escape(summary)
  <> "</p><article>"
  <> escape(body)
  <> "</article><a class='btn dark' href='/'>← Ana sayfa</a></main>"
  <> footer_html
  <> "</body></html>"
}

pub fn projects_page(database: Database) -> String {
  let cards =
    database.list_published_entries(database, "projects")
    |> list.map(fn(entry) {
      let Entry(_, title, slug, summary, _, _, _, _) = entry
      "<article class='info-card'><h3>"
      <> escape(title)
      <> "</h3><p>"
      <> escape(summary)
      <> "</p><a class='button copper' href='/projeler/"
      <> escape(slug)
      <> "'>Projeyi inceleyin →</a></article>"
    })
    |> string.join("")
  "<!doctype html><html lang='tr'><head>"
  <> corporate_head
  <> "<title>Projeler | Mamon</title><meta name='description' content='Mamon projeleri'><link rel='canonical' href='https://mamon.tr/projeler/'></head><body>"
  <> nav("/projeler/")
  <> "<main><section class='page-hero'><span class='overline'>PROJELER</span><h1>Geleceğe bıraktığımız iz</h1></section><section class='content'><div class='cards-list'>"
  <> case cards {
    "" -> "<p>Yeni projeler çok yakında burada yayınlanacak.</p>"
    _ -> cards
  }
  <> "</div></section></main>"
  <> corporate_footer
  <> "</body></html>"
}

// --- Admin Panel ---

pub fn admin_entries(
  csrf_token: String,
  database: Database,
  table: String,
) -> String {
  let label = case table {
    "pages" -> "Sayfalar"
    _ -> "Projeler"
  }
  let hx =
    "hx-headers='" <> "{\"x-csrf-token\":\"" <> csrf_token <> "\"}" <> "'"
  let csrf_field =
    "<input type='hidden' name='_csrf_token' value='" <> csrf_token <> "'>"
  let rows = case table {
    "pages" -> {
      let all_pages = database.list_all_pages(database)
      list.map(all_pages, fn(entry) {
        let Entry(id, title, slug, _, _, _, _, category) = entry
        let category_label = case category {
          "anasayfa" -> "Ana Sayfa"
          "kurumsal" -> "Kurumsal"
          "turizm" -> "Turizm"
          "emlak" -> "Emlak"
          "insaat" -> "İnşaat"
          "iletisim" -> "İletişim"
          "en" -> "English"
          other -> other
        }
        "<tr id='entry-"
        <> int.to_string(id)
        <> "'><td><b>"
        <> escape(title)
        <> "</b><small>/"
        <> escape(slug)
        <> "</small></td><td><span class='category-badge'>"
        <> escape(category_label)
        <> "</span></td><td><span class='status'>● YAYINDA</span></td><td><a class='edit-link' href='/admin/pages/"
        <> int.to_string(id)
        <> "/edit'>Düzenle</a> <button class='delete' hx-post='/admin/"
        <> table
        <> "/"
        <> int.to_string(id)
        <> "/delete' hx-target='#entry-"
        <> int.to_string(id)
        <> "' hx-swap='outerHTML' hx-confirm='Bu kaydı silmek istediğinize emin misiniz?'>Sil</button></td></tr>"
      })
      |> string.join("")
    }
    _ -> {
      let entries = database.list_entries(database, table)
      list.map(entries, fn(entry) {
        let Entry(id, title, slug, _, _, _, _, _) = entry
        "<tr id='entry-"
        <> int.to_string(id)
        <> "'><td><b>"
        <> escape(title)
        <> "</b><small>/"
        <> escape(slug)
        <> "</small></td><td><span class='status'>● YAYINDA</span></td><td><a class='edit-link' href='/admin/projects/"
        <> int.to_string(id)
        <> "/edit'>Düzenle</a> <button class='delete' hx-post='/admin/"
        <> table
        <> "/"
        <> int.to_string(id)
        <> "/delete' hx-target='#entry-"
        <> int.to_string(id)
        <> "' hx-swap='outerHTML' hx-confirm='Bu kaydı silmek istediğinize emin misiniz?'>Sil</button></td></tr>"
      })
      |> string.join("")
    }
  }
  "<!doctype html><html lang='tr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Mamon Yönetim — "
  <> label
  <> "</title><link rel='stylesheet' href='/static/styles.css'><link rel='stylesheet' href='/static/admin.css'><script src='https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js' defer></script></head><body class='admin-body' "
  <> hx
  <> "><aside><a class='brand' href='/'><i>M</i>MAMON</a><small>YÖNETİM PANELİ</small><nav><a href='/admin'>⌂ Genel Bakış</a><a href='/admin/pages'>▤ Sayfalar</a><a href='/admin/projects'>◈ Projeler</a></nav><form class='logout-form' method='post' action='/admin/logout'>"
  <> csrf_field
  <> "<button>Oturumu kapat</button></form><a class='back' href='/'>← Siteye dön</a></aside><main class='admin-main'><header><div><small>İÇERİK YÖNETİMİ</small><h1>"
  <> label
  <> "</h1></div></header><section class='admin-grid cms-grid'><div class='panel'><header><div><small>YAYINDAKİ KAYITLAR</small><h2>"
  <> label
  <> "</h2></div></header><table class='cms-table'><tbody>"
  <> rows
  <> "</tbody></table></div><div class='panel'><header><div><small>YENİ KAYIT</small><h2>"
  <> label
  <> " oluştur</h2></div></header><form class='cms-form' hx-post='/admin/"
  <> table
  <> "' hx-target='body' hx-push-url='true'>"
  <> csrf_field
  <> case table {
    "pages" ->
      "<label>Kategori<select name='category'><option value='anasayfa'>Ana Sayfa</option><option value='kurumsal'>Kurumsal</option><option value='turizm'>Turizm</option><option value='emlak'>Emlak</option><option value='insaat'>İnşaat</option><option value='iletisim'>İletişim</option><option value='en'>English</option><option value='sayfa'>Diğer Sayfa</option></select></label>"
    _ -> ""
  }
  <> "<label>Başlık<input required name='title'></label><label>URL kısa adı<input required name='slug' placeholder='ornek-sayfa'></label><label>Kısa açıklama<textarea name='summary'></textarea></label><label>İçerik<textarea name='body' rows='12'></textarea></label><label>SEO başlığı<input name='seo_title'></label><label>Meta açıklaması<textarea name='seo_description' maxlength='160'></textarea></label><button class='btn accent'>Kaydet ve yayınla</button></form></div></section></main></body></html>"
}

pub fn admin_edit_page(
  csrf_token: String,
  database: Database,
  table: String,
  id: Int,
) -> String {
  let hx =
    "hx-headers='" <> "{\"x-csrf-token\":\"" <> csrf_token <> "\"}" <> "'"
  let csrf_field =
    "<input type='hidden' name='_csrf_token' value='" <> csrf_token <> "'>"
  case database.find_entry_by_id(database, table, id) {
    Some(entry) -> {
      let Entry(
        entry_id,
        title,
        slug,
        summary,
        body,
        seo_title,
        seo_description,
        category,
      ) = entry
      let category_label = case category {
        "anasayfa" -> "Ana Sayfa"
        "kurumsal" -> "Kurumsal"
        "turizm" -> "Turizm"
        "emlak" -> "Emlak"
        "insaat" -> "İnşaat"
        "iletisim" -> "İletişim"
        "en" -> "English"
        other -> other
      }
      "<!doctype html><html lang='tr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Mamon Yönetim — Düzenle</title><link rel='stylesheet' href='/static/styles.css'><link rel='stylesheet' href='/static/admin.css'><script src='https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js' defer></script></head><body class='admin-body' "
      <> hx
      <> "><aside><a class='brand' href='/'><i>M</i>MAMON</a><small>YÖNETİM PANELİ</small><nav><a href='/admin'>⌂ Genel Bakış</a><a href='/admin/pages'>▤ Sayfalar</a><a href='/admin/projects'>◈ Projeler</a></nav><form class='logout-form' method='post' action='/admin/logout'>"
      <> csrf_field
      <> "<button>Oturumu kapat</button></form><a class='back' href='/'>← Siteye dön</a></aside><main class='admin-main'><header><div><small>DÜZENLEME</small><h1>"
      <> escape(title)
      <> "</h1><span class='category-badge'>"
      <> escape(category_label)
      <> "</span></div></header><section class='admin-grid'><div class='panel editor'><header><div><small>"
      <> string.uppercase(category_label)
      <> "</small><h2>Sayfa düzenle</h2></div></header><form hx-post='/admin/"
      <> table
      <> "/"
      <> int.to_string(entry_id)
      <> "/update' hx-target='#save-result' hx-swap='innerHTML'>"
      <> csrf_field
      <> case table {
        "pages" ->
          "<label>Kategori<select name='category'><option value='anasayfa'"
          <> case category {
            "anasayfa" -> " selected"
            _ -> ""
          }
          <> ">Ana Sayfa</option><option value='kurumsal'"
          <> case category {
            "kurumsal" -> " selected"
            _ -> ""
          }
          <> ">Kurumsal</option><option value='turizm'"
          <> case category {
            "turizm" -> " selected"
            _ -> ""
          }
          <> ">Turizm</option><option value='emlak'"
          <> case category {
            "emlak" -> " selected"
            _ -> ""
          }
          <> ">Emlak</option><option value='insaat'"
          <> case category {
            "insaat" -> " selected"
            _ -> ""
          }
          <> ">İnşaat</option><option value='iletisim'"
          <> case category {
            "iletisim" -> " selected"
            _ -> ""
          }
          <> ">İletişim</option><option value='en'"
          <> case category {
            "en" -> " selected"
            _ -> ""
          }
          <> ">English</option><option value='sayfa'"
          <> case category {
            "sayfa" -> " selected"
            _ -> ""
          }
          <> ">Diğer Sayfa</option></select></label>"
        _ -> ""
      }
      <> "<label>Başlık<input required name='title' value='"
      <> escape(title)
      <> "'></label><label>URL kısa adı<input required name='slug' value='"
      <> escape(slug)
      <> "'></label><label>Kısa açıklama<textarea name='summary'>"
      <> escape(summary)
      <> "</textarea></label><label>İçerik<textarea name='body' rows='15'>"
      <> escape(body)
      <> "</textarea></label><label>SEO başlığı<input name='seo_title' value='"
      <> escape(seo_title)
      <> "'></label><label>Meta açıklaması<textarea name='seo_description' maxlength='160'>"
      <> escape(seo_description)
      <> "</textarea></label><div class='save-row'><div id='save-result'></div><button class='btn accent'>Güncelle</button></div></form></div></section></main></body></html>"
    }
    None ->
      "<!doctype html><html lang='tr'><head><meta charset='utf-8'></head><body><main><h1>Kayıt bulunamadı</h1><a href='/admin/pages'>← Geri dön</a></main></body></html>"
  }
}

pub fn sitemap(database: Database) -> String {
  let urls =
    database.list_published_entries(database, "pages")
    |> list.append(database.list_published_entries(database, "projects"))
    |> list.map(fn(entry) {
      "<url><loc>https://mamon.tr"
      <> entry_path(entry)
      <> "</loc><changefreq>weekly</changefreq></url>"
    })
    |> string.join("")
  "<?xml version='1.0' encoding='UTF-8'?><urlset xmlns='http://www.sitemaps.org/schemas/sitemap/0.9'>"
  <> urls
  <> "</urlset>"
}

pub fn entry_path(entry: Entry) -> String {
  let Entry(_, _, slug, _, _, _, _, category) = entry
  case category {
    "anasayfa" -> "/"
    "kurumsal" | "turizm" | "emlak" | "insaat" | "iletisim" | "en" ->
      "/" <> category <> "/"
    "projeler" -> "/projeler/" <> slug
    _ -> "/sayfa/" <> slug
  }
}
