import database
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request
import gleam/io
import gleam/list
import gleam/result
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
  case req.method, request.path_segments(req) {
    Get, [] -> wisp.html_response(home, 200)
    Get, ["admin"] -> wisp.html_response(admin, 200)
    Get, ["hx", "regions"] -> wisp.html_response(regions, 200)
    Post, ["hx", "contact"] -> message(req, db)
    Post, ["admin", "save"] -> saved(req, db)
    _, _ ->
      wisp.html_response(
        "<main><h1>404</h1><a href='/'>Ana sayfa</a></main>",
        404,
      )
  }
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

const head = "<meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><link rel='preconnect' href='https://fonts.googleapis.com'><link rel='preconnect' href='https://fonts.gstatic.com' crossorigin><link href='https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=Manrope:wght@500;600;700;800&display=swap' rel='stylesheet'><link rel='stylesheet' href='/static/styles.css'><script src='https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js' defer></script>"

const home = "<!doctype html><html lang='tr'><head>"
  <> head
  <> "<title>Mamon | Turizm, Emlak & İnşaat</title><meta name='description' content='2010’dan bu yana turizm, emlak ve inşaatta güvenilir çözümler.'></head><body>
<header class='top'><a class='brand' href='/'><i>M</i>MAMON</a><nav><a href='#about'>Hakkımızda</a><a href='#work'>Faaliyet Alanları</a><a href='#nexus'>Nexus</a><a href='#contact'>İletişim</a></nav><a class='top-cta' href='#contact'>Bizimle konuşun ↗</a></header>
<main><section class='hero'><div class='hero-copy'><label>— 2010'DAN BERİ GÜVENLE</label><h1>Yerelden doğan<br><em>küresel</em> vizyon.</h1><p>Turizm, emlak ve inşaatta köklü deneyimi; teknoloji, güven ve insan odaklı hizmetle buluşturuyoruz.</p><div class='actions'><a class='btn light' href='#work'>Neler yapıyoruz ↓</a><a href='#about'>Hikâyemizi keşfedin →</a></div></div><div class='scene'><div class='sun'></div><div class='arch'></div><small>36.8969° N<br>30.7133° E</small></div><div class='stats'><div><b>15+</b><span>Yıllık deneyim</span></div><div><b>3</b><span>Uzmanlık alanı</span></div><div><b>∞</b><span>Küresel erişim</span></div></div></section>
<section class='about' id='about'><div class='kicker'>01 — BİZ KİMİZ</div><div><h2>Akdeniz'in enerjisini<br><em>dünyaya taşıyoruz.</em></h2><p>2010 yılında çıktığımız yolda farklı sektörlerde aynı ilkeye sadık kaldık: kalıcı değer üretmek. Antalya ve Muğla'da emlak ve inşaat, dünya genelinde turizm faaliyetlerimizle güvenilir iş ortaklıkları kuruyoruz.</p><a class='under' href='#contact'>Mamon'u yakından tanıyın ↗</a></div><div class='orbit'><small>EST.</small><b>2010</b><small>ANTALYA • TÜRKİYE</small></div></section>
<section class='work' id='work'><div class='work-head'><div><span>02 — FAALİYET ALANLARI</span><h2>Üç alan.<br>Tek bir standart.</h2></div><p>Her projeye bölgesel uzmanlık, uluslararası bakış ve uzun vadeli değer anlayışıyla yaklaşıyoruz.</p></div><div class='cards'><article><small>01</small><i>✦</i><h3>Turizm</h3><p>Dünya genelindeki destinasyon ve iş ortakları ağımızla kapsamlı seyahat çözümleri.</p><b>KÜRESEL AĞ</b><b>SEYAHAT TEKNOLOJİSİ</b><a href='#contact'>↗</a></article><article><small>02</small><i>⌂</i><h3>Emlak</h3><p>Antalya ve Muğla'nın seçkin lokasyonlarında doğru yatırım, satış ve danışmanlık.</p><b>ANTALYA</b><b>MUĞLA</b><a href='#contact'>↗</a></article><article><small>03</small><i>▱</i><h3>İnşaat</h3><p>Estetik, işlev ve sürdürülebilirliği buluşturan nitelikli yaşam alanları.</p><b>PROJE GELİŞTİRME</b><b>UYGULAMA</b><a href='#contact'>↗</a></article></div></section>
<section class='region'><div><span class='kicker'>03 — BÖLGESEL UZMANLIK</span><h2>İki şehir,<br>sayısız olasılık.</h2><p>Akdeniz ve Ege'nin en değerli bölgelerinde yerel bilgimiz, güçlü saha ağımız ve yatırım odağımızla yanınızdayız.</p><button class='btn dark' hx-get='/hx/regions' hx-target='#map' hx-swap='innerHTML'>Bölgeleri keşfedin ＋</button></div><div class='map' id='map'><div class='dot ant'><b>ANTALYA</b><small>Akdeniz</small></div><div class='dot mug'><b>MUĞLA</b><small>Ege</small></div></div></section>
<section class='nexus' id='nexus'><div><label>STRATEJİK PARTNERLİK</label><div class='nexus-logo'><i>N</i><b>NEXUS<br><small>TRAVEL TECH</small></b></div><h2>Turizmin bilgisi,<br><em>teknolojinin gücü.</em></h2><p>Nexus Travel Tech partnerliğiyle turizm sektörüne yönelik kapsamlı bir bilgi ağı geliştiriyoruz. Veriyi, deneyimi ve doğru bağlantıları tek bir ekosistemde buluşturuyoruz.</p><div class='features'><span>01　Akıllı bilgi ağı</span><span>02　Küresel bağlantılar</span><span>03　Sektörel içgörü</span></div></div><div class='network'><b>N</b><i></i><i></i><i></i><i></i></div></section>
<section class='contact' id='contact'><div><span class='kicker'>04 — İLETİŞİM</span><h2>Birlikte değer<br><em>üretelim.</em></h2><p>Yeni bir yatırım, proje veya iş ortaklığı için ekibimizle iletişime geçin.</p><div class='meta'><span><small>E-POSTA</small>hello@mamon.com.tr</span><span><small>MERKEZ</small>Antalya, Türkiye</span></div></div><form hx-post='/hx/contact' hx-target='this' hx-swap='innerHTML'><label>Adınız Soyadınız<input required name='name' placeholder='Adınız ve soyadınız'></label><label>E-posta adresiniz<input required type='email' name='email' placeholder='ornek@firma.com'></label><label>İlgilendiğiniz alan<select name='area'><option>Turizm</option><option>Emlak</option><option>İnşaat</option><option>İş ortaklığı</option></select></label><label>Mesajınız<textarea required name='message' placeholder='Size nasıl yardımcı olabiliriz?'></textarea></label><button class='btn accent'>Mesajı gönder ↗</button></form></section></main>
<footer><a class='brand' href='/'><i>M</i>MAMON</a><p>Turizm • Emlak • İnşaat</p><div><a href='#'>LinkedIn</a><a href='#'>Instagram</a><a href='/admin'>Yönetim</a></div><small>© 2026 Mamon. Tüm hakları saklıdır.</small></footer></body></html>"

