import cms

const styles = "<style>*{box-sizing:border-box}body{margin:0;background:#fff9e9;color:#123b40;font-family:Arial,sans-serif}.auth{min-height:100vh;display:grid;grid-template-columns:1fr 1fr}.auth-brand{background:#06444c;color:white;padding:8vw;display:flex;flex-direction:column;justify-content:space-between}.auth-brand a{color:#ffcc01;font-weight:800;letter-spacing:.18em}.auth-brand h1{font:400 58px/1.05 Georgia;margin:30px 0}.auth-brand small{color:#ffcc01}.auth-brand p{color:#b8dcde;line-height:1.7}.auth-panel{display:grid;place-items:center;padding:40px}.auth-box{width:min(430px,100%)}.auth-box small{letter-spacing:.16em;color:#e66221;font-weight:700}.auth-box h2{font:400 38px Georgia;margin:14px 0 8px}.auth-box>p{color:#58757a;line-height:1.6}.auth-form{display:grid;gap:17px;margin-top:30px}.auth-form label{font-size:11px;font-weight:700;display:grid;gap:8px}.auth-form input{width:100%;padding:15px;border:1px solid #bcd7d5;background:white;font-size:14px}.auth-form input:focus{outline:2px solid #0e9ca8;outline-offset:1px}.auth-form button{padding:16px;background:#e66221;color:white;border:0;font-weight:700;cursor:pointer}.auth-form button:hover{background:#c94d14}.auth-links{display:flex;justify-content:space-between;margin-top:20px;font-size:12px}.auth-links a{color:#08717a}.notice{padding:13px 15px;background:#fff0c0;border-left:3px solid #e66221;font-size:12px;line-height:1.5;margin-top:20px}.error{background:#f4dede;border-color:#a64040;color:#7d2525}@media(max-width:760px){.auth{grid-template-columns:1fr}.auth-brand{padding:35px;min-height:260px}.auth-brand h1{font-size:40px}.auth-panel{padding:50px 22px}}</style>"

fn page(
  title: String,
  heading: String,
  intro: String,
  content: String,
) -> String {
  "<!doctype html><html lang='tr'><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><meta name='robots' content='noindex,nofollow'><link rel='icon' href='/static/favicon.png'><title>"
  <> cms.escape(title)
  <> " | Mamon Yönetim</title>"
  <> styles
  <> "</head><body><main class='auth'><section class='auth-brand'><a href='/'>MAMON</a><div><small>YÖNETİM PLATFORMU</small><h1>İçeriğinizi<br>güvenle yönetin.</h1><p>Sayfalar, projeler ve kurumsal içerikler için tek merkez.</p></div><span>© 2026 Mamon</span></section><section class='auth-panel'><div class='auth-box'><small>GÜVENLİ HESAP</small><h2>"
  <> heading
  <> "</h2><p>"
  <> intro
  <> "</p>"
  <> content
  <> "</div></section></main></body></html>"
}

pub fn login(csrf_token: String, message: String) -> String {
  let notice = case message {
    "" -> ""
    _ -> "<div class='notice error'>" <> cms.escape(message) <> "</div>"
  }
  let csrf_field =
    "<input type='hidden' name='_csrf_token' value='" <> csrf_token <> "'>"
  page(
    "Giriş",
    "Panel girişi",
    "Yönetim hesabınızla güvenli oturum açın.",
    notice
      <> "<form class='auth-form' method='post' action='/admin/login'>"
      <> csrf_field
      <> "<label>E-posta adresi<input type='email' name='email' autocomplete='email' required></label><label>Parola<input type='password' name='password' autocomplete='current-password' required></label><button>Oturum aç</button></form><div class='auth-links'><a href='/admin/forgot-password'>Parolamı unuttum</a><a href='/admin/register'>Hesap oluştur</a></div>",
  )
}

pub fn register(csrf_token: String, message: String) -> String {
  let notice = case message {
    "" -> ""
    _ -> "<div class='notice error'>" <> cms.escape(message) <> "</div>"
  }
  let csrf_field =
    "<input type='hidden' name='_csrf_token' value='" <> csrf_token <> "'>"
  page(
    "Hesap Oluştur",
    "Hesap oluşturun",
    "Güvenlik için yalnızca ilk yönetici hesabı buradan oluşturulabilir; ardından açık kayıt otomatik kapanır.",
    notice
      <> "<form class='auth-form' method='post' action='/admin/register'>"
      <> csrf_field
      <> "<label>Ad soyad<input name='display_name' autocomplete='name' minlength='2' required></label><label>E-posta adresi<input type='email' name='email' autocomplete='email' required></label><label>Parola<input type='password' name='password' autocomplete='new-password' minlength='12' required></label><label>Parola tekrar<input type='password' name='password_confirm' autocomplete='new-password' minlength='12' required></label><button>Hesap oluştur</button></form><div class='auth-links'><a href='/admin/login'>Zaten hesabınız var mı?</a></div>",
  )
}

pub fn forgot(csrf_token: String, message: String) -> String {
  let notice = case message {
    "" -> ""
    _ -> "<div class='notice'>" <> cms.escape(message) <> "</div>"
  }
  let csrf_field =
    "<input type='hidden' name='_csrf_token' value='" <> csrf_token <> "'>"
  page(
    "Parola Hatırlatma",
    "Parolanızı yenileyin",
    "Hesabınıza ait e-posta adresini girin. Geçerli hesap varsa güvenli sıfırlama kaydı oluşturulur.",
    notice
      <> "<form class='auth-form' method='post' action='/admin/forgot-password'>"
      <> csrf_field
      <> "<label>E-posta adresi<input type='email' name='email' autocomplete='email' required></label><button>Sıfırlama bağlantısı iste</button></form><div class='auth-links'><a href='/admin/login'>Giriş sayfasına dön</a></div>",
  )
}

pub fn reset(csrf_token: String, token: String, message: String) -> String {
  let notice = case message {
    "" -> ""
    _ -> "<div class='notice error'>" <> cms.escape(message) <> "</div>"
  }
  let csrf_field =
    "<input type='hidden' name='_csrf_token' value='" <> csrf_token <> "'>"
  page(
    "Yeni Parola",
    "Yeni parola belirleyin",
    "En az 12 karakterden oluşan güçlü bir parola kullanın.",
    notice
      <> "<form class='auth-form' method='post' action='/admin/reset-password'>"
      <> csrf_field
      <> "<input type='hidden' name='token' value='"
      <> cms.escape(token)
      <> "'><label>Yeni parola<input type='password' name='password' autocomplete='new-password' minlength='12' required></label><label>Yeni parola tekrar<input type='password' name='password_confirm' autocomplete='new-password' minlength='12' required></label><button>Parolayı güncelle</button></form>",
  )
}
