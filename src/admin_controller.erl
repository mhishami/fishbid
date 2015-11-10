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

handle_request(<<"GET">>, <<"prices">> = Action, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, Action, [{user, User}, {fishes, model_fish:get_all()}]};

handle_request(<<"POST">>, <<"prices">> = Action, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    Name = proplists:get_value(<<"name">>, PostVals),
    Grade = proplists:get_value(<<"grade">>, PostVals),
    Price = proplists:get_value(<<"price">>, PostVals),

    Item = model_fish:new(Name, Grade, Price, User),
    case model_fish:save(Item) of
        {ok, _} ->
            {render, Action, [{user, User}, {fishes, model_fish:get_all()}]};
        {error, _} ->
            {render, Action, [
                {user, User}, 
                {error, << <<"Item '">>/binary, Name/binary, <<"' already exists!">>/binary >>}, 
                {fishes, model_fish:get_all()}]}
    end;

handle_request(<<"GET">>, <<"prices">> = Action, [<<"edit">>, Id], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, Action, [{user, User}, 
                      {fish, model_fish:get(Id)}, 
                      {fishes, model_fish:get_all()}]};

handle_request(<<"POST">>, <<"prices">> = Action, [<<"edit">>], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    Id = proplists:get_value(<<"_id">>, PostVals),
    Name = proplists:get_value(<<"name">>, PostVals),
    Grade = proplists:get_value(<<"grade">>, PostVals),
    Price = proplists:get_value(<<"price">>, PostVals),

    model_fish:update(Id, Name, Grade, Price, User),
    {render, Action, [{user, User}, {fishes, model_fish:get_all()}]};

handle_request(<<"GET">>, <<"prices">> = Action, [<<"delete">>, Id], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    model_fish:delete(Id),
    {render, Action, [{user, User}, {fishes, model_fish:get_all()}]}.
    








