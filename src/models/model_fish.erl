-module (model_fish).
-include ("fishbid.hrl").

-export ([new/4]).
-export ([save/1]).
-export ([get_all/0]).
-export ([get/1]).
-export ([get_by_grades/0]).
-export ([update/5]).
-export ([delete/1]).
-export ([ensure_index/0]).
-export ([price/1]).

-spec new(binary(), binary(), binary(), binary()) -> map().
new(Name, Grade, Price, User) when is_binary(Name),
                                   is_binary(Grade),
                                   is_binary(Price) ->
    #{<<"_id">> => uuid:gen(),
      <<"name">> => Name,
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

-spec get(binary()) -> map().
get(Id) ->
    {ok, Fish} = mongo_worker:find_one(?DB_FISHES, {<<"_id">>, Id}),
    Fish.

get_by_grades() ->
    {ok, A} = mongo_worker:match(?DB_FISHES, {<<"grade">>, <<"A">>}, {<<"name">>, 1}),
    {ok, B} = mongo_worker:match(?DB_FISHES, {<<"grade">>, <<"B">>}, {<<"name">>, 1}),
    {ok, C} = mongo_worker:match(?DB_FISHES, {<<"grade">>, <<"C">>}, {<<"name">>, 1}),
    [{grade_a, A}, {grade_b, B}, {grade_c, C}].

-spec update(binary(), binary(), binary(), binary(), binary()) -> {ok, any()}.
update(Id, Name, Grade, Price, User) when is_binary(Id),
                                          is_binary(Name),
                                          is_binary(Grade),
                                          is_binary(Price),
                                          is_binary(User) ->
    Fish = #{<<"_id">> => Id,
             <<"name">> => Name,
             <<"grade">> => Grade,
             <<"price">> => price(Price),
             <<"updated_at">> => erlang:timestamp(),
             <<"updated_by">> => User},
    mongo_worker:update(?DB_FISHES, Fish).

-spec delete(binary()) -> {ok, any()}.
delete(Id) when is_binary(Id) ->
    mongo_worker:delete(?DB_FISHES, {<<"_id">>, Id}).

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

-spec price(any) -> float().
price(Price) when is_binary(Price) ->
    Comp = binary:split(Price, <<".">>),
    case length(Comp) of
        1 ->
            binary_to_float(<< Price/binary, <<".0">>/binary >>);
        2 ->
            binary_to_float(Price)
    end;

price(Price) when is_float(Price) ->
    Price.
