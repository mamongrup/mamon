import account_auth
import account_mail
import auth_pages
import chat
import cms
import csrf
import database
import envoy
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
import rate_limit
import wisp
import wisp/wisp_mist

pub fn main() {
  rate_limit.init()
  let db = database.connect()
  let secret = case envoy.get("SECRET_KEY_BASE") {
    Ok(key) -> key
    Error(_) -> {
      io.println(
        "HATA: SECRET_KEY_BASE ortam değişkeni tanımlı değil. Üretimde bu değişken zorunludur.",
      )
      panic as "SECRET_KEY_BASE gerekli"
    }
  }
  let _ = case db {
    Some(_) -> {
      io.println("✓ Veritabanı bağlantısı başarılı")
      let seed_result = seed_content(db)
      case seed_result {
        True -> io.println("✓ Sayfalar veritabanına yazıldı")
        False -> io.println("✗ Seed başarısız (tablolar eksik olabilir)")
      }
      seed_result
    }
    None -> {
      io.println("✗ Veritabanı bağlantısı yok, seed yapılamıyor")
      False
    }
  }
  let assert Ok(_) =
    fn(request) { handle_request(request, db) }
    |> wisp_mist.handler(secret)
    |> mist.new
    |> mist.port(8000)
    |> mist.start
  io.println("Mamon http://localhost:8000 adresinde çalışıyor")
  process.sleep_forever()
}

