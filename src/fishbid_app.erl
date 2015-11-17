-module(fishbid_app).
-behaviour(application).

-export([start/2]).
-export([stop/1]).
-export ([init/0]).

start(_Type, _Args) ->
    application:start(sync),
    application:ensure_all_started(lager),
    application:ensure_all_started(mongodb),    
    application:ensure_all_started(cowboy),
    application:start(erlydtl),

    %% set debug for console logs
    lager:set_loglevel(lager_console_backend, debug),

    fishbid_sup:start_link().

stop(_State) ->
    ok.

%% ======================================================================================
%% Initialization
%% ======================================================================================
-spec init() -> any().
init() ->
    User = model_user:new(<<"hisham">>, 
               <<"Hisham Ismail">>, 
               <<"admin">>, 
               <<"mhishami@gmail.com">>, 
               <<"0196622165">>,
               <<"sa">>,
               <<"">>),
    UserId = maps:get(<<"_id">>, User),
    Who = #{<<"_id">> => UserId, 
            <<"username">> => <<"hisham">>, 
            <<"role">> => <<"admin">>},
    model_user:save(User#{<<"created_by">> => Who}),
    model_trx:init(UserId),

    %% init the index
    model_fish:ensure_index(),
    model_offer:ensure_index(),
    model_user:ensure_index(),
    model_trx:ensure_index(),
    model_bid:ensure_index(),

    %% add the fishes
    model_fish:save(model_fish:new(<<"Kerapu">>, <<"A">>, <<"30">>, Who)),
    model_fish:save(model_fish:new(<<"Tenggiri">>, <<"A">>, <<"25">>, Who)),
    model_fish:save(model_fish:new(<<"Udang Harimau">>, <<"B">>, <<"70">>, Who)),
    model_fish:save(model_fish:new(<<"Sotong">>, <<"B">>, <<"40">>, Who)),
    model_fish:save(model_fish:new(<<"Pari">>, <<"B">>, <<"20">>, Who)),
    model_fish:save(model_fish:new(<<"Kembong">>, <<"C">>, <<"8">>, Who)),
    model_fish:save(model_fish:new(<<"Selayang">>, <<"C">>, <<"7">>, Who)),
    model_fish:save(model_fish:new(<<"Pelaling">>, <<"C">>, <<"7">>, Who)),
    model_fish:save(model_fish:new(<<"Selar">>, <<"C">>, <<"7">>, Who)),
    model_fish:save(model_fish:new(<<"Cencaru">>, <<"C">>, <<"7">>, Who)),

    ok.