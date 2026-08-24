-module(rate_limit_ffi).
-export([init/0, check_rate/3]).

%% ETS tablosunu oluştur (named_table, public)
init() ->
    try ets:new(rate_limits, [set, public, named_table, {write_concurrency, true}]) of
        _ -> ok
    catch
        error:badarg -> ok
    end.

%% Pencere süresi içindeki istek sayısını kontrol et
%% Key = "IP:endpoint" formatında benzersiz anahtar
%% Limit = pencere başına izin verilen maksimum istek
%% WindowSeconds = pencere süresi (saniye)
check_rate(Key, Limit, WindowSeconds) ->
    Now = erlang:system_time(second),
    case ets:lookup(rate_limits, Key) of
        [{Key, Count, First}] when (Now - First) < WindowSeconds ->
            case Count < Limit of
                true ->
                    ets:insert(rate_limits, {Key, Count + 1, First}),
                    true;
                false ->
                    false
            end;
        _ ->
            ets:insert(rate_limits, {Key, 1, Now}),
            true
    end.
