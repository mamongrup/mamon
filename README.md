# Mamon Kurumsal Web Sitesi

Gleam, Wisp, Mist ve HTMX ile hazırlanmış kurumsal web sitesi ve yönetim paneli.

- Kurumsal site: `http://localhost:8000/`
- Yönetim paneli: `http://localhost:8000/admin`

## Alan adları

- `mamon.tr`: ön yüz ve yönetim paneli
- `mamon.com.tr`: aynı ön yüzün ikinci alan adı
- `mamon.com.tr/admin`: uygulama seviyesinde 404 döner

İki alan adı aynı Gleam uygulamasına yönlendirilir ve süreçte yalnızca tek bir
`DATABASE_URL` tanımlanır. Böylece sayfalar, projeler, iletişim talepleri ve diğer
içerikler aynı PostgreSQL veritabanından okunur. SEO açısından birincil alan adı
`mamon.tr` olduğu için canonical ve sitemap adresleri bu alan adında kalır.

Plesk'te `mamon.com.tr` alan adını ayrı bir uygulama olarak kurmak yerine
`mamon.tr` ile aynı document root/reverse proxy hedefine bağlayın. Her iki alan
adı ve `www` karşılıkları için SSL sertifikası oluşturun; proxy'nin özgün `Host`
başlığını uygulamaya ilettiğinden emin olun. Yönetim rotaları uygulama içinde
yalnızca `mamon.tr`, `www.mamon.tr` ve yerel geliştirme adreslerine açıktır.

## PostgreSQL

Uygulama `DATABASE_URL` ortam değişkeni üzerinden PostgreSQL'e bağlanır ve ilk
başlangıçta gerekli tabloları oluşturur. Örnek bağlantı `.env.example`
dosyasındadır.

```sh
DATABASE_URL=postgresql://mamon_user:parola@127.0.0.1:5432/mamon?sslmode=disable
```

Üretimde doğrulanmış TLS için bağlantı adresinde `sslmode=verify-full`
kullanılmalıdır. Şema ayrıca `sql/001_initial.sql` içinde tutulur.

## İçerik ve yapay zekâ

- `/admin/pages`: SEO alanlarıyla sayfa oluşturma ve silme
- `/admin/projects`: proje oluşturma ve silme
- `/sitemap.xml`: veritabanındaki yayınlara göre otomatik sitemap
- `/robots.txt`: arama motoru ve yönetim paneli kuralları
- `DEEPSEEK_API_KEY`: Mamon Asistan sohbet kutusunun sunucu anahtarı

DeepSeek anahtarı yalnızca sunucu ortamında tutulmalı, istemci koduna veya
Git deposuna yazılmamalıdır.

## Site mimarisi

Statik yayın paketi büyümeye uygun çok sayfalı yapıdadır:

- `/`: kurumsal ana sayfa
- `/kurumsal/`: şirket profili
- `/turizm/`: TÜRSAB ve turizm markaları
- `/emlak/`: emlak faaliyetleri
- `/insaat/`: inşaat faaliyetleri
- `/projeler/`: proje arşivi
- `/en/`: İngilizce giriş sayfası

Yeni projeler Gleam yönetim panelinden eklendiğinde kendilerine ait
`/projeler/{slug}` adreslerinde yayınlanacak şekilde modellenmiştir.

## Development

```sh
gleam run   # Siteyi 8000 portunda çalıştırır
gleam test  # Testleri çalıştırır
```

Yayında `SECRET_KEY_BASE` en az 64 rastgele karakterden oluşmalı; PostgreSQL
bağlantısı doğrulanmış TLS için `sslmode=verify-full` kullanmalıdır. Yönetim
panelinde imzalı oturum, CSRF koruması, giriş hız sınırı ve parola yenileme akışı
etkindir.
