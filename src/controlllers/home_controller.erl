-module (home_controller).
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

handle_request(<<"GET">>, <<"index">>, _Args, Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"home">>, [{user, User}]};

handle_request(<<"GET">>, <<"prices">>, _Args, Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"home_prices">>, [{user, User} | model_fish:get_by_grades()]}.



