-module (model_fish).
-include ("fishbid.hrl").

-export ([new/4]).
-export ([save/1]).
-export ([get_all/0]).
-export ([get/1]).
-export ([get_by_grades/0]).
-export ([get_for_select/0]).
-export ([update/5]).
-export ([delete/1]).
-export ([ensure_index/0]).
-export ([to_float/1]).

-spec new(Name::binary(), Grade::binary(), Price::binary(), Who::map()) -> map().
new(Name, Grade, Price, Who) when is_binary(Name),
                                   is_binary(Grade),
                                   is_binary(Price),
                                   is_map(Who) ->
    #{<<"_id">> => uuid:gen(),
      <<"name">> => Name,
      <<"grade">> => Grade,
      <<"price">> => to_float(Price),
      <<"created_at">> => erlang:timestamp(),
      <<"updated_at">> => erlang:timestamp(),
      <<"added_by">> => Who}.

-spec save(Fish::map()) -> {ok, any()}.
save(Fish) when is_map(Fish) ->
    mongo_worker:save(?DB_FISHES, Fish).

-spec get_all() -> list().
get_all() ->
    {ok, Fishes} = mongo_worker:match(?DB_FISHES, {}, {<<"grade">>, 1}),
    Fishes.

get_for_select() ->
    {ok, Fishes} = mongo_worker:match(?DB_FISHES, {}, {<<"name">>, 1}), 
    Fishes.

-spec get(Id::binary()) -> map().
get(Id) ->
    {ok, Fish} = mongo_worker:find_one(?DB_FISHES, {<<"_id">>, Id}, 
        [{projector, {<<"name">>, 1, <<"grade">>, 1, <<"price">>, 1}}]),
    Fish.

get_by_grades() ->
    {ok, A} = mongo_worker:match(?DB_FISHES, {<<"grade">>, <<"A">>}, {<<"name">>, 1}),
    {ok, B} = mongo_worker:match(?DB_FISHES, {<<"grade">>, <<"B">>}, {<<"name">>, 1}),
    {ok, C} = mongo_worker:match(?DB_FISHES, {<<"grade">>, <<"C">>}, {<<"name">>, 1}),
    [{grade_a, A}, {grade_b, B}, {grade_c, C}].

-spec update(Id::binary(), Name::binary(), Grade::binary(), Price::binary(), Who::map()) -> {ok, any()}.
update(Id, Name, Grade, Price, Who) when is_binary(Id),
                                         is_binary(Name),
                                         is_binary(Grade),
                                         is_binary(Price),
                                         is_map(Who) ->
    Fish = #{<<"_id">> => Id,
             <<"name">> => Name,
             <<"grade">> => Grade,
             <<"price">> => to_float(Price),
             <<"updated_at">> => erlang:timestamp(),
             <<"updated_by">> => Who},
    mongo_worker:update(?DB_FISHES, Fish).

-spec delete(Id::binary()) -> {ok, any()}.
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
                                            <<"dropDups">> => true}),
    ok.

-spec to_float(Val::any()) -> float().
to_float(Val) when is_binary(Val) ->
    Comp = binary:split(Val, <<".">>),
    case length(Comp) of
        1 ->
            binary_to_float(<< Val/binary, <<".0">>/binary >>);
        2 ->
            binary_to_float(Val)
    end;

to_float(Val) when is_float(Val) ->
    Val.
