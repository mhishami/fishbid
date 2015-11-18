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
    {render, <<"home">>, [
        {user, User},
        {bids, model_bid:get_all(true)},
        {success, model_bid:get_successful_bids()}

    ]};

handle_request(<<"GET">>, <<"base">>, _Args, Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"base">>, [{user, User}]};

handle_request(<<"GET">>, <<"prices">>, _Args, Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"home_prices">>, [{user, User} | model_fish:get_by_grades()]};

handle_request(<<"GET">>, <<"offers">>, _Args, Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"home_offers">>, [{user, User}, {offers, model_offer:get_all_sans_mine(User)}]};

handle_request(Method, Action, Args, Params, Req) ->
    {render, <<"error">>, [
        {error, <<"Method not implemented">>},
        {details, [
            {method, Method}, 
            {action, Action}, 
            {args, Args}, 
            {params, jsx:prettify(jsx:encode(Params))},
            {req, Req}]}
    ]}.