fn seed_content(db: database.Database) -> Bool {
  let _ =
    database.seed_page(
      db,
      "Ana Sayfa",
      "anasayfa",
      "Turizm, emlak ve inşaatta köklü deneyim; güvenilir ortaklıklar.",
      "<section class='hero-corp'><div class='hero-main'><span class='overline'>2010'DAN BERİ GÜVENLE</span><h1>Köklü deneyim.<br><em>Kalıcı değer.</em></h1><p>Turizm, emlak ve inşaat alanlarında yerel uzmanlığı uluslararası bakış açısıyla birleştiriyor; insanlar, şehirler ve gelecek için güvenilir işler üretiyoruz.</p><div class='hero-buttons'><a class='button copper' href='/kurumsal/'>Bizi tanıyın <span>→</span></a><a class='button outline' href='/projeler/'>Projelerimiz <span>↗</span></a></div></div><div class='hero-side'></div></section><section class='trustbar'><div><small>KURULUŞ</small><strong>2010</strong></div><div><small>UZMANLIK</small><strong>3 faaliyet alanı</strong></div><div><small>TURİZM</small><strong>TÜRSAB 13127</strong></div><div><small>ERİŞİM</small><strong>Türkiye ve dünya</strong></div></section><section class='intro-corp'><div><span class='section-no'>01 — MAMON</span></div><div><h2>Farklı sektörlerde,<br>aynı güven anlayışı.</h2><p>Mamon; turizmde misafirperverliği, emlakta doğru yatırımı, inşaatta ise nitelikli yaşam alanlarını odağına alır. Her faaliyet alanımız kendi uzman ekibi ve markasıyla gelişirken, tüm işlerimizin merkezinde şeffaflık, kalite ve uzun vadeli değer bulunur.</p></div></section><section class='divisions'><div class='divisions-head'><div><span class='section-no'>02 — FAALİYET ALANLARI</span><h2 class='section-title'>Uzmanlığımız</h2></div><p>Her alan için ayrı içerik, ayrı proje yapısı ve büyümeye hazır kurumsal sayfalar.</p></div><div class='division-grid'><article class='division'><span>01</span><h3>Turizm</h3><p>TÜRSAB üyesi acentemizle yerli ve yabancı misafirlere güvenilir seyahat çözümleri.</p><a href='/turizm/'>TURİZMİ KEŞFEDİN <b>→</b></a></article><article class='division'><span>02</span><h3>Emlak</h3><p>Antalya ve Muğla'da doğru lokasyon, doğru analiz ve güvenilir yatırım danışmanlığı.</p><a href='/emlak/'>EMLAĞI KEŞFEDİN <b>→</b></a></article><article class='division'><span>03</span><h3>İnşaat</h3><p>İşlevsel, estetik ve çevresiyle uyumlu yaşam alanları için proje geliştirme.</p><a href='/insaat/'>İNŞAATI KEŞFEDİN <b>→</b></a></article></div></section><section class='project-strip'><header><div><span class='section-no'>03 — PROJELER</span><h2 class='section-title'>Geleceğe bıraktığımız iz</h2></div><a class='button copper' href='/projeler/'>Tüm projeler →</a></header><div class='project-list'><article class='project-tile'><small>PROJE GELİŞTİRME</small><h3>Yeni projeler çok yakında</h3><p>İnşaat ve gayrimenkul projelerimiz bu alanda ayrı detay sayfalarıyla yayınlanacak.</p></article><article class='project-tile'><small>ANTALYA</small><h3>Yerel uzmanlık</h3></article><article class='project-tile'><small>MUĞLA</small><h3>Seçkin lokasyonlar</h3></article></div></section><section class='partner'><div class='partner-badge'><small>STRATEJİK PARTNER</small><b>Nexus Travel Tech</b></div><div><h2>Turizm deneyimini teknolojiyle güçlendiriyoruz.</h2><p>Nexus Travel Tech partnerliğimizle turizm sektörüne yönelik kapsamlı bilgi ağı çalışmalarına katkı sunuyor; yerel deneyimi küresel bağlantılarla bir araya getiriyoruz.</p></div></section><section class='cta' id='iletisim'><h2>Birlikte kalıcı değer üretelim.</h2><a class='button outline' href='mailto:info@mamon.com.tr'>info@mamon.com.tr <span>↗</span></a></section>",
      "Mamon | Turizm, Emlak ve İnşaat",
      "Turizm, emlak ve inşaatta köklü deneyim; güvenilir ortaklıklar.",
      "anasayfa",
    )
  let _ =
    database.seed_page(
      db,
      "Turizm",
      "turizm",
      "TÜRSAB 13127 belgeli Mamon seyahat acentesi, yerli ve yabancı turistlere Türkiye genelinde hizmet verir.",
      "<div class='content-grid'><div><span class='section-no'>TÜRSAB BELGE NO</span><h2>13127</h2></div><div><h2>Yerli deneyim, uluslararası hizmet.</h2><p>TÜRSAB üyesi seyahat acentemiz, Türkiye'nin doğal ve kültürel zenginliğini yerli ve yabancı misafirlerle buluşturur. Doğru seçenekler, şeffaf iletişim ve güçlü tedarik ağımızla seyahatin her aşamasında güvenilir bir çözüm ortağıyız.</p><p>Yurt içi misafirlerimize <strong>Rezervasyon Yap</strong>, dünyanın farklı ülkelerinden gelen konuklarımıza <strong>Reservation in Turkey</strong> markalarımızla hizmet veriyoruz.</p><div class='facts'><div class='fact'><b>13127</b><small>TÜRSAB BELGE NO</small></div><div class='fact'><b>Yerli</b><small>TÜRKİYE PAZARI</small></div><div class='fact'><b>Global</b><small>ULUSLARARASI MİSAFİRLER</small></div></div></div></div><div class='cards-list'><article class='info-card'><h3>Otel ve tatil</h3><p>Farklı beklenti ve bütçelere uygun konaklama seçenekleri.</p></article><article class='info-card'><h3>Tur ve deneyim</h3><p>Türkiye'nin kültürünü ve doğasını yakından tanıtan rotalar.</p></article><article class='info-card'><h3>Misafir desteği</h3><p>Rezervasyon öncesinden dönüşe kadar ulaşılabilir hizmet.</p></article></div><section class='cta'><h2>Seyahatinizi birlikte planlayalım.</h2><div><a class='button outline' href='https://www.rezervasyonyap.com.tr'>Rezervasyon Yap ↗</a> <a class='button outline' href='https://www.reservastioninturkey.com'>Reservation in Turkey ↗</a></div></section>",
      "Turizm | Mamon",
      "TÜRSAB 13127 belgeli Mamon seyahat acentesi, yerli ve yabancı turistlere Türkiye genelinde hizmet verir.",
      "turizm",
    )
  let _ =
    database.seed_page(
      db,
      "Emlak",
      "emlak",
      "Mamon Estate ile Antalya ve Muğla'da güvenilir gayrimenkul yatırım ve satış danışmanlığı.",
      "<div class='content-grid'><div><span class='section-no'>BÖLGESEL UZMANLIK</span><h2>Antalya<br>& Muğla</h2></div><div><h2>Gayrimenkulde güven, bilgiden doğar.</h2><p><strong>Mamon Estate</strong>, yaşam ve yatırım hedeflerinize uygun gayrimenkul fırsatlarını yerel uzmanlıkla buluşturur. Her gayrimenkul kararının farklı bir amacı olduğuna inanıyoruz.</p><div class='cards-list'><article class='info-card'><h3>Yatırım danışmanlığı</h3><p>Veriye ve bölgesel gelişime dayalı fırsat analizi.</p></article><article class='info-card'><h3>Satış ve portföy</h3><p>Nitelikli gayrimenkuller için güvenilir süreç yönetimi.</p></article><article class='info-card'><h3>Arsa geliştirme</h3><p>Potansiyeli doğru okuyan proje ve fizibilite yaklaşımı.</p></article></div></div></div></div><section class='partner'><div class='partner-badge'><small>GAYRİMENKUL MARKAMIZ</small><b>Mamon Estate</b></div><div><h2>Seçkin portföyü keşfedin.</h2><p>Satılık ve yatırım amaçlı güncel gayrimenkul seçenekleri için Mamon Estate web sitesini ziyaret edin.</p><a class='button copper' href='https://mamonestate.com' target='_blank' rel='noopener'>mamonestate.com ↗</a></div></section><section class='cta'><h2>Gayrimenkul hedefinizi konuşalım.</h2><a class='button outline' href='https://mamonestate.com' target='_blank' rel='noopener'>Mamon Estate'i ziyaret edin ↗</a></section>",
      "Emlak | Mamon Estate",
      "Mamon Estate ile Antalya ve Muğla'da güvenilir gayrimenkul yatırım ve satış danışmanlığı.",
      "emlak",
    )
  let _ =
    database.seed_page(
      db,
      "İnşaat",
      "insaat",
      "Mamon İnşaat, Antalya ve Muğla'da yalnızca yatay mimari alanında uzmanlaşmış nitelikli yaşam projeleri geliştirir.",
      "<div class='content-grid'><div><span class='section-no'>PROJE YAKLAŞIMI</span><h2>Fikirden<br>yaşama.</h2></div><div><h2>Uzmanlığımız yalnızca yatay mimari.</h2><p>Mamon İnşaat olarak dikey yapılaşma projeleri geliştirmiyor; tüm bilgi birikimimizi yatay mimariye odaklıyoruz.</p><p>Doğru arsa seçiminden tasarıma, uygulamadan teslim sonrasına kadar bütüncül bir proje yönetimi benimsiyoruz.</p><div class='cards-list'><article class='info-card'><h3>Proje geliştirme</h3><p>Doğru ihtiyaç, doğru konsept ve sağlam fizibilite.</p></article><article class='info-card'><h3>Uygulama</h3><p>Kalite, zaman ve bütçe dengesini koruyan saha yönetimi.</p></article><article class='info-card'><h3>Yatay yaşam</h3><p>İnsan ölçeğini, mahremiyeti ve açık alanlarla güçlü bağı koruyan projeler.</p></article></div></div></div></div><section class='partner'><div class='partner-badge'><small>TEK UZMANLIK ALANIMIZ</small><b>Yatay Mimari</b></div><div><h2>Odağımız net, uzmanlığımız derin.</h2><p>Yatay mimari dışındaki yapı modellerinde çalışma yapmıyoruz.</p></div></section><section class='cta'><h2>Yatay mimari projenizi birlikte geliştirelim.</h2><a class='button outline' href='mailto:info@mamon.com.tr'>Bize ulaşın ↗</a></section>",
      "İnşaat | Mamon",
      "Mamon İnşaat, Antalya ve Muğla'da yalnızca yatay mimari alanında uzmanlaşmış nitelikli yaşam projeleri geliştirir.",
      "insaat",
    )
  let _ =
    database.seed_page(
      db,
      "Kurumsal",
      "kurumsal",
      "Mamon, 2010'dan beri turizm, emlak ve inşaat alanlarında faaliyet gösteren Antalya merkezli bir şirketler grubudur.",
      "<div class='content-grid'><div><span class='section-no'>HAKKIMIZDA</span><h2>Birlikte daha ileriye.</h2></div><div><p>Mamon'un yolculuğu 2010 yılında, kalıcı ve güvenilir işler üretme hedefiyle başladı. Bugün turizmde dünya genelinde, emlak ve inşaatta Antalya ile Muğla'da faaliyet gösteriyoruz.</p><p>Farklı uzmanlık alanlarımızı tek bir kurumsal anlayış etrafında buluşturuyoruz: sözünü tutmak, şeffaf olmak, kaliteyi ayrıntılarda aramak ve kurduğumuz her ilişkiye uzun vadeli bakmak.</p><div class='facts'><div class='fact'><b>2010</b><small>KURULUŞ</small></div><div class='fact'><b>3</b><small>FAALİYET ALANI</small></div><div class='fact'><b>2+ ülke</b><small>KÜRESEL ERİŞİM</small></div></div></div></div></div><section class='partner'><div class='partner-badge'><small>DEĞERLERİMİZ</small><b>Güven</b></div><div><h2>İşimizin merkezinde insan var.</h2><p>Misafirlerimiz, yatırımcılarımız, iş ortaklarımız ve ekip arkadaşlarımızla kurduğumuz ilişkilerde açıklığı ve karşılıklı güveni esas alıyoruz.</p></div></section>",
      "Kurumsal | Mamon",
      "Mamon, 2010'dan beri turizm, emlak ve inşaat alanlarında faaliyet gösteren bir şirketler grubudur.",
      "kurumsal",
    )
  let _ =
    database.seed_page(
      db,
      "İletişim",
      "iletisim",
      "Mamon ile turizm, emlak, yatay mimari ve iş ortaklığı projeleriniz hakkında iletişime geçin.",
      "<div class='content-grid'><div><span class='section-no'>BİZE ULAŞIN</span><h2>Doğru sorular,<br>iyi başlangıçlar.</h2></div><div><div class='contact-item'><small>E-POSTA</small><a href='mailto:info@mamon.com.tr'>info@mamon.com.tr</a></div><div class='contact-item'><small>TELEFON</small><a href='tel:+905323977957'>0532 397 7957</a></div><div class='contact-item'><small>WHATSAPP</small><a href='https://wa.me/905323977957' target='_blank' rel='noopener'>WhatsApp üzerinden yazın ↗</a></div><div class='contact-item'><small>MERKEZ OFİS</small><span>Kesikkapı Mah. Çarşı Cd. No:254</span><p>Fethiye / Muğla, Türkiye</p></div><div class='contact-item'><small>ÇALIŞMA ALANLARI</small><span>Turizm · Emlak · Yatay Mimari</span></div></div></div></div>",
      "İletişim | Mamon",
      "Mamon ile turizm, emlak, yatay mimari ve iş ortaklığı projeleriniz hakkında iletişime geçin.",
      "iletisim",
    )
  let _ =
    database.seed_page(
      db,
      "İletişim",
      "iletisim",
      "Mamon ile turizm, emlak, yatay mimari ve iş ortaklığı projeleriniz hakkında iletişime geçin.",
      "<div class='content-grid'><div><span class='section-no'>BİZE ULAŞIN</span><h2>Doğru sorular,<br>iyi başlangıçlar.</h2></div><div><div class='contact-item'><small>E-POSTA</small><a href='mailto:info@mamon.com.tr'>info@mamon.com.tr</a></div><div class='contact-item'><small>TELEFON</small><a href='tel:+905323977957'>0532 397 7957</a></div><div class='contact-item'><small>WHATSAPP</small><a href='https://wa.me/905323977957' target='_blank' rel='noopener'>WhatsApp üzerinden yazın ↗</a></div><div class='contact-item'><small>MERKEZ OFİS</small><span>Kesikkapı Mah. Çarşı Cd. No:254</span><p>Fethiye / Muğla, Türkiye</p></div><div class='contact-item'><small>ÇALIŞMA ALANLARI</small><span>Turizm · Emlak · Yatay Mimari</span></div></div></div></div>",
      "İletişim | Mamon",
      "Mamon ile turizm, emlak, yatay mimari ve iş ortaklığı projeleriniz hakkında iletişime geçin.",
      "iletisim",
    )
  let _ =
    database.seed_page(
      db,
      "Home",
      "en",
      "Mamon has created lasting value in tourism, real estate and construction since 2010.",
      "<section class='hero-corp'><div class='hero-main'><span class='overline'>TRUSTED SINCE 2010</span><h1>Deep experience.<br><em>Lasting value.</em></h1><p>We combine local expertise with an international perspective across tourism, real estate and construction; building trustworthy projects for people, cities and the future.</p><div class='hero-buttons'><a class='button copper' href='/en/corporate/'>About Us <span>→</span></a><a class='button outline' href='/en/projects/'>Our Projects <span>↗</span></a></div></div><div class='hero-side'></div></section><section class='trustbar'><div><small>FOUNDED</small><strong>2010</strong></div><div><small>EXPERTISE</small><strong>3 business areas</strong></div><div><small>TOURISM</small><strong>TÜRSAB 13127</strong></div><div><small>REACH</small><strong>Türkiye & worldwide</strong></div></section><section class='intro-corp' id='about'><div><span class='section-no'>01 — MAMON</span></div><div><h2>Different industries.<br>One standard of trust.</h2><p>Mamon focuses on hospitality in tourism, sound investment in real estate, and high-quality living spaces in construction. While each division grows with its specialized team and brand, transparency, quality, and long-term value remain at the core of everything we do.</p></div></section><section class='divisions'><div class='divisions-head'><div><span class='section-no'>02 — DIVISIONS</span><h2 class='section-title'>Our Expertise</h2></div><p>Dedicated content, distinct project architecture and structured corporate pages for each division.</p></div><div class='division-grid'><article class='division'><span>01</span><h3>Tourism</h3><p>Reliable travel solutions for domestic and international guests through our TÜRSAB-certified agency.</p><a href='/en/tourism/'>DISCOVER TOURISM <b>→</b></a></article><article class='division'><span>02</span><h3>Real Estate</h3><p>Accurate location analysis, market data, and dependable investment consultancy in Antalya and Muğla.</p><a href='/en/real-estate/'>DISCOVER REAL ESTATE <b>→</b></a></article><article class='division'><span>03</span><h3>Construction</h3><p>Project development for functional, aesthetic living spaces harmonious with nature and environment.</p><a href='/en/construction/'>DISCOVER CONSTRUCTION <b>→</b></a></article></div></section><section class='project-strip'><header><div><span class='section-no'>03 — PROJECTS</span><h2 class='section-title'>The mark we leave for the future</h2></div><a class='button copper' href='/en/projects/'>All projects →</a></header><div class='project-list'><article class='project-tile'><small>PROJECT DEVELOPMENT</small><h3>New projects coming soon</h3><p>Our construction and real estate projects will be showcased here with dedicated detail pages.</p></article><article class='project-tile'><small>ANTALYA</small><h3>Local expertise</h3></article><article class='project-tile'><small>MUĞLA</small><h3>Prime locations</h3></article></div></section><section class='partner'><div class='partner-badge'><small>STRATEGIC PARTNER</small><b>Nexus Travel Tech</b></div><div><h2>Empowering the tourism experience with technology.</h2><p>Through our strategic partnership with Nexus Travel Tech, we contribute to comprehensive knowledge network initiatives for the tourism sector, connecting local expertise with global networks.</p></div></section><section class='cta' id='contact'><h2>Let's create lasting value together.</h2><a class='button outline' href='/en/contact/'>Contact us <span>↗</span></a></section>",
      "Mamon | Tourism, Real Estate & Construction",
      "Mamon has created lasting value in tourism, real estate and construction since 2010.",
      "en",
    )
  let _ =
    database.seed_page(
      db,
      "Tourism",
      "tourism",
      "TÜRSAB-certified Mamon travel agency serving domestic and international tourists across Turkey.",
      "<div class='content-grid'><div><span class='section-no'>TÜRSAB LICENSE NO</span><h2>13127</h2></div><div><h2>Local experience, international standard.</h2><p>As an accredited TÜRSAB member travel agency, we connect domestic and international travelers with Turkey's rich cultural and natural heritage. With verified accommodations, transparent communication, and an extensive supplier network, we are a trusted partner throughout every stage of travel.</p><p>We serve our domestic guests under <strong>Rezervasyon Yap</strong> and international guests through our <strong>Reservation in Turkey</strong> brand.</p><div class='facts'><div class='fact'><b>13127</b><small>TÜRSAB LICENSE</small></div><div class='fact'><b>Domestic</b><small>TURKEY MARKET</small></div><div class='fact'><b>Global</b><small>INTERNATIONAL GUESTS</small></div></div></div></div><div class='cards-list'><article class='info-card'><h3>Hotels & Stays</h3><p>Carefully selected accommodation options for varying expectations and budgets.</p></article><article class='info-card'><h3>Tours & Experiences</h3><p>Authentic routes introducing Turkey's history, culture, and nature up close.</p></article><article class='info-card'><h3>Guest Support</h3><p>Dedicated assistance and seamless support from initial booking to departure.</p></article></div><section class='cta'><h2>Let's plan your journey together.</h2><div><a class='button outline' href='https://www.rezervasyonyap.com.tr' target='_blank' rel='noopener'>Rezervasyon Yap ↗</a> <a class='button outline' href='https://www.reservastioninturkey.com' target='_blank' rel='noopener'>Reservation in Turkey ↗</a></div></section>",
      "Tourism | Mamon",
      "TÜRSAB-certified Mamon travel agency serving domestic and international tourists across Turkey.",
      "en",
    )
  let _ =
    database.seed_page(
      db,
      "Real Estate",
      "real-estate",
      "Mamon Estate offers reliable real estate investment and sales consulting in Antalya and Muğla.",
      "<div class='content-grid'><div><span class='section-no'>REGIONAL EXPERTISE</span><h2>Antalya<br>& Muğla</h2></div><div><h2>Trust in real estate is built on insight.</h2><p><strong>Mamon Estate</strong> pairs your living and investment goals with verified regional market expertise. We understand that every real estate decision serves a distinct purpose. Whether seeking lifestyle properties, capital growth, or development plots, we provide transparent data-driven consultancy.</p><div class='cards-list'><article class='info-card'><h3>Investment Consulting</h3><p>Data-driven yield analysis and regional development forecasting.</p></article><article class='info-card'><h3>Sales & Portfolio</h3><p>Transparent process management for prime residential and commercial real estate.</p></article><article class='info-card'><h3>Land Development</h3><p>Feasibility studies and development strategies assessing true land potential.</p></article></div></div></div><section class='partner'><div class='partner-badge'><small>REAL ESTATE BRAND</small><b>Mamon Estate</b></div><div><h2>Explore our exclusive portfolio.</h2><p>Visit the official Mamon Estate portal for current listings and premium investment opportunities.</p><a class='button copper' href='https://mamonestate.com' target='_blank' rel='noopener'>mamonestate.com ↗</a></div></section><section class='cta'><h2>Let's discuss your real estate objectives.</h2><a class='button outline' href='https://mamonestate.com' target='_blank' rel='noopener'>Visit Mamon Estate ↗</a></section>",
      "Real Estate | Mamon Estate",
      "Mamon Estate offers reliable real estate investment and sales consulting in Antalya and Muğla.",
      "en",
    )
  let _ =
    database.seed_page(
      db,
      "Construction",
      "construction",
      "Mamon Construction develops qualified living projects exclusively in horizontal architecture in Antalya and Muğla.",
      "<div class='content-grid'><div><span class='section-no'>PROJECT PHILOSOPHY</span><h2>From concept<br>to life.</h2></div><div><h2>Specialized exclusively in horizontal architecture.</h2><p>At Mamon Construction, we do not build high-rise towers; our entire craft and engineering focus is dedicated to low-density horizontal architecture. We treat each development as a long-lasting living habitat closely connected to its natural surroundings.</p><p>From meticulous site selection and sustainable architectural design to field execution and after-handover care, we deliver end-to-end project management.</p><div class='cards-list'><article class='info-card'><h3>Project Development</h3><p>Rigorous feasibility, concept creation, and architectural harmony.</p></article><article class='info-card'><h3>Execution</h3><p>Precise site engineering balancing premium material quality, budget, and timelines.</p></article><article class='info-card'><h3>Horizontal Living</h3><p>Human-scale spaces preserving privacy, green zones, and natural light.</p></article></div></div></div><section class='partner'><div class='partner-badge'><small>OUR ONLY SPECIALIZATION</small><b>Horizontal Architecture</b></div><div><h2>Clear focus, deep expertise.</h2><p>We deliberately do not undertake vertical construction projects. This focused commitment allows us to refine every architectural and landscape detail.</p></div></section><section class='cta'><h2>Let's develop your horizontal architecture project together.</h2><a class='button outline' href='/en/contact/'>Contact us ↗</a></section>",
      "Construction | Mamon",
      "Mamon Construction develops qualified living projects exclusively in horizontal architecture in Antalya and Muğla.",
      "en",
    )
  let _ =
    database.seed_page(
      db,
      "Corporate",
      "corporate",
      "Mamon is an Antalya-based group of companies active in tourism, real estate and construction since 2010.",
      "<div class='content-grid'><div><span class='section-no'>ABOUT US</span><h2>Together, further.</h2></div><div><p>Mamon's journey began in 2010 with the goal of creating enduring, dependable work. Today, we operate globally in tourism, and in Antalya and Muğla across real estate and construction.</p><p>We unite our diverse areas of expertise under a single corporate philosophy: keeping our promises, maintaining transparency, pursuing excellence in every detail, and taking a long-term perspective in every partnership we forge.</p><div class='facts'><div class='fact'><b>2010</b><small>FOUNDED</small></div><div class='fact'><b>3</b><small>BUSINESS DIVISIONS</small></div><div class='fact'><b>2+ countries</b><small>GLOBAL REACH</small></div></div></div></div><section class='partner'><div class='partner-badge'><small>OUR VALUES</small><b>Trust & Quality</b></div><div><h2>People are at the center of our business.</h2><p>In all interactions with our guests, investors, business partners, and team members, we prioritize openness, mutual trust, and uncompromising integrity.</p></div></section>",
      "Corporate | Mamon",
      "Mamon is an Antalya-based group of companies active in tourism, real estate and construction since 2010.",
      "en",
    )
  let _ =
    database.seed_page(
      db,
      "Contact",
      "contact",
      "Get in touch with Mamon about tourism, real estate, horizontal architecture and business partnership projects.",
      "<div class='content-grid'><div><span class='section-no'>GET IN TOUCH</span><h2>The right questions,<br>great beginnings.</h2></div><div><div class='contact-item'><small>EMAIL</small><a href='mailto:info@mamon.com.tr'>info@mamon.com.tr</a></div><div class='contact-item'><small>PHONE</small><a href='tel:+905323977957'>+90 532 397 7957</a></div><div class='contact-item'><small>WHATSAPP</small><a href='https://wa.me/905323977957' target='_blank' rel='noopener'>Message us on WhatsApp ↗</a></div><div class='contact-item'><small>HEAD OFFICE</small><span>Kesikkapı Mah. Çarşı Cd. No:254</span><p>Fethiye / Muğla, Türkiye</p></div><div class='contact-item'><small>BUSINESS DIVISIONS</small><span>Tourism · Real Estate · Horizontal Architecture</span></div></div></div>",
      "Contact | Mamon",
      "Get in touch with Mamon about tourism, real estate, horizontal architecture and business partnership projects.",
      "en",
    )
  True
}

