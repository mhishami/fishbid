-module (model_fish).
-include ("fishbid.hrl").

-export ([new/4]).
-export ([save/1]).
-export ([get_all/0]).
-export ([ensure_index/0]).

-spec new(binary(), binary(), binary(), binary()) -> map().
new(Name, Grade, Price, User) when is_binary(Name),
                                   is_binary(Grade),
                                   is_binary(Price) ->
    #{<<"name">> => Name,
      <<"grade">> => Grade,
      <<"price">> => price(Price),
      <<"created_at">> => erlang:timestamp(),
      <<"updated_at">> => erlang:timestamp(),
      <<"added_by">> => User}.

-spec save(map()) -> {ok, any()}.
save(Fish) when is_map(Fish) ->
    mongo_worker:save(?DB_FISHES, Fish).

-spec get_all() -> list().
get_all() ->
    {ok, Fishes} = mongo_worker:match(?DB_FISHES, {}, {<<"grade">>, 1}),
    Fishes.

-spec ensure_index() -> {ok, any()}.
ensure_index() ->
    mongo_worker:ensure_index(?DB_FISHES, #{<<"key">> => #{<<"price">> => 1}}),
    mongo_worker:ensure_index(?DB_FISHES, #{<<"key">> => #{<<"grade">> => 1}}),
    mongo_worker:ensure_index(?DB_FISHES, #{<<"key">> => #{<<"name">> => 1},
                                            <<"unique">> => true,
                                            <<"dropDups">> => true}),
    mongo_worker:ensure_index(?DB_FISHES, #{<<"key">> => #{<<"name">> => 1, 
                                                           <<"grade">> => 1},
                                            <<"unique">> => true,
                                            <<"dropDups">> => true}).

price(Price) when is_binary(Price) ->
    binary_to_float(<< Price/binary, <<".0">>/binary >>); 
price(Price) when is_float(Price) ->
    Price.
