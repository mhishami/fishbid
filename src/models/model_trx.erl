-module (model_trx).
-include ("fishbid.hrl").

-export ([new/4]).
-export ([save/1]).
-export ([update/1]).
-export ([ensure_index/0]).

% -spec new(binary(), float(), float(), binary()) -> map().
new(UserId, Debit, Credit, Status) when is_binary(UserId),
                                        is_float(Debit),
                                        is_float(Credit),
                                        is_binary(Status) ->
    #{<<"_id">> => uuid:gen(),
      <<"user_id">> => UserId,
      <<"debit">> => Debit,
      <<"credit">> => Credit,
      <<"status">> => Status,
      <<"trx_ts">> => erlang:timestamp(),
      <<"created_at">> => erlang:timestamp(),
      <<"updated_at">> => erlang:timestamp()}.

% -spec save(any()) -> {ok, any()}.
save(Trx) ->
    mongo_worker:save(?DB_TRXS, Trx).

% -spec update(any()) -> {ok, any()}.
update(Trx) ->
    mongo_worker:update(?DB_TRXS, Trx#{<<"updated_at">> := erlang:timestamp()}).

% -spec ensure_index() -> {ok, any()}.
ensure_index() ->
    % mongo_worker:ensure_index(<<"posts">>, #{<<"key">> => {<<"grpid">>, 1}}).
    mongo_worker:ensure_index(?DB_TRXS, #{<<"key">> => #{<<"user_id">> => 1}}),
    mongo_worker:ensure_index(?DB_TRXS, #{<<"key">> => #{<<"status">> => 1}}),
    mongo_worker:ensure_index(?DB_TRXS, #{<<"key">> => #{<<"user_id">> => 1, <<"status">> => 1}}).

