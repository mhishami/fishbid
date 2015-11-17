-module (model_offer).
-include ("fishbid.hrl").

-import (model_fish, [to_float/1]).

-export ([from_vals/2]).
-export ([new/4]).
-export ([save/1]).
-export ([get_all/0]).
-export ([get_by_id/2]).
-export ([get_by_user/1]).
-export ([ensure_index/0]).

-spec from_vals(Vals::list(), Who::map()) -> map().
from_vals(Vals, Who) ->
    FishId = proplists:get_value(<<"fish_id">>, Vals),
    Weight = proplists:get_value(<<"weight">>, Vals),
    Price = proplists:get_value(<<"price">>, Vals),
    new(model_fish:get(FishId), Weight, Price, Who).

-spec new(Fish::map(), Weight::binary(), Price::binary(), Who::map()) -> map().
new(Fish, Weight, Price, Who) ->
    #{<<"_id">> => uuid:gen(),
      <<"seller">> => Who,
      <<"fish">> => Fish,
      <<"weight">> => to_float(Weight),
      <<"price">> => to_float(Price),
      <<"total">> => to_float(Weight) * to_float(Price),
      <<"status">> => <<"open">>,
      <<"created_at">> => erlang:timestamp(),
      <<"updated_at">> => erlang:timestamp()
    }.

-spec save(Offer::map()) -> {ok, any()}.
save(Offer) ->
    mongo_worker:save(?DB_OFFERS, Offer).

-spec get_all() -> list().
get_all() ->
    {ok, Offers} = mongo_worker:find(?DB_OFFERS, {<<"status">>, {<<"$eq">>, <<"open">>}}),
    F = fun(T) ->
            CA = maps:get(<<"created_at">>, T),
            T#{<<"created_at">> => calendar:now_to_local_time(CA)}
        end,
    lists:map(F, Offers).

-spec get_by_id(OfferId::binary(), Sanitize::boolean()) -> list().
get_by_id(OfferId, Sanitize) ->
    {ok, Offer} = mongo_worker:find_one(?DB_OFFERS, {<<"_id">>, OfferId}),
    %% change the date format
    case Sanitize of
      true ->
        CA = maps:get(<<"created_at">>, Offer),
        Offer#{<<"created_at">> => calendar:now_to_local_time(CA)};
      _ ->
        Offer
    end.

-spec get_by_user(UserId::binary()) -> list().
get_by_user(UserId) ->
    {ok, Offers} = mongo_worker:find(?DB_OFFERS, {<<"seller._id">>, {<<"$eq">>, UserId}}),
    %% change the date format
    F = fun(T) ->
            CA = maps:get(<<"created_at">>, T),
            OfferId = maps:get(<<"_id">>, T),

            %% inject the highest bid data in the map
            T#{<<"created_at">> => calendar:now_to_local_time(CA),
               <<"highest_bid">> => model_bid:find_highest_bid_price(OfferId)
            }
        end,
    lists:map(F, Offers).

-spec ensure_index() -> any().
ensure_index() ->
    mongo_worker:ensure_index(?DB_OFFERS, #{<<"key">> => #{<<"seller">> => 1}}),
    mongo_worker:ensure_index(?DB_OFFERS, #{<<"key">> => #{<<"fish">> => 1}}),
    mongo_worker:ensure_index(?DB_OFFERS, #{<<"key">> => #{<<"status">> => 1}}),
    ok.
