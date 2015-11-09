-module (model_user).
-include ("fishbid.hrl").

-export ([new/4]).
-export ([save/1]).
-export ([update/1]).
-export ([authenticate/2]).
-export ([reset_password/1]).
-export ([ensure_index/0]).

-spec new(binary(), binary(), binary(), binary()) -> map().
new(Username, Email, Role, Password) when is_binary(Username),
                                          is_binary(Email),
                                          is_binary(Role),
                                          is_binary(Password) ->
    #{ <<"_id">> => uuid:gen(),
       <<"username">> => Username,
       <<"password">> => web_util:hash_password(Password),
       <<"email">> => Email,
       <<"role">> => Role,
       <<"balances">> => 0.0,
       <<"created_at">> => erlang:timestamp(),
       <<"updated_at">> => erlang:timestamp()}.

-spec save(map()) -> {ok, any()}.
save(User) ->
    mongo_worker:save(?DB_USERS, User).

-spec update(map()) -> {ok, any()}.
update(User) ->
    mongo_worker:update(?DB_USERS, User#{ <<"updated_at">> := erlang:timestamp()}).

-spec authenticate(binary(), binary()) -> ok | error.
authenticate(Username, Password) when is_binary(Username),
                                      is_binary(Password) ->
    case mongo_worker:find_one(?DB_USERS, {<<"username">>, Username}) of
        {ok, User} ->
            %% ok, process the password
            HashPass = web_util:hash_password(Password),
            case HashPass =:= maps:get(<<"password">>, User) of
                true -> 
                    ok;
                _ ->
                    error
            end;
        _ ->
            error
    end.

-spec reset_password(binary()) -> ok.
reset_password(_Email) ->
    ok.

-spec ensure_index() -> {ok, any()}.
ensure_index() ->
    mongo_worker:ensure_index(?DB_USERS, #{<<"key">> => #{<<"username">> => 1},
                                           <<"unique">> => true,
                                           <<"dropDups">> => true}),
    mongo_worker:ensure_index(?DB_USERS, #{<<"key">> => #{<<"email">> => 1},
                                           <<"unique">> => true,
                                           <<"dropDups">> => true}),
    mongo_worker:ensure_index(?DB_USERS, #{<<"key">> => #{<<"email">> => 1, <<"username">> => 1},
                                           <<"unique">> => true,
                                           <<"dropDups">> => true}),
    mongo_worker:ensure_index(?DB_USERS, #{<<"key">> => #{<<"password">> => 1}}).
