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

%% ======================================================================================
%% Offers Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"offers">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    Fishes = model_fish:get_for_select(),
    Offers = model_offer:get_by_user(maps:get(<<"_id">>, User)),

    %% get the highest bidder for each offer
    
    {render, <<"user_offers">>, [{user, User}, {fishes, Fishes}, {offers, Offers}]};

handle_request(<<"POST">>, <<"offers">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),

    Offer = model_offer:from_vals(PostVals, User),
    model_offer:save(Offer),

    {redirect, <<"/user/offers">>};

%% ======================================================================================
%% Bids Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"bids">>, [OfferId], Params, _Req) ->
    ?DEBUG("OfferId= ~p", [OfferId]),
    User = maps:get(<<"auth">>, Params),
    Offer = model_offer:get_by_id(OfferId, true),
    {render, <<"user_bids">>, [{user, User}, {offer, Offer}, 
        {max, maps:get(<<"total">>, Offer) * 2.0},
        {min, maps:get(<<"total">>, Offer) * 0.90}
    ]};

handle_request(<<"POST">>, <<"bids">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    case model_bid:from_vals(PostVals, User) of 
        {error, OfferId} ->
            %% okay, user bids with lower value this time
            Offer = model_offer:get_by_id(OfferId, true),
            {render, <<"user_bids">>, [{user, User}, {offer, Offer}, 
                {max, maps:get(<<"total">>, Offer) * 2.0},
                {min, maps:get(<<"total">>, Offer) * 0.90},
                {error, <<"Bid Rejected. You have bid with higher bid value before">>}
            ]};
        Bid ->
            model_bid:save(Bid),
            {redirect, <<"/user/bids">>}
    end;

handle_request(<<"GET">>, <<"bids">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    ?DEBUG("User= ~p", [User]),
    Bids = model_bid:get_by_user(maps:get(<<"_id">>, User), true),
    {render, <<"user_bids_list">>, [{user, User}, {bids, Bids}]};

%% ======================================================================================
%% Profile Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"edit">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    Person = model_user:get_by_id(maps:get(<<"_id">>, User)),
    {render, <<"user_edit">>, [{user, User}, {person, Person}]};

handle_request(<<"POST">>, <<"profile">>, [<<"update">>], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    ?DEBUG("Params= ~p~n", [Params]),

    %% get all params
    Updated = #{<<"_id">> => proplists:get_value(<<"_id">>, PostVals),
                <<"username">> => proplists:get_value(<<"username">>, PostVals),
                <<"fullname">> => proplists:get_value(<<"fullname">>, PostVals),
                <<"about">> => proplists:get_value(<<"about">>, PostVals),
                <<"role">> => proplists:get_value(<<"role">>, PostVals),
                <<"email">> => proplists:get_value(<<"email">>, PostVals),
                <<"mobile">> => proplists:get_value(<<"mobile">>, PostVals)},

    %% check if user is changing password
    Pass1 = proplists:get_value(<<"password1">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),

    case Pass1 =/= <<>> orelse Pass2 =/= <<>> of
        true ->
            case Pass1 =/= Pass2 of
                true ->
                    %% ok, can change password
                    U2 = Updated#{ <<"password">> => web_util:hash_password(Pass1) },
                    ?DEBUG("Updating user model...", []),
                    model_user:update(U2, User),
                    {redirect, <<"/">>};
                _ ->
                    Person = model_user:get_by_id(proplists:get_value(<<"_id">>, PostVals)),
                    {render, <<"user_edit">>, [
                        {user, User}, {person, Person},
                        {error, <<"Passwords are not the same">>}
                    ]}
            end;
        _ ->
            %% just update the user
            model_user:update(Updated, User),
            {redirect, <<"/">>}
    end;

%% ======================================================================================
%% Catch All Handling
%% ======================================================================================
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