const regions = "<div class='region-cards'><article><small>01 / AKDENİZ</small><h3>Antalya</h3><p>Şehir merkezinden kıyı bölgelerine uzanan emlak ve inşaat uzmanlığı.</p></article><article><small>02 / EGE</small><h3>Muğla</h3><p>Bodrum, Fethiye ve çevresinde seçkin yatırım fırsatları.</p></article></div>"

const admin = "<!doctype html><html lang='tr'><head>"
  <> head
  <> "<title>Mamon Yönetim</title></head><body class='admin-body'><aside><a class='brand' href='/'><i>M</i>MAMON</a><small>YÖNETİM PANELİ</small><nav><a class='active'>⌂　Genel Bakış</a><a>▤　Sayfa İçerikleri</a><a>◈　Faaliyet Alanları</a><a>✉　İletişim Talepleri <b>3</b></a><a>⚙　Ayarlar</a></nav><a class='back' href='/'>← Siteye dön</a></aside><main class='admin-main'><header><div><small>24 AĞUSTOS 2026</small><h1>Günaydın, Mamon.</h1></div><div class='user'><i>MA</i><span><b>Site Yöneticisi</b><small>Yönetici</small></span></div></header><section class='admin-stats'><article><span>TOPLAM SAYFA</span><b>6</b><small>↑ Tümü yayında</small></article><article><span>FAALİYET ALANI</span><b>3</b><small>Turizm, emlak, inşaat</small></article><article><span>YENİ TALEP</span><b>3</b><small>Son 7 gün</small></article><article><span>SON GÜNCELLEME</span><b>Bugün</b><small>10:42</small></article></section><section class='admin-grid'><div class='panel editor'><header><div><small>ANA SAYFA</small><h2>İçerik düzenleyici</h2></div><span>● YAYINDA</span></header><form hx-post='/admin/save' hx-target='#save' hx-swap='innerHTML'><label>Üst başlık<input name='eyebrow' value='2010&apos;DAN BERİ GÜVENLE'></label><label>Ana başlık<textarea name='title'>Yerelden doğan küresel vizyon.</textarea></label><label>Açıklama<textarea name='description'>Turizm, emlak ve inşaatta köklü deneyimi; teknoloji, güven ve insan odaklı hizmetle buluşturuyoruz.</textarea></label><div class='row'><label>Birincil buton<input name='cta' value='Neler yapıyoruz'></label><label>Bağlantı<input name='url' value='#alanlar'></label></div><div class='save-row'><div id='save'></div><button class='btn accent'>Değişiklikleri kaydet</button></div></form></div><div class='panel activity'><header><div><small>SON HAREKETLER</small><h2>Aktivite</h2></div></header><ul><li><i>MK</i><p><b>Ana sayfa güncellendi</b><span>M. Kaya • 18 dakika önce</span></p></li><li><i>AT</i><p><b>Yeni iletişim talebi</b><span>Ayşe Tan • 2 saat önce</span></p></li><li><i>SY</i><p><b>Turizm içeriği düzenlendi</b><span>S. Yılmaz • Dün</span></p></li></ul></div></section></main></body></html>"
