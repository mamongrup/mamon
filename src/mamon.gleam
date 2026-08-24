import chat
import cms
import database
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import mist
import wisp
import wisp/wisp_mist

const secret = "mamon-development-secret-change-in-production-2026"

pub fn main() {
  let db = database.connect()
  let assert Ok(_) =
    fn(request) { handle_request(request, db) }
    |> wisp_mist.handler(secret)
    |> mist.new
    |> mist.port(8000)
    |> mist.start
  io.println("Mamon http://localhost:8000 adresinde çalışıyor")
  process.sleep_forever()
}

pub fn handle_request(
  req: wisp.Request,
  db: database.Database,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.serve_static(req, under: "/static", from: "public")
  let admin_allowed = admin_host_allowed(req)
  case req.method, request.path_segments(req), admin_allowed {
    Get, [], _ -> wisp.html_response(home, 200)
    Get, ["admin"], True -> wisp.html_response(admin, 200)
    Get, ["admin", "pages"], True ->
      wisp.html_response(cms.admin_entries(db, "pages"), 200)
    Get, ["admin", "projects"], True ->
      wisp.html_response(cms.admin_entries(db, "projects"), 200)
    Post, ["admin", "pages"], True -> create_entry(req, db, "pages")
    Post, ["admin", "projects"], True -> create_entry(req, db, "projects")
    Post, ["admin", table, id, "delete"], True -> delete_entry(db, table, id)
    Post, ["admin", "save"], True -> saved(req, db)
    _, ["admin", ..], False ->
      wisp.html_response(
        "<main><h1>404</h1><a href='/'>Ana sayfa</a></main>",
        404,
      )
    Get, ["sayfa", slug], _ -> show_entry(db, "pages", "sayfa", slug)
    Get, ["projeler", slug], _ -> show_entry(db, "projects", "projeler", slug)
    Get, ["sitemap.xml"], _ ->
      wisp.html_response(cms.sitemap(db), 200)
      |> response.set_header("content-type", "application/xml; charset=utf-8")
    Get, ["robots.txt"], _ ->
      wisp.html_response(
        "User-agent: *\nAllow: /\nDisallow: /admin\nSitemap: https://mamon.tr/sitemap.xml\n",
        200,
      )
      |> response.set_header("content-type", "text/plain; charset=utf-8")
    Get, ["hx", "regions"], _ -> wisp.html_response(regions, 200)
    Post, ["hx", "contact"], _ -> message(req, db)
    Post, ["hx", "chat"], _ -> chat_message(req)
    _, _, _ ->
      wisp.html_response(
        "<main><h1>404</h1><a href='/'>Ana sayfa</a></main>",
        404,
      )
  }
}

fn admin_host_allowed(req: wisp.Request) -> Bool {
  let host =
    request.get_header(req, "host")
    |> result.unwrap("")
    |> string.lowercase
    |> string.split(":")
    |> list.first
    |> result.unwrap("")
  list.contains(["mamon.tr", "www.mamon.tr", "localhost", "127.0.0.1"], host)
}

fn show_entry(db, table, kind, slug) {
  case database.find_entry(db, table, slug) {
    Some(entry) -> wisp.html_response(cms.entry_page(entry, kind), 200)
    None ->
      wisp.html_response(
        "<main><h1>İçerik bulunamadı</h1><a href='/'>Ana sayfa</a></main>",
        404,
      )
  }
}

fn create_entry(req, db, table) {
  use form <- wisp.require_form(req)
  let get = fn(key) { list.key_find(form.values, key) |> result.unwrap("") }
  let _ =
    database.create_entry(
      db,
      table,
      get("title"),
      get("slug"),
      get("summary"),
      get("body"),
      get("seo_title"),
      get("seo_description"),
    )
  wisp.html_response(cms.admin_entries(db, table), 200)
}

fn delete_entry(db, table, id) {
  case int.parse(id) {
    Ok(id) -> {
      let _ = database.delete_entry(db, table, id)
      wisp.html_response("", 200)
    }
    Error(_) -> wisp.html_response("Geçersiz kayıt", 400)
  }
}

fn chat_message(req) {
  use form <- wisp.require_form(req)
  let question = list.key_find(form.values, "message") |> result.unwrap("")
  let answer =
    chat.ask(question)
    |> result.unwrap(
      "Şu anda yanıt veremiyorum. Lütfen iletişim formunu kullanın.",
    )
  wisp.html_response(
    "<div class='chat-answer'><b>Mamon Asistan</b><p>"
      <> cms.escape(answer)
      <> "</p></div>",
    200,
  )
}

