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

handle_request(<<"GET">>, <<"edit">>, [UserId], Params, _Req) ->
    User = maps:get(<<"auth">>, Params),
    Person = model_user:get_by_id(UserId),
    {render, <<"user_edit">>, [{user, User}, {person, Person}]};

handle_request(<<"POST">>, <<"update">>, _Args, Params, _Req) ->
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
                    {render, <<"user_edit">>, [
                        {user, User}, {person, Person},
                        {error, <<"Passwords are not the same">>}
                    ]}
            end;
        _ ->
            %% just update the user
            model_user:update(Updated, User),
            {redirect, <<"/admin/users">>}
    end;

handle_request(_Method, _Action, _Args, _Params, _Req) ->
    {render, <<"error">>, [{error, <<"Method not implemented">>}]}.
