-module (user_controller).
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

handle_request(<<"GET">>, <<"offers">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    Fishes = model_fish:get_for_select(),
    Offers = model_offer:find_by_user(maps:get(<<"_id">>, User)),
    {render, <<"user_offers">>, [{user, User}, {fishes, Fishes}, {offers, Offers}]};

handle_request(<<"POST">>, <<"offers">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),

    Offer = model_offer:from_vals(PostVals, User),
    model_offer:save(Offer),

    {redirect, <<"/user/offers">>};

handle_request(<<"GET">>, <<"bids">>, OfferId, _Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    Offer = model_offer:get(OfferId),
    {redirect, <<"/user/offers">>};

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
