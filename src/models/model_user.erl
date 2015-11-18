-module (model_user).
-include ("fishbid.hrl").

-export ([new/7]).
-export ([make_admin/0]).
-export ([save/1]).
-export ([update/2]).
-export ([deactivate/2]).
-export ([activate/2]).
-export ([get_all/0]).
-export ([get_users_count/0]).
-export ([get_by_id/1]).
-export ([get_by_username/1]).
-export ([authenticate/2]).
-export ([reset_password/1]).
-export ([ensure_index/0]).

-spec new(Username::binary(), Fullname::binary(), Role::binary(), Email::binary(), 
    Mobile::binary(), Password::binary(), Who::any()) -> any().
new(Username, Fullname, Role, Email, Mobile, Password, Who) ->
    ?INFO("~p: Creating a new user: ~p, ~p, ~p", [Who, Username, Role, Fullname]),

    #{ <<"_id">> => uuid:gen(),
       <<"username">> => Username,
       <<"fullname">> => Fullname,
       <<"password">> => web_util:hash_password(Password),
       <<"email">> => Email,
       <<"mobile">> => Mobile,
       <<"about">> => <<"">>,
       <<"role">> => Role,
       <<"balances">> => 0.0,
       <<"created_at">> => erlang:timestamp(),
       <<"updated_at">> => erlang:timestamp(),
       <<"created_by">> => Who,
       <<"updated_by">> => Who}.

-spec make_admin() -> {ok, any()}.
make_admin() ->
    User = new(<<"hisham">>, 
               <<"Hisham Ismail">>, 
               <<"admin">>, 
               <<"mhishami@gmail.com">>, 
               <<"0196622165">>,
               <<"sa">>,
               #{<<"username">> => <<"hisham">>, <<"role">> => <<"admin">>}),
    save(User),
    UserId = maps:get(<<"_id">>, User),
    model_trx:init(UserId).


-spec save(User::map()) -> {ok, any()}.
save(User) ->
    mongo_worker:save(?DB_USERS, User).

-spec update(User::map(), Who::any()) -> {ok, any()}.
update(User, Who) ->
    mongo_worker:update(?DB_USERS, 
        User#{ 
            <<"updated_at">> => erlang:timestamp(),
            <<"updated_by">> => Who
        }).

-spec deactivate(UserId::binary(), Who::map()) -> {ok, any()}.
deactivate(UserId, Who) ->
    {ok, User} = mongo_worker:find_one(?DB_USERS, {<<"_id">>, UserId}),
    mongo_worker:update(?DB_USERS, 
        User#{ 
            <<"updated_at">> => erlang:timestamp(),
            <<"updated_by">> => Who,
            <<"status">> => <<"inactive">>
        }).

-spec activate(UserId::binary(), Who::map()) -> {ok, any()}.
activate(UserId, Who) ->
    {ok, User} = mongo_worker:find_one(?DB_USERS, {<<"_id">>, UserId}),
    mongo_worker:update(?DB_USERS, 
        User#{ 
            <<"updated_at">> => erlang:timestamp(),
            <<"updated_by">> => Who,
            <<"status">> => <<"active">>
        }).

-spec get_all() -> map().
get_all() ->
    {ok, Users} = mongo_worker:match(?DB_USERS, {<<"status">>, {<<"$ne">>, <<"inactive">>}}, {<<"username">>, 1}),
    Users.

-spec get_users_count() -> integer().
get_users_count() ->
    {ok, Count} = mongo_worker:count(?DB_USERS, {}),
    Count.

-spec get_by_id(Id::binary()) -> map().
get_by_id(Id) ->
    {ok, User} = mongo_worker:find_one(?DB_USERS, {<<"_id">>, Id}),
    User.

-spec get_by_username(Username::binary()) -> map().
get_by_username(Username) ->
    case mongo_worker:find_one(?DB_USERS, 
            {<<"username">>, Username},
            [{projector, #{<<"username">> => 1, <<"role">> => 1}}]) of
        {ok, User} -> User;
        _ -> #{}
    end.

-spec authenticate(binary(), binary()) -> ok | error.
authenticate(Username, Password) when is_binary(Username),
                                      is_binary(Password) ->
    case mongo_worker:find_one(?DB_USERS, {<<"username">>, Username}) of
        {ok, User} ->
            %% ok, process the password
            HashPass = web_util:hash_password(Password),
            case HashPass =:= maps:get(<<"password">>, User) of
                true -> 
                    {ok, User};
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
    mongo_worker:ensure_index(?DB_USERS, #{<<"key">> => #{<<"password">> => 1}}),
    ok.
