-module(account_mail_ffi).
-export([send_reset/2]).

send_reset(Email, Url) ->
    case os:find_executable("sendmail") of
        false -> false;
        Program ->
            Message = iolist_to_binary([
                "To: ", Email, "\n",
                "From: Mamon <noreply@mamon.tr>\n",
                "Subject: Mamon yonetim paneli parola yenileme\n",
                "Content-Type: text/plain; charset=UTF-8\n\n",
                "Parolanizi yenilemek icin 30 dakika icinde bu baglantiyi kullanin:\n",
                Url, "\n\nBu talebi siz yapmadiysaniz bu mesaji yok sayin.\n"
            ]),
            Port = open_port({spawn_executable, Program}, [binary, exit_status, {args, ["-t"]}]),
            true = port_command(Port, Message),
            true = port_command(Port, eof),
            true
    end.
