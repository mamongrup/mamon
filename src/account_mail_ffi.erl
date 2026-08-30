-module(account_mail_ffi).
-export([send_reset/2, send_contact/4]).

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

send_contact(Name, Email, Area, Body) ->
    case os:find_executable("sendmail") of
        false -> false;
        Program ->
            SafeEmail = sanitize_header(Email),
            Message = iolist_to_binary([
                "To: info@mamon.com.tr\n",
                "From: Mamon Web Sitesi <noreply@mamon.tr>\n",
                "Reply-To: ", SafeEmail, "\n",
                "Subject: Mamon web sitesi yeni iletisim mesaji\n",
                "Content-Type: text/plain; charset=UTF-8\n\n",
                "Web sitesinden yeni bir iletisim mesaji alindi.\n\n",
                "Ad Soyad: ", Name, "\n",
                "E-posta: ", Email, "\n",
                "Ilgi Alani: ", Area, "\n\n",
                "Mesaj:\n", Body, "\n"
            ]),
            Port = open_port({spawn_executable, Program}, [binary, exit_status, {args, ["-t"]}]),
            true = port_command(Port, Message),
            true = port_command(Port, eof),
            true
    end.

sanitize_header(Value) ->
    binary:replace(binary:replace(Value, <<"\r">>, <<>>, [global]), <<"\n">>, <<>>, [global]).