pub fn handle_request(
  req: wisp.Request,
  db: database.Database,
) -> wisp.Response {
  use <- wisp.log_request(req)
  use <- wisp.serve_static(req, under: "/static", from: "public")
  let csrf_token = csrf.get_token(req)
  let response = handle_route(req, db, csrf_token)
  response
  |> wisp.set_cookie(req, "_csrf_token", csrf_token, wisp.Signed, 60 * 60 * 24)
  |> add_security_headers()
}

fn add_security_headers(resp: wisp.Response) -> wisp.Response {
  resp
  |> response.set_header("x-content-type-options", "nosniff")
  |> response.set_header("x-frame-options", "DENY")
  |> response.set_header("x-xss-protection", "0")
  |> response.set_header("referrer-policy", "strict-origin-when-cross-origin")
  |> response.set_header(
    "content-security-policy",
    "default-src 'self'; script-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'",
  )
}

fn get_client_ip(req: wisp.Request) -> String {
  case request.get_header(req, "x-forwarded-for") {
    Ok(value) ->
      value
      |> string.split(",")
      |> list.first
      |> result.unwrap("unknown")
      |> string.trim
    Error(_) ->
      case request.get_header(req, "x-real-ip") {
        Ok(value) -> value
        Error(_) -> "unknown"
      }
  }
}