fn message(req, db) {
  use form <- wisp.require_form(req)
  let name = list.key_find(form.values, "name") |> result.unwrap("")
  let email = list.key_find(form.values, "email") |> result.unwrap("")
  let area = list.key_find(form.values, "area") |> result.unwrap("")
  let text = list.key_find(form.values, "message") |> result.unwrap("")
  case database.save_contact(db, name, email, area, text) {
    True ->
      wisp.html_response(
        "<div class='success'><b>Talebiniz alındı.</b><span>Ekibimiz en kısa sürede sizinle iletişime geçecek.</span></div>",
        200,
      )
    False ->
      wisp.html_response(
        "<div class='success'><b>Talep kaydedilemedi.</b><span>Lütfen doğrudan e-posta ile iletişime geçin.</span></div>",
        503,
      )
  }
}

fn saved(req, db) {
  use form <- wisp.require_form(req)
  let get = fn(key) { list.key_find(form.values, key) |> result.unwrap("") }
  case
    database.save_home_content(
      db,
      get("eyebrow"),
      get("title"),
      get("description"),
      get("cta"),
      get("url"),
    )
  {
    True ->
      wisp.html_response(
        "<div class='saved'>✓ Değişiklikler veritabanına kaydedildi.</div>",
        200,
      )
    False ->
      wisp.html_response(
        "<div class='saved'>Veritabanı bağlantısı kurulamadı.</div>",
        503,
      )
  }
}

const head = "<meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><link rel='icon' type='image/png' href='/favicon.png'><link rel='apple-touch-icon' href='/favicon.png'><link rel='manifest' href='/site.webmanifest'><meta name='theme-color' content='#10273c'><link rel='preconnect' href='https://fonts.googleapis.com'><link rel='preconnect' href='https://fonts.gstatic.com' crossorigin><link href='https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=Manrope:wght@500;600;700;800&display=swap' rel='stylesheet'><link rel='stylesheet' href='/static/styles.css'><link rel='stylesheet' href='/static/extra.css'><link rel='stylesheet' href='/static/tourism.css'><script src='https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js' defer></script>"

const home = "<!doctype html><html lang='tr'><head>"
  <> head
  <> "<title>Mamon | Turizm, Emlak ve İnşaat</title><meta name='description' content='Mamon, 2010’dan bu yana Antalya ve Muğla’da emlak ve inşaat, dünya genelinde turizm çözümleri sunar.'><link rel='canonical' href='https://mamon.tr/'><meta name='robots' content='index,follow,max-image-preview:large'><meta property='og:type' content='website'><meta property='og:locale' content='tr_TR'><meta property='og:site_name' content='Mamon'><meta property='og:title' content='Mamon | Turizm, Emlak ve İnşaat'><meta property='og:description' content='Yerelden doğan küresel vizyon. 2010’dan beri turizm, emlak ve inşaat.'><meta property='og:url' content='https://mamon.tr/'><meta name='twitter:card' content='summary_large_image'><script type='application/ld+json'>{\"@context\":\"https://schema.org\",\"@type\":\"Organization\",\"name\":\"Mamon\",\"url\":\"https://mamon.tr\",\"foundingDate\":\"2010\",\"areaServed\":\"Worldwide\",\"knowsAbout\":[\"Tourism\",\"Real Estate\",\"Construction\"]}</script></head><body>
