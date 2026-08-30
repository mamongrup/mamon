@external(erlang, "account_mail_ffi", "send_reset")
pub fn send_reset(email: String, url: String) -> Bool

@external(erlang, "account_mail_ffi", "send_contact")
pub fn send_contact(
  name: String,
  email: String,
  area: String,
  message: String,
) -> Bool