fn handle_route(
  req: wisp.Request,
  db: database.Database,
  csrf_token: String,
) -> wisp.Response {
  let admin_allowed = admin_host_allowed(req)
  case req.method, request.path_segments(req), admin_allowed {
    // --- Public CMS pages ---
    Get, [], _ -> render_page_by_slug(db, "anasayfa", "anasayfa")
    Get, ["turizm"], _ -> render_page_by_slug(db, "turizm", "turizm")
    Get, ["emlak"], _ -> render_page_by_slug(db, "emlak", "emlak")
    Get, ["insaat"], _ -> render_page_by_slug(db, "insaat", "insaat")
    Get, ["kurumsal"], _ -> render_page_by_slug(db, "kurumsal", "kurumsal")
    Get, ["iletisim"], _ -> render_page_by_slug(db, "iletisim", "iletisim")
    Get, ["en"], _ -> render_page_by_slug(db, "en", "en")
    Get, ["en", "corporate"], _ -> render_page_by_slug(db, "corporate", "en")
    Get, ["en", "tourism"], _ -> render_page_by_slug(db, "tourism", "en")
    Get, ["en", "real-estate"], _ -> render_page_by_slug(db, "real-estate", "en")
    Get, ["en", "construction"], _ -> render_page_by_slug(db, "construction", "en")
    Get, ["en", "contact"], _ -> render_page_by_slug(db, "contact", "en")
    Get, ["en", "projects"], _ ->
      wisp.html_response(cms.en_projects_page(db), 200)
    Get, ["en", "projects", slug], _ ->
      show_en_entry(db, slug)
    Get, ["en", slug], _ -> show_en_entry(db, slug)
    Get, ["projeler"], _ -> wisp.html_response(cms.projects_page(db), 200)
    Get, ["sayfa", slug], _ -> show_entry(db, "pages", "sayfa", slug)
    Get, ["projeler", slug], _ -> show_entry(db, "projects", "projeler", slug)

    // --- Admin auth ---
    Get, ["admin", "login"], True ->
      wisp.html_response(auth_pages.login(csrf_token, ""), 200)
    Post, ["admin", "login"], True -> login(req, db, csrf_token)
    Get, ["admin", "register"], True ->
      wisp.html_response(auth_pages.register(csrf_token, ""), 200)
    Post, ["admin", "register"], True -> register(req, db, csrf_token)
    Get, ["admin", "forgot-password"], True ->
      wisp.html_response(auth_pages.forgot(csrf_token, ""), 200)
    Post, ["admin", "forgot-password"], True ->
      forgot_password(req, db, csrf_token)
    Get, ["admin", "reset-password", token], True ->
      wisp.html_response(auth_pages.reset(csrf_token, token, ""), 200)
    Post, ["admin", "reset-password"], True ->
      reset_password(req, db, csrf_token)
    Post, ["admin", "logout"], True -> logout(req, csrf_token)

    // --- Admin dashboard & CMS ---
    Get, ["admin"], True ->
      protected(req, db, fn() {
        wisp.html_response(admin_dashboard(csrf_token, db), 200)
      })
    Get, ["admin", "pages"], True ->
      protected(req, db, fn() {
        wisp.html_response(cms.admin_entries(csrf_token, db, "pages"), 200)
      })
    Get, ["admin", "pages", id_str, "edit"], True ->
      protected(req, db, fn() {
        case int.parse(id_str) {
          Ok(id) ->
            wisp.html_response(
              cms.admin_edit_page(csrf_token, db, "pages", id),
              200,
            )
          Error(_) -> wisp.html_response("Geçersiz ID", 400)
        }
      })
    Get, ["admin", "projects"], True ->
      protected(req, db, fn() {
        wisp.html_response(cms.admin_entries(csrf_token, db, "projects"), 200)
      })
    Get, ["admin", "projects", id_str, "edit"], True ->
      protected(req, db, fn() {
        case int.parse(id_str) {
          Ok(id) ->
            wisp.html_response(
              cms.admin_edit_page(csrf_token, db, "projects", id),
              200,
            )
          Error(_) -> wisp.html_response("Geçersiz ID", 400)
        }
      })
    Post, ["admin", "pages"], True ->
      protected(req, db, fn() { create_page(req, db) })
    Post, ["admin", "projects"], True ->
      protected(req, db, fn() { create_entry(req, db, "projects") })
    Post, ["admin", "pages", id_str, "update"], True ->
      protected(req, db, fn() { update_page(req, db, id_str) })
    Post, ["admin", "projects", id_str, "update"], True ->
      protected(req, db, fn() { update_entry(req, db, "projects", id_str) })
    Post, ["admin", table, id, "delete"], True ->
      protected(req, db, fn() { delete_entry(db, table, id) })
    Post, ["admin", "save"], True -> protected(req, db, fn() { saved(req, db) })

    _, ["admin", ..], False ->
      wisp.html_response(
        "<main><h1>404</h1><a href='/'>Ana sayfa</a></main>",
        404,
      )

    // --- HTMX ---
    Get, ["hx", "regions"], _ -> wisp.html_response(regions, 200)
    Post, ["hx", "contact"], _ -> message(req, db, csrf_token)
    Post, ["hx", "chat"], _ -> chat_message(req, csrf_token)

    // --- Static files ---
    Get, ["sitemap.xml"], _ ->
      wisp.html_response(cms.sitemap(db), 200)
      |> response.set_header("content-type", "application/xml; charset=utf-8")
    Get, ["robots.txt"], _ ->
      wisp.html_response(
        "User-agent: *\nAllow: /\nDisallow: /admin\nSitemap: https://mamon.tr/sitemap.xml\n",
        200,
      )
      |> response.set_header("content-type", "text/plain; charset=utf-8")

    _, _, _ ->
      wisp.html_response(
        "<main><h1>404</h1><a href='/'>Ana sayfa</a></main>",
        404,
      )
  }
}