<header class='top'><a class='brand' href='/'><i>M</i>MAMON</a><nav><a href='#about'>Hakkımızda</a><a href='#work'>Faaliyet Alanları</a><a href='#nexus'>Nexus</a><a href='#contact'>İletişim</a></nav><a class='top-cta' href='#contact'>Bizimle konuşun ↗</a></header>
<main><section class='hero'><div class='hero-copy'><label>— 2010'DAN BERİ GÜVENLE</label><h1>Yerelden doğan<br><em>küresel</em> vizyon.</h1><p>Turizm, emlak ve inşaatta köklü deneyimi; teknoloji, güven ve insan odaklı hizmetle buluşturuyoruz.</p><div class='actions'><a class='btn light' href='#work'>Neler yapıyoruz ↓</a><a href='#about'>Hikâyemizi keşfedin →</a></div></div><div class='scene'><div class='sun'></div><div class='arch'></div><small>36.8969° N<br>30.7133° E</small></div><div class='stats'><div><b>15+</b><span>Yıllık deneyim</span></div><div><b>3</b><span>Uzmanlık alanı</span></div><div><b>∞</b><span>Küresel erişim</span></div></div></section>
<section class='about' id='about'><div class='kicker'>01 — BİZ KİMİZ</div><div><h2>Akdeniz'in enerjisini<br><em>dünyaya taşıyoruz.</em></h2><p>2010 yılında çıktığımız yolda farklı sektörlerde aynı ilkeye sadık kaldık: kalıcı değer üretmek. Antalya ve Muğla'da emlak ve inşaat, dünya genelinde turizm faaliyetlerimizle güvenilir iş ortaklıkları kuruyoruz.</p><a class='under' href='#contact'>Mamon'u yakından tanıyın ↗</a></div><div class='orbit'><small>EST.</small><b>2010</b><small>ANTALYA • TÜRKİYE</small></div></section>
<section class='work' id='work'><div class='work-head'><div><span>02 — FAALİYET ALANLARI</span><h2>Üç alan.<br>Tek bir standart.</h2></div><p>Her projeye bölgesel uzmanlık, uluslararası bakış ve uzun vadeli değer anlayışıyla yaklaşıyoruz.</p></div><div class='cards'><article><small>01</small><i>✦</i><h3>Turizm</h3><p>TÜRSAB üyesi seyahat acentemizle yerli ve yabancı misafirlerimize güvenilir, özenli ve uçtan uca seyahat deneyimleri sunuyoruz.</p><b>TÜRSAB 13127</b><b>KÜRESEL HİZMET</b><a href='#tourism'>↗</a></article><article><small>02</small><i>⌂</i><h3>Emlak</h3><p>Antalya ve Muğla'nın seçkin lokasyonlarında doğru yatırım, satış ve danışmanlık.</p><b>ANTALYA</b><b>MUĞLA</b><a href='#contact'>↗</a></article><article><small>03</small><i>▱</i><h3>İnşaat</h3><p>Estetik, işlev ve sürdürülebilirliği buluşturan nitelikli yaşam alanları.</p><b>PROJE GELİŞTİRME</b><b>UYGULAMA</b><a href='#contact'>↗</a></article></div></section>
<section class='tourism-story' id='tourism'><div class='tourism-seal'><small>TÜRSAB</small><b>13127</b><span>BELGE NO</span></div><div class='tourism-copy'><span class='kicker'>SEYAHATİN HER ANINDA YANINIZDA</span><h2>Türkiye'yi keşfetmenin<br><em>en güzel hâli.</em></h2><p>TÜRSAB Belge No: 13127 ile faaliyet gösteren seyahat acentemiz, Türkiye'nin zenginliğini yerli ve yabancı misafirlerle buluşturuyor. Tatil planının ilk heyecanından eve dönüş anına kadar; doğru seçenekler, şeffaf iletişim ve içten bir misafirperverlikle her yolculuğu özenle tasarlıyoruz.</p><p>Yurt içi misafirlerimize <strong>Rezervasyon Yap</strong>, dünyanın farklı ülkelerinden gelen konuklarımıza ise <strong>Reservation in Turkey</strong> markalarımızla hizmet veriyor; yerel deneyimimizi uluslararası hizmet anlayışıyla birleştiriyoruz.</p><div class='tourism-links'><a href='https://www.rezervasyonyap.com.tr' target='_blank' rel='noopener'>rezervasyonyap.com.tr <span>↗</span></a><a href='https://www.reservastioninturkey.com' target='_blank' rel='noopener'>reservastioninturkey.com <span>↗</span></a></div></div></section>
<section class='region'><div><span class='kicker'>03 — BÖLGESEL UZMANLIK</span><h2>İki şehir,<br>sayısız olasılık.</h2><p>Akdeniz ve Ege'nin en değerli bölgelerinde yerel bilgimiz, güçlü saha ağımız ve yatırım odağımızla yanınızdayız.</p><button class='btn dark' hx-get='/hx/regions' hx-target='#map' hx-swap='innerHTML'>Bölgeleri keşfedin ＋</button></div><div class='map' id='map'><div class='dot ant'><b>ANTALYA</b><small>Akdeniz</small></div><div class='dot mug'><b>MUĞLA</b><small>Ege</small></div></div></section>
<section class='nexus' id='nexus'><div><label>STRATEJİK PARTNERLİK</label><div class='nexus-logo'><i>N</i><b>NEXUS<br><small>TRAVEL TECH</small></b></div><h2>Turizmin bilgisi,<br><em>teknolojinin gücü.</em></h2><p>Nexus Travel Tech partnerliğiyle turizm sektörüne yönelik kapsamlı bir bilgi ağı geliştiriyoruz. Veriyi, deneyimi ve doğru bağlantıları tek bir ekosistemde buluşturuyoruz.</p><div class='features'><span>01　Akıllı bilgi ağı</span><span>02　Küresel bağlantılar</span><span>03　Sektörel içgörü</span></div></div><div class='network'><b>N</b><i></i><i></i><i></i><i></i></div></section>
<section class='contact' id='contact'><div><span class='kicker'>04 — İLETİŞİM</span><h2>Birlikte değer<br><em>üretelim.</em></h2><p>Yeni bir yatırım, proje veya iş ortaklığı için ekibimizle iletişime geçin.</p><div class='meta'><span><small>E-POSTA</small>hello@mamon.com.tr</span><span><small>MERKEZ</small>Antalya, Türkiye</span></div></div><form hx-post='/hx/contact' hx-target='this' hx-swap='innerHTML'><label>Adınız Soyadınız<input required name='name' placeholder='Adınız ve soyadınız'></label><label>E-posta adresiniz<input required type='email' name='email' placeholder='ornek@firma.com'></label><label>İlgilendiğiniz alan<select name='area'><option>Turizm</option><option>Emlak</option><option>İnşaat</option><option>İş ortaklığı</option></select></label><label>Mesajınız<textarea required name='message' placeholder='Size nasıl yardımcı olabiliriz?'></textarea></label><button class='btn accent'>Mesajı gönder ↗</button></form></section></main>
<footer><a class='brand' href='/'><i>M</i>MAMON</a><p>Turizm • Emlak • İnşaat</p><div><a href='#'>LinkedIn</a><a href='#'>Instagram</a><a href='/admin'>Yönetim</a></div><small>© 2026 Mamon. Tüm hakları saklıdır.</small></footer><details class='chatbox'><summary><span>✦</span> Mamon Asistan</summary><div class='chat-window'><div class='chat-intro'><b>Size nasıl yardımcı olabilirim?</b><p>Turizm, emlak ve projelerimiz hakkında sorun.</p></div><div id='chat-result'></div><form hx-post='/hx/chat' hx-target='#chat-result' hx-swap='beforeend' hx-on::after-request='this.reset()'><input name='message' required maxlength='600' placeholder='Mesajınızı yazın…'><button aria-label='Gönder'>↑</button></form></div></details></body></html>"

