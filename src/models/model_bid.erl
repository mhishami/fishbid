-module (model_bid).

-include ("fishbid.hrl").
-import (model_fish, [to_float/1]).

-export ([from_vals/2]).
-export ([new/3]).
-export ([save/1]).
-export ([update/1]).
-export ([get_all/1]).
-export ([get_by_user/2]).
-export ([get_counts_by_offer/1]).
-export ([get_by_offer/2]).
-export ([get_by_id/1]).
-export ([find_highest_bid_price/1]).
-export ([ensure_index/0]).
-export ([sanitize/1]).

-spec from_vals(Params::list(), Who::map()) -> map().
from_vals(Params, Who) ->
    OfferId = proplists:get_value(<<"offer_id">>, Params),
    UserId = maps:get(<<"_id">>, Who),

    B = proplists:get_value(<<"bid_price">>, Params),
    BidPrice = sanitize(B),
    %% see if the user has bid before, and MUST be higher value this time.
    case find_by_user(UserId, OfferId) of
        [] ->
            %% just save the bid
            new(OfferId, BidPrice, Who);
        Bids ->
            case check_bids(BidPrice, Bids) of
                ok ->
                    %% proceed
                    new(OfferId, BidPrice, Who);
                _ ->
                    %% we should return error instead.
                    {error, OfferId}
            end
    end.

-spec new(OfferId::binary(), BidPrice::float(), Who::map()) -> map().
new(OfferId, BidPrice, Who) ->
    CommFees = BidPrice * 0.04,
    SumTotal = BidPrice + CommFees,
    #{<<"_id">> => uuid:gen(),
      <<"offer">> => model_offer:get_by_id(OfferId, false),
      <<"bidder">> => Who,
      <<"comm_fees">> => CommFees,
      <<"bid_price">> => BidPrice,
      <<"sum_total">> => SumTotal,
      <<"status">> => <<"pending">>,
      <<"created_at">> => erlang:timestamp(),
      <<"updated_at">> => erlang:timestamp()
      }.

-spec save(Bid::map()) -> {ok, any()}.
save(Bid) when is_map(Bid) ->
    mongo_worker:save(?DB_BIDS, Bid).

-spec update(Bid::map()) -> {ok, any()}.
update(Bid) ->
    mongo_worker:update(?DB_BIDS, Bid).

-spec get_all(Sanitize::boolean()) -> list().
get_all(Sanitize) ->
    {ok, Bids} = mongo_worker:match(?DB_BIDS, {}, {<<"sum_total">>, 1}),
    transform(Bids, Sanitize).

-spec get_by_user(UserId::binary(), Sanitize::boolean()) -> list().
get_by_user(UserId, Sanitize) ->
    {ok, Bids} = mongo_worker:match(?DB_BIDS, {<<"bidder._id">>, {<<"$eq">>, UserId}}, {<<"sum_total">>, 1}),
    transform(Bids, Sanitize).

-spec get_counts_by_offer(OfferId::binary()) -> integer().
get_counts_by_offer(OfferId) ->
    {ok, Count} = mongo_worker:count(?DB_BIDS, {<<"offer._id">>, {<<"$eq">>, OfferId}}),
    Count.

-spec get_by_offer(OfferId::binary(), Sanitize::boolean()) -> list().
get_by_offer(OfferId, Sanitize) ->
    {ok, Bids} = mongo_worker:match(?DB_BIDS, {<<"offer._id">>, {<<"$eq">>, OfferId}}, {<<"bid_price">>, -1}),
    transform(Bids, Sanitize).

-spec get_by_id(BidId::binary()) -> map().
get_by_id(BidId) ->
    {ok, Bid} = mongo_worker:find_one(?DB_BIDS, {<<"_id">>, BidId}),
    Bid.

find_by_user(UserId, OfferId) ->
    {ok, Bids} = mongo_worker:find(?DB_BIDS, {<<"bidder._id">>, {<<"$eq">>, UserId},
                                              <<"offer._id">>, {<<"$eq">>, OfferId}}),
    Bids.

-spec find_highest_bid_price(OfferId::binary()) -> float().
find_highest_bid_price(OfferId) ->
    {ok, Bids} = mongo_worker:match(?DB_BIDS, {<<"offer._id">>, {<<"$eq">>, OfferId}}, {<<"bid_price">>, -1}),
    case Bids of
        [] -> 
            0.0;
        List ->
            %% get the first one
            maps:get(<<"bid_price">>, hd(List))
    end.

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

-spec transform(List::list(), Sanitize::boolean()) -> list().
transform(List, Sanitize) ->
    case Sanitize of
        true ->
            F = fun(T) ->
                    CA = maps:get(<<"created_at">>, T),
                    T#{<<"created_at">> => calendar:now_to_local_time(CA)}
                end,
            lists:map(F, List);
        _ ->
            List
    end.

-spec check_bids(BidPrice::float(), Bids::list()) -> ok | error.
check_bids(BidPrice, [H|T]) ->
    case BidPrice > maps:get(<<"bid_price">>, H) of
        true ->
            check_bids(BidPrice, T);
        false ->
            error 
    end;
check_bids(_BidPrice, []) -> ok.