fn render_page_by_slug(
  db: database.Database,
  slug: String,
  kind: String,
) -> wisp.Response {
  case database.find_entry(db, "pages", slug) {
    Some(entry) -> {
      let _ = io.println("✓ Sayfa bulundu: " <> slug)
      let is_en = kind == "en" || entry.category == "en"
      let footer_html = case is_en {
        True -> cms.en_footer
        False -> cms.corporate_footer
      }
      let nav_path = case is_en {
        True ->
          case slug {
            "en" -> "/en/"
            _ -> "/en/" <> slug <> "/"
          }
        False ->
          case slug {
            "anasayfa" -> "/"
            _ -> "/" <> slug <> "/"
          }
      }
      let nav_html = case is_en {
        True -> cms.en_nav(nav_path)
        False -> cms.nav(nav_path)
      }
      wisp.html_response(cms.page_template(entry, nav_html, footer_html), 200)
    }
    None -> {
      let _ = io.println("✗ Sayfa bulunamadı: " <> slug)
      case kind {
        "en" ->
          wisp.html_response(
            "<main><h1>Page not found</h1><a href='/en/'>Home</a></main>",
            404,
          )
        _ ->
          wisp.html_response(
            "<main><h1>Sayfa bulunamadı</h1><a href='/'>Ana sayfa</a></main>",
            404,
          )
      }
    }
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

fn current_admin(req: wisp.Request, db: database.Database) {
  case wisp.get_cookie(req, "mamon_session", wisp.Signed) {
    Ok(value) ->
      case int.parse(value) {
        Ok(id) -> database.find_active_admin(db, id)
        Error(_) -> None
      }
    Error(_) -> None
  }
}

fn protected(
  req: wisp.Request,
  db: database.Database,
  next: fn() -> wisp.Response,
) -> wisp.Response {
  case current_admin(req, db) {
    None -> wisp.redirect("/admin/login")
    Some(_) ->
      case req.method {
        Post ->
          case csrf.validate_header(req) {
            True -> next()
            False ->
              wisp.html_response(
                "<main><h1>403</h1><p>CSRF token geçersiz.</p><a href='/admin'>Panele dön</a></main>",
                403,
              )
          }
        _ -> next()
      }
  }
}

fn admin_dashboard(csrf_token: String, db: database.Database) -> String {
  let hx =
    "hx-headers='" <> "{\"x-csrf-token\":\"" <> csrf_token <> "\"}" <> "'"
  let csrf_field =
    "<input type='hidden' name='_csrf_token' value='" <> csrf_token <> "'>"
  let all_pages = database.list_all_pages(db)
  let page_count = list.length(all_pages)
  let all_projects = database.list_entries(db, "projects")
  let project_count = list.length(all_projects)
  "<!doctype html><html lang='tr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Mamon Yönetim</title><link rel='stylesheet' href='/static/styles.css'><link rel='stylesheet' href='/static/admin.css'><script src='https://cdn.jsdelivr.net/npm/htmx.org@2.0.8/dist/htmx.min.js' defer></script></head><body class='admin-body' "
  <> hx
  <> "><aside><a class='brand' href='/'><i>M</i>MAMON</a><small>YÖNETİM PANELİ</small><nav><a class='active' href='/admin'>⌂ Genel Bakış</a><a href='/admin/pages'>▤ Sayfalar</a><a href='/admin/projects'>◈ Projeler</a></nav><form class='logout-form' method='post' action='/admin/logout'>"
  <> csrf_field
  <> "<button>Oturumu kapat</button></form><a class='back' href='/'>← Siteye dön</a></aside><main class='admin-main'><header><div><small>YÖNETİM PANELİ</small><h1>Genel Bakış</h1></div></header><section class='admin-stats'><article><span>TOPLAM SAYFA</span><b>"
  <> int.to_string(page_count)
  <> "</b><small>Tümü yayında</small></article><article><span>TOPLAM PROJE</span><b>"
  <> int.to_string(project_count)
  <> "</b><small>Aktif projeler</small></article><article><span>FAALİYET ALANI</span><b>3</b><small>Turizm, emlak, inşaat</small></article><article><span>SON GÜNCELLEME</span><b>Bugün</b><small>—</small></article></section><section class='admin-grid'><div class='panel'><header><div><small>HIZLI ERİŞİM</small><h2>Sayfalar</h2></div></header><div class='quick-links'><a href='/admin/pages'>TÜM SAYFALAR →</a><a href='/admin/pages?cat=anasayfa'>Ana Sayfa</a><a href='/admin/pages?cat=kurumsal'>Kurumsal</a><a href='/admin/pages?cat=turizm'>Turizm</a><a href='/admin/pages?cat=emlak'>Emlak</a><a href='/admin/pages?cat=insaat'>İnşaat</a><a href='/admin/pages?cat=iletisim'>İletişim</a><a href='/admin/pages?cat=en'>English</a></div></div><div class='panel'><header><div><small>SAYFA DÜZENLEYİCİ</small><h2>Ana sayfa içerikleri</h2></div></header><form hx-post='/admin/save' hx-target='#save' hx-swap='innerHTML'>"
  <> csrf_field
  <> "<label>Üst başlık<input name='eyebrow' value='2010 DAN BERİ GÜVENLE'></label><label>Ana başlık<textarea name='title'>Köklü deneyim. Kalıcı değer.</textarea></label><label>Açıklama<textarea name='description'>Turizm, emlak ve inşaatta köklü deneyimi; teknoloji, güven ve insan odaklı hizmetle buluşturuyoruz.</textarea></label><div class='save-row'><div id='save'></div><button class='btn accent'>Kaydet</button></div></form></div></section></main></body></html>"
}

fn login(
  req: wisp.Request,
  db: database.Database,
  csrf_token: String,
) -> wisp.Response {
  use form <- wisp.require_form(req)
  let csrf_value =
    list.key_find(form.values, "_csrf_token") |> result.unwrap("")
  case csrf.validate(req, csrf_value) {
    False ->
      wisp.html_response(
        auth_pages.login(csrf_token, "CSRF token geçersiz."),
        403,
      )
    True -> {
      let ip = get_client_ip(req)
      case rate_limit.check_rate(ip <> ":login", 5, 900) {
        False ->
          wisp.html_response(
            auth_pages.login(
              csrf_token,
              "Çok fazla deneme. 15 dakika sonra tekrar deneyin.",
            ),
            429,
          )
        True -> {
          let email =
            list.key_find(form.values, "email")
            |> result.unwrap("")
            |> account_auth.normalize_email
          let password =
            list.key_find(form.values, "password") |> result.unwrap("")
          case database.find_admin_by_email(db, email) {
            Some(#(database.AdminUser(id, _, _, True), hash)) ->
              case account_auth.verify_password(password, hash) {
                True ->
                  wisp.redirect("/admin")
                  |> wisp.set_cookie(
                    req,
                    "mamon_session",
                    int.to_string(id),
                    wisp.Signed,
                    60 * 60 * 8,
                  )
                False ->
                  wisp.html_response(
                    auth_pages.login(csrf_token, "E-posta veya parola hatalı."),
                    401,
                  )
              }
            _ ->
              wisp.html_response(
                auth_pages.login(csrf_token, "E-posta veya parola hatalı."),
                401,
              )
          }
        }
      }
    }
  }
}

fn register(
  req: wisp.Request,
  db: database.Database,
  csrf_token: String,
) -> wisp.Response {
  use form <- wisp.require_form(req)
  let csrf_value =
    list.key_find(form.values, "_csrf_token") |> result.unwrap("")
  case csrf.validate(req, csrf_value) {
    False ->
      wisp.html_response(
        auth_pages.register(csrf_token, "CSRF token geçersiz."),
        403,
      )
    True -> {
      let ip = get_client_ip(req)
      case rate_limit.check_rate(ip <> ":register", 3, 3600) {
        False ->
          wisp.html_response(
            auth_pages.register(
              csrf_token,
              "Çok fazla deneme. 1 saat sonra tekrar deneyin.",
            ),
            429,
          )
        True -> {
          let get = fn(key) {
            list.key_find(form.values, key) |> result.unwrap("")
          }
          let email = get("email") |> account_auth.normalize_email
          let password = get("password")
          let confirm = get("password_confirm")
          let name = get("display_name")
          case
            database.admin_count(db),
            account_auth.valid_email(email),
            account_auth.valid_password(password),
            password == confirm
          {
            0, True, True, True ->
              case
                database.create_admin(
                  db,
                  email,
                  account_auth.hash_password(password),
                  name,
                  True,
                )
              {
                True ->
                  wisp.html_response(
                    auth_pages.login(
                      csrf_token,
                      "Hesabınız oluşturuldu. Şimdi giriş yapabilirsiniz.",
                    ),
                    201,
                  )
                False ->
                  wisp.html_response(
                    auth_pages.register(csrf_token, "Hesap oluşturulamadı."),
                    400,
                  )
              }
            count, _, _, _ if count > 0 ->
              wisp.html_response(
                auth_pages.register(
                  csrf_token,
                  "Açık kayıt kapalıdır. Yeni kullanıcı için mevcut yöneticiyle iletişime geçin.",
                ),
                403,
              )
            _, _, False, _ ->
              wisp.html_response(
                auth_pages.register(
                  csrf_token,
                  "Parola en az 12 karakter olmalıdır.",
                ),
                400,
              )
            _, _, _, False ->
              wisp.html_response(
                auth_pages.register(csrf_token, "Parolalar eşleşmiyor."),
                400,
              )
            _, _, _, _ ->
              wisp.html_response(
                auth_pages.register(csrf_token, "Bilgileri kontrol edin."),
                400,
              )
          }
        }
      }
    }
  }
}

fn forgot_password(
  req: wisp.Request,
  db: database.Database,
  csrf_token: String,
) -> wisp.Response {
  use form <- wisp.require_form(req)
  let csrf_value =
    list.key_find(form.values, "_csrf_token") |> result.unwrap("")
  case csrf.validate(req, csrf_value) {
    False ->
      wisp.html_response(
        auth_pages.forgot(csrf_token, "CSRF token geçersiz."),
        403,
      )
    True -> {
      let ip = get_client_ip(req)
      case rate_limit.check_rate(ip <> ":forgot", 3, 900) {
        False ->
          wisp.html_response(
            auth_pages.forgot(
              csrf_token,
              "Çok fazla deneme. 15 dakika sonra tekrar deneyin.",
            ),
            429,
          )
        True -> {
          let email =
            list.key_find(form.values, "email")
            |> result.unwrap("")
            |> account_auth.normalize_email
          let token = account_auth.random_token()
          let created =
            database.create_password_reset(
              db,
              email,
              account_auth.token_digest(token),
            )
          let _ = case created {
            True ->
              account_mail.send_reset(
                email,
                "https://mamon.tr/admin/reset-password/" <> token,
              )
            False -> False
          }
          wisp.html_response(
            auth_pages.forgot(
              csrf_token,
              "Hesap mevcutsa parola yenileme bağlantısı e-posta adresinize gönderildi.",
            ),
            200,
          )
        }
      }
    }
  }
}

fn reset_password(
  req: wisp.Request,
  db: database.Database,
  csrf_token: String,
) -> wisp.Response {
  use form <- wisp.require_form(req)
  let csrf_value =
    list.key_find(form.values, "_csrf_token") |> result.unwrap("")
  case csrf.validate(req, csrf_value) {
    False ->
      wisp.html_response(
        auth_pages.reset(csrf_token, "", "CSRF token geçersiz."),
        403,
      )
    True -> {
      let get = fn(key) { list.key_find(form.values, key) |> result.unwrap("") }
      let token = get("token")
      let password = get("password")
      let confirm = get("password_confirm")
      case account_auth.valid_password(password), password == confirm {
        True, True ->
          case
            database.reset_password(
              db,
              account_auth.token_digest(token),
              account_auth.hash_password(password),
            )
          {
            True ->
              wisp.html_response(
                auth_pages.login(
                  csrf_token,
                  "Parolanız güncellendi. Giriş yapabilirsiniz.",
                ),
                200,
              )
            False ->
              wisp.html_response(
                auth_pages.reset(
                  csrf_token,
                  token,
                  "Bağlantı geçersiz veya süresi dolmuş.",
                ),
                400,
              )
          }
        False, _ ->
          wisp.html_response(
            auth_pages.reset(
              csrf_token,
              token,
              "Parola en az 12 karakter olmalıdır.",
            ),
            400,
          )
        _, False ->
          wisp.html_response(
            auth_pages.reset(csrf_token, token, "Parolalar eşleşmiyor."),
            400,
          )
      }
    }
  }
}

fn logout(req: wisp.Request, csrf_token: String) -> wisp.Response {
  use form <- wisp.require_form(req)
  let csrf_value =
    list.key_find(form.values, "_csrf_token") |> result.unwrap("")
  case csrf.validate(req, csrf_value) {
    False ->
      wisp.html_response(
        auth_pages.login(csrf_token, "CSRF token geçersiz."),
        403,
      )
    True ->
      wisp.redirect("/admin/login")
      |> wisp.set_cookie(req, "mamon_session", "", wisp.Signed, 0)
  }
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

fn show_en_entry(db, slug) {
  case database.find_entry(db, "pages", slug) {
    Some(entry) -> wisp.html_response(cms.en_entry_page(entry), 200)
    None ->
      wisp.html_response(
        "<main><h1>Page not found</h1><a href='/en/'>Home</a></main>",
        404,
      )
  }
}

fn create_page(req, db) {
  use form <- wisp.require_form(req)
  let get = fn(key) { list.key_find(form.values, key) |> result.unwrap("") }
  let created =
    database.create_page(
      db,
      get("title"),
      get("slug"),
      get("summary"),
      get("body"),
      get("seo_title"),
      get("seo_description"),
      get("category"),
    )
  case created {
    True -> wisp.html_response(cms.admin_entries("", db, "pages"), 201)
    False ->
      wisp.html_response(
        "Sayfa oluşturulamadı. URL kısa adı benzersiz olmalıdır.",
        400,
      )
  }
}

fn create_entry(req, db, table) {
  use form <- wisp.require_form(req)
  let get = fn(key) { list.key_find(form.values, key) |> result.unwrap("") }
  let created =
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
  case created {
    True -> wisp.html_response(cms.admin_entries("", db, table), 201)
    False ->
      wisp.html_response(
        "Proje oluşturulamadı. URL kısa adı benzersiz olmalıdır.",
        400,
      )
  }
}

fn update_page(req, db, id_str) {
  use form <- wisp.require_form(req)
  let get = fn(key) { list.key_find(form.values, key) |> result.unwrap("") }
  case int.parse(id_str) {
    Ok(id) -> {
      let updated =
        database.update_page(
          db,
          id,
          get("title"),
          get("slug"),
          get("summary"),
          get("body"),
          get("seo_title"),
          get("seo_description"),
          get("category"),
        )
      mutation_response(updated, "Değişiklikler kaydedildi.")
    }
    Error(_) -> wisp.html_response("Geçersiz ID", 400)
  }
}

fn update_entry(req, db, table, id_str) {
  use form <- wisp.require_form(req)
  let get = fn(key) { list.key_find(form.values, key) |> result.unwrap("") }
  case int.parse(id_str) {
    Ok(id) -> {
      let updated =
        database.update_entry(
          db,
          table,
          id,
          get("title"),
          get("slug"),
          get("summary"),
          get("body"),
          get("seo_title"),
          get("seo_description"),
        )
      mutation_response(updated, "Değişiklikler kaydedildi.")
    }
    Error(_) -> wisp.html_response("Geçersiz ID", 400)
  }
}

fn delete_entry(db, table, id) {
  case int.parse(id) {
    Ok(id) -> {
      case database.delete_entry(db, table, id) {
        True -> wisp.html_response("", 200)
        False -> wisp.html_response("Kayıt silinemedi.", 500)
      }
    }
    Error(_) -> wisp.html_response("Geçersiz kayıt", 400)
  }
}

fn mutation_response(success: Bool, message: String) -> wisp.Response {
  case success {
    True ->
      wisp.html_response("<div class='saved'>✓ " <> message <> "</div>", 200)
    False ->
      wisp.html_response(
        "<div class='saved'>İşlem gerçekleştirilemedi.</div>",
        500,
      )
  }
}

fn chat_message(req: wisp.Request, _csrf_token: String) -> wisp.Response {
  use form <- wisp.require_form(req)
  let csrf_value =
    list.key_find(form.values, "_csrf_token") |> result.unwrap("")
  case csrf.validate(req, csrf_value) {
    False -> wisp.html_response("CSRF token geçersiz.", 403)
    True -> {
      let ip = get_client_ip(req)
      case rate_limit.check_rate(ip <> ":chat", 10, 60) {
        False -> wisp.html_response("Çok fazla istek. Biraz bekleyin.", 429)
        True -> {
          let question =
            list.key_find(form.values, "message") |> result.unwrap("")
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
      }
    }
  }
}

fn message(
  req: wisp.Request,
  db: database.Database,
  _csrf_token: String,
) -> wisp.Response {
  use form <- wisp.require_form(req)
  case public_form_origin_allowed(req) {
    False -> wisp.html_response("CSRF token geçersiz.", 403)
    True -> {
      let ip = get_client_ip(req)
      case rate_limit.check_rate(ip <> ":contact", 5, 900) {
        False ->
          wisp.html_response(
            "Çok fazla istek. 15 dakika sonra tekrar deneyin.",
            429,
          )
        True -> {
          let name = list.key_find(form.values, "name") |> result.unwrap("")
          let email = list.key_find(form.values, "email") |> result.unwrap("")
          let area = list.key_find(form.values, "area") |> result.unwrap("")
          let text = list.key_find(form.values, "message") |> result.unwrap("")
          case
            database.save_contact(db, name, email, area, text),
            account_mail.send_contact(name, email, area, text)
          {
            True, True ->
              wisp.html_response(
                "<div class='success'><b>Talebiniz alındı.</b><span>Ekibimiz en kısa sürede sizinle iletişime geçecek.</span></div>",
                200,
              )
            False, _ ->
              wisp.html_response(
                "<div class='success'><b>Talep kaydedilemedi.</b><span>Lütfen doğrudan e-posta ile iletişime geçin.</span></div>",
                503,
              )
            True, False ->
              wisp.html_response(
                "<div class='success'><b>Talebiniz kaydedildi ancak e-posta bildirimi gönderilemedi.</b><span>Ekibimiz yönetim kayıtlarından mesajınıza erişebilir.</span></div>",
                202,
              )
          }
        }
      }
    }
  }
}

fn public_form_origin_allowed(req: wisp.Request) -> Bool {
  let origin = request.get_header(req, "origin") |> result.unwrap("")
  list.contains(
    [
      "https://mamon.tr",
      "https://www.mamon.tr",
      "https://mamon.com.tr",
      "https://www.mamon.com.tr",
      "http://localhost:8000",
      "http://127.0.0.1:8000",
    ],
    origin,
  )
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

const regions = "<div class='region-cards'><article><small>01 / AKDENİZ</small><h3>Antalya</h3><p>Şehir merkezinden kıyı bölgelerine uzanan emlak ve inşaat uzmanlığı.</p></article><article><small>02 / EGE</small><h3>Muğla</h3><p>Bodrum, Fethiye ve çevresinde seçkin yatırım fırsatları.</p></article></div>"
