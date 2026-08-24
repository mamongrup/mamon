/// ETS tabanlı sabit pencere rate limiter.
/// Her istek anahtarı (IP + endpoint) için pencere süresince
/// izin verilen maksimum istek sayısını kontrol eder.

@external(erlang, "rate_limit_ffi", "init")
pub fn init() -> Nil

@external(erlang, "rate_limit_ffi", "check_rate")
pub fn check_rate(key: String, limit: Int, window_seconds: Int) -> Bool
