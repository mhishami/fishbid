-module (model_user).
-include ("fishbid.hrl").

-export ([new/7]).
-export ([save/1]).
-export ([update/2]).
-export ([get_all/0]).
-export ([get_by_id/1]).
-export ([authenticate/2]).
-export ([reset_password/1]).
-export ([ensure_index/0]).

-spec new(Username::binary(), Fullname::binary(), Role::binary(), Email::binary(), 
    Mobile::binary(), Password::binary(), Admin::any()) -> any().
new(Username, Fullname, Role, Email, Mobile, Password, Admin) ->
    ?INFO("~p: Creating a new user: ~p, ~p, ~p", [Admin, Username, Role, Fullname]),

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
       <<"created_by">> => Admin,
       <<"updated_by">> => Admin}.

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

-spec get_all() -> map().
get_all() ->
    {ok, Users} = mongo_worker:match(?DB_USERS, {}, {<<"username">>, 1}),
    Users.

get_by_id(Id) ->
    {ok, User} = mongo_worker:find_one(?DB_USERS, {<<"_id">>, Id}),
    User.

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
