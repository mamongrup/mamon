-module(auth_ffi).
-export([pbkdf2/3]).

pbkdf2(Password, Salt, Iterations) ->
    crypto:pbkdf2_hmac(sha256, Password, Salt, Iterations, 32).
