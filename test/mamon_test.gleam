import account_auth
import cms
import database.{Entry}
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}

pub fn password_hash_round_trip_test() {
  let hash = account_auth.hash_password("GucluBirParola-2026")
  assert account_auth.verify_password("GucluBirParola-2026", hash)
  assert !account_auth.verify_password("yanlis-parola", hash)
}

pub fn account_validation_test() {
  assert account_auth.valid_email("yonetim@mamon.tr")
  assert !account_auth.valid_email("gecersiz")
  assert account_auth.valid_password("oniki-karakter")
  assert !account_auth.valid_password("kisa")
}

pub fn cms_entry_path_test() {
  let page = Entry(1, "Kurumsal", "kurumsal", "", "", "", "", "kurumsal")
  let project = Entry(2, "Proje", "ornek", "", "", "", "", "projeler")
  assert cms.entry_path(page) == "/kurumsal/"
  assert cms.entry_path(project) == "/projeler/ornek"
}
