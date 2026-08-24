# Mamon Kurumsal Web Sitesi

Gleam, Wisp, Mist ve HTMX ile hazırlanmış kurumsal web sitesi ve yönetim paneli.

- Kurumsal site: `http://localhost:8000/`
- Yönetim paneli: `http://localhost:8000/admin`

## Development

```sh
gleam run   # Siteyi 8000 portunda çalıştırır
gleam test  # Testleri çalıştırır
```

Yayına almadan önce `src/mamon.gleam` içindeki geliştirme amaçlı gizli anahtarın
ortam değişkeninden okunması ve yönetim paneline kimlik doğrulama eklenmesi gerekir.
