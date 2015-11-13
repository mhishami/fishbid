-module (admin_controller).
-behaviour (tuah_controller).

-export ([handle_request/5]).
-export ([before_filter/1]).

-include ("fishbid.hrl").

before_filter(SessionId) ->
    %% do some checking
    Sid = session_worker:get_cookies(SessionId),
    case Sid of
        {error, undefined} ->
            {redirect, <<"/auth/login">>};
        _ ->
            {ok, proceed}
    end.

handle_request(<<"GET">>, <<"prices">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_prices">>, [{user, User}, {fishes, model_fish:get_all()}]};

handle_request(<<"POST">>, <<"prices">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    Name = proplists:get_value(<<"name">>, PostVals),
    Grade = proplists:get_value(<<"grade">>, PostVals),
    Price = proplists:get_value(<<"price">>, PostVals),

    Item = model_fish:new(Name, Grade, Price, User),
    case model_fish:save(Item) of
        {ok, _} ->
            {render, <<"admin_prices">>, [{user, User}, {fishes, model_fish:get_all()}]};
        {error, _} ->
            {render, <<"admin_prices">>, [
                {user, User}, 
                {error, << <<"Item '">>/binary, Name/binary, <<"' already exists!">>/binary >>}, 
                {fishes, model_fish:get_all()}]}
    end;

handle_request(<<"GET">>, <<"prices">>, [<<"edit">>, Id], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_prices">>, [{user, User}, 
                      {fish, model_fish:get(Id)}, 
                      {fishes, model_fish:get_all()}]};

handle_request(<<"POST">>, <<"prices">>, [<<"edit">>], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    Id = proplists:get_value(<<"_id">>, PostVals),
    Name = proplists:get_value(<<"name">>, PostVals),
    Grade = proplists:get_value(<<"grade">>, PostVals),
    Price = proplists:get_value(<<"price">>, PostVals),

    model_fish:update(Id, Name, Grade, Price, User),
    {render, <<"admin_prices">>, [{user, User}, {fishes, model_fish:get_all()}]};

handle_request(<<"GET">>, <<"prices">>, [<<"delete">>, Id], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    model_fish:delete(Id),
    {render, <<"admin_prices">>, [{user, User}, {fishes, model_fish:get_all()}]};
    
handle_request(<<"GET">>, <<"users">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_users">>, [{user, User}, {users, model_user:get_all()}]};

handle_request(<<"POST">>, <<"users">>, [<<"add">>], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    Pass1 = proplists:get_value(<<"password1">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),    

    ?DEBUG("Pass1=~p, Pass2=~p~n", [Pass1, Pass2]),
    case Pass1 =/= Pass2 of
        true ->
            {render, <<"admin_users">>, [{user, User}, {error, <<"Passwords are not the same.">>}]};
        _ ->
            FullName = proplists:get_value(<<"fullname">>, PostVals),
            Username = proplists:get_value(<<"username">>, PostVals),
            Role = proplists:get_value(<<"role">>, PostVals),
            Email = proplists:get_value(<<"email">>, PostVals),
            Mobile = proplists:get_value(<<"mobile">>, PostVals),

            ?DEBUG("Creating a new user...", []),
            NewUser = model_user:new(Username, FullName, Role, Email, Mobile, Pass2, User),
            ?DEBUG("NewUser= ~p", [NewUser]),
            model_user:save(NewUser),

            {redirect, <<"/admin/users">>}
    end;

handle_request(_, _, _, _, _) ->
    {render, <<"error">>, [{error, <<"Method not implemented!">>}]}.