const regions = "<div class='region-cards'><article><small>01 / AKDENİZ</small><h3>Antalya</h3><p>Şehir merkezinden kıyı bölgelerine uzanan emlak ve inşaat uzmanlığı.</p></article><article><small>02 / EGE</small><h3>Muğla</h3><p>Bodrum, Fethiye ve çevresinde seçkin yatırım fırsatları.</p></article></div>"

const admin = "<!doctype html><html lang='tr'><head>"
  <> head
  <> "<title>Mamon Yönetim</title></head><body class='admin-body'><aside><a class='brand' href='/'><i>M</i>MAMON</a><small>YÖNETİM PANELİ</small><nav><a class='active'>⌂　Genel Bakış</a><a>▤　Sayfa İçerikleri</a><a>◈　Faaliyet Alanları</a><a>✉　İletişim Talepleri <b>3</b></a><a>⚙　Ayarlar</a></nav><a class='back' href='/'>← Siteye dön</a></aside><main class='admin-main'><header><div><small>24 AĞUSTOS 2026</small><h1>Günaydın, Mamon.</h1></div><div class='user'><i>MA</i><span><b>Site Yöneticisi</b><small>Yönetici</small></span></div></header><section class='admin-stats'><article><span>TOPLAM SAYFA</span><b>6</b><small>↑ Tümü yayında</small></article><article><span>FAALİYET ALANI</span><b>3</b><small>Turizm, emlak, inşaat</small></article><article><span>YENİ TALEP</span><b>3</b><small>Son 7 gün</small></article><article><span>SON GÜNCELLEME</span><b>Bugün</b><small>10:42</small></article></section><section class='admin-grid'><div class='panel editor'><header><div><small>ANA SAYFA</small><h2>İçerik düzenleyici</h2></div><span>● YAYINDA</span></header><form hx-post='/admin/save' hx-target='#save' hx-swap='innerHTML'><label>Üst başlık<input name='eyebrow' value='2010&apos;DAN BERİ GÜVENLE'></label><label>Ana başlık<textarea name='title'>Yerelden doğan küresel vizyon.</textarea></label><label>Açıklama<textarea name='description'>Turizm, emlak ve inşaatta köklü deneyimi; teknoloji, güven ve insan odaklı hizmetle buluşturuyoruz.</textarea></label><div class='row'><label>Birincil buton<input name='cta' value='Neler yapıyoruz'></label><label>Bağlantı<input name='url' value='#alanlar'></label></div><div class='save-row'><div id='save'></div><button class='btn accent'>Değişiklikleri kaydet</button></div></form></div><div class='panel activity'><header><div><small>SON HAREKETLER</small><h2>Aktivite</h2></div></header><ul><li><i>MK</i><p><b>Ana sayfa güncellendi</b><span>M. Kaya • 18 dakika önce</span></p></li><li><i>AT</i><p><b>Yeni iletişim talebi</b><span>Ayşe Tan • 2 saat önce</span></p></li><li><i>SY</i><p><b>Turizm içeriği düzenlendi</b><span>S. Yılmaz • Dün</span></p></li></ul></div></section></main></body></html>"
