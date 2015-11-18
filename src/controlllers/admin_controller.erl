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
        {ok, User} ->
            case maps:get(<<"role">>, User) of
                <<"admin">> ->
                    {ok, proceed};
                _ ->
                    {redirect, <<"/">>}
            end
    end.

%% ======================================================================================
%% Price Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"prices">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_price_list">>, [{user, User}, {fishes, model_fish:get_all()}]};

handle_request(<<"POST">>, <<"prices">>, [<<"add">>], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    Name = proplists:get_value(<<"name">>, PostVals),
    Grade = proplists:get_value(<<"grade">>, PostVals),
    Price = proplists:get_value(<<"price">>, PostVals),

    Item = model_fish:new(Name, Grade, Price, User),
    case model_fish:save(Item) of
        {ok, _} ->
            {render, <<"admin_price_list">>, [{user, User}, {fishes, model_fish:get_all()}]};
        {error, _} ->
            {render, <<"admin_price_list">>, [
                {user, User}, 
                {error, << <<"Item '">>/binary, Name/binary, <<"' already exists!">>/binary >>}, 
                {fishes, model_fish:get_all()}]}
    end;

handle_request(<<"GET">>, <<"prices">>, [<<"edit">>, Id], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_price_list">>, [{user, User}, 
                      {fish, model_fish:get(Id)}, 
                      {fishes, model_fish:get_all()}]};

handle_request(<<"POST">>, <<"prices">>, [<<"update">>], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    
    Id = proplists:get_value(<<"_id">>, PostVals),
    Name = proplists:get_value(<<"name">>, PostVals),
    Grade = proplists:get_value(<<"grade">>, PostVals),
    Price = proplists:get_value(<<"price">>, PostVals),

    ?DEBUG("Updating fish prices...", []),
    model_fish:update(Id, Name, Grade, Price, User),
    {redirect, <<"/admin/prices">>};

handle_request(<<"GET">>, <<"prices">>, [<<"delete">>, Id], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    model_fish:delete(Id),
    {render, <<"admin_price_list">>, [{user, User}, {fishes, model_fish:get_all()}]};
    
%% ======================================================================================
%% User Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"users">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_user_list">>, [{user, User}, {users, model_user:get_all()}]};

handle_request(<<"POST">>, <<"users">>, [<<"add">>], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    PostVals = maps:get(<<"qs_body">>, Params),
    Pass1 = proplists:get_value(<<"password1">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),    

    ?DEBUG("Pass1=~p, Pass2=~p~n", [Pass1, Pass2]),
    case Pass1 =/= Pass2 of
        true ->
            {render, <<"admin_user_list">>, [{user, User}, {error, <<"Passwords are not the same.">>}]};
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
            UserId = maps:get(<<"_id">>, NewUser),
            model_trx:init(UserId),

            {redirect, <<"/admin/users">>}
    end;

handle_request(<<"GET">>, <<"users">>, [<<"edit">>, UserId], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    Person = model_user:get_by_id(UserId),
    ?DEBUG("Person= ~p", [Person]),
    {render, <<"admin_user_edit">>, [{user, User}, {person, Person}]};

handle_request(<<"GET">>, <<"users">>, [<<"remove">>, UserId], Params, _Req) ->
    ?INFO("Removing user ~p", [UserId]),
    User = maps:get(<<"auth">>, Params),
    model_user:deactivate(UserId, User),
    {render, <<"admin_user_list">>, [{user, User}, {users, model_user:get_all()}]};

handle_request(<<"POST">>, <<"users">>, [<<"update">>], Params, _Req) ->
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
                    {redirect, <<"/admin/users">>};
                _ ->
                    Person = model_user:get_by_id(proplists:get_value(<<"_id">>, PostVals)),
                    {render, <<"admin_user_edit">>, [
                        {user, User}, {person, Person},
                        {error, <<"Passwords are not the same">>}
                    ]}
            end;
        _ ->
            %% just update the user
            model_user:update(Updated, User),
            {redirect, <<"/admin/users">>}
    end;
%% ======================================================================================
%% Offers Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"offers">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_offers_list">>, [{user, User}, {offers, model_offer:get_all_with_bids_count()}]};

handle_request(<<"GET">>, <<"offers">>, [OfferId], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_bids_list">>, [{user, User}, 
        {offer, model_offer:get_by_id(OfferId, true)},
        {bids, model_bid:get_by_offer(OfferId, true)}]};

%% ======================================================================================
%% Bids Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"bids">>, [BidId], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    Winner = model_bid:get_by_id(BidId),
    ?DEBUG("Winner= ~p", [Winner]),
    Offer = maps:get(<<"offer">>, Winner),
    ?DEBUG("Offer= ~p", [Offer]),

    %% update the current BidId as winner, and the rest as failed
    Bids = model_bid:get_by_offer(maps:get(<<"_id">>, Offer), false),
    F = fun(B) ->
            case BidId =:= maps:get(<<"_id">>, B) of
                true ->
                    %% mark as winner
                    model_bid:update(B#{
                        <<"status">> => <<"successful">>,
                        <<"updated_at">> => erlang:timestamp(),
                        <<"updated_by">> => User
                    });
                false ->
                    %% marked as failed
                    model_bid:update(B#{
                        <<"status">> => <<"failed">>,
                        <<"updated_at">> => erlang:timestamp(),
                        <<"updated_by">> => User
                    })
            end
        end,
    lists:map(F, Bids),

    %% close the offer
    model_offer:update(Offer#{
        <<"status">> => <<"closed">>,
        <<"updated_at">> => erlang:timestamp(),
        <<"updated_by">> => User
    }),

    {redirect, <<"/admin/offers">>};

%% ======================================================================================
%% Dashboard Handling
%% ======================================================================================
handle_request(<<"GET">>, <<"dashboard">>, [], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    {render, <<"admin_dashboard">>, [
        {user, User},
        {fish_count, model_fish:get_count()},
        {sales_bid, model_bid:get_sales_for_bids()},
        {offers_completed, model_offer:get_all_completed_count()},
        {users_count, model_user:get_users_count()},
        {bids, model_bid:get_all(true)},
        {success, model_bid:get_successful_bids()}
    ]};


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








