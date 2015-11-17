-module (model_bid).

-include ("fishbid.hrl").
-import (model_fish, [to_float/1]).

-export ([from_vals/2]).
-export ([new/4]).
-export ([save/1]).
-export ([ensure_index/0]).
-export ([sanitize/1]).

-spec from_vals(Params::list(), Who::map()) -> map().
from_vals(Params, Who) ->
    OfferId = proplists:get_value(<<"offer_id">>, Params),
    B = proplists:get_value(<<"bid_price">>, Params),
    C = proplists:get_value(<<"comm_fees">>, Params),
    BidPrice = sanitize(B),
    CommFees = sanitize(C),
    new(OfferId, BidPrice, CommFees, Who).

-spec new(OfferId::binary(), BidPrice::binary(), CommFees::binary(), Who::map()) -> map().
new(OfferId, BidPrice, CommFees, Who) ->
    #{<<"_id">> => uuid:gen(),
      <<"offer">> => model_offer:get_by_id(OfferId),
      <<"bidder">> => Who,
      <<"comm_fees">> => CommFees,
      <<"bid_price">> => BidPrice,
      <<"created_at">> => erlang:timestamp(),
      <<"updated_at">> => erlang:timestamp()
      }.

-spec save(Bid::map()) -> {ok, any()}.
save(Bid) when is_map(Bid) ->
    mongo_worker:save(?DB_BIDS, Bid).

-spec ensure_index() -> {ok, any()}.
ensure_index() ->
    mongo_worker:ensure_index(?DB_BIDS, #{<<"key">> => #{<<"offer">> => 1}}),
    mongo_worker:ensure_index(?DB_BIDS, #{<<"key">> => #{<<"bidder">> => 1}}),
    mongo_worker:ensure_index(?DB_BIDS, #{<<"key">> => #{<<"bid_price">> => 1}}),
    ok.

-spec sanitize(Val::binary()) -> float().
sanitize(Val) when is_binary(Val) ->
    S = re:split(Val, "[, ]"),
    sanitize(S, <<>>).

sanitize([H|T], Accu) ->
    case H of
        <<"RM">> ->
            sanitize(T, Accu);
        Rest ->
            sanitize(T, << Accu/binary, Rest/binary >>) 
    end;
sanitize([], Accu) -> to_float(Accu).
