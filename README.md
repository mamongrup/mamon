# Mamon Kurumsal Web Sitesi

Gleam, Wisp, Mist ve HTMX ile hazırlanmış kurumsal web sitesi ve yönetim paneli.

- Kurumsal site: `http://localhost:8000/`
- Yönetim paneli: `http://localhost:8000/admin`

## PostgreSQL

Uygulama `DATABASE_URL` ortam değişkeni üzerinden PostgreSQL'e bağlanır ve ilk
başlangıçta gerekli tabloları oluşturur. Örnek bağlantı `.env.example`
dosyasındadır.

```sh
DATABASE_URL=postgresql://mamon_user:parola@127.0.0.1:5432/mamon?sslmode=disable
```

Üretimde doğrulanmış TLS için bağlantı adresinde `sslmode=verify-full`
kullanılmalıdır. Şema ayrıca `sql/001_initial.sql` içinde tutulur.

## Development

```sh
gleam run   # Siteyi 8000 portunda çalıştırır
gleam test  # Testleri çalıştırır
```

Yayına almadan önce `src/mamon.gleam` içindeki geliştirme amaçlı gizli anahtarın
ortam değişkeninden okunması ve yönetim paneline kimlik doğrulama eklenmesi gerekir.
