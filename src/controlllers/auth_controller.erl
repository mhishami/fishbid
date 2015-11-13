-module (auth_controller).
-behaviour (tuah_controller).

-export ([handle_request/5]).
-export ([before_filter/1]).

-include("fishbid.hrl").

before_filter(_SessionId) ->
    {ok, proceed}.

handle_request(<<"GET">>, <<"logout">>, _Args, Params, _Req) ->
    session_worker:del_cookies(maps:get(<<"sid">>, Params)),
    {redirect, <<"/">>};

handle_request(<<"GET">>, <<"login">> = Action, _Args, _Params, _Req) ->
    {render, Action, []};  

handle_request(<<"POST">>, <<"login">> = Action, _Args, Params, _Req) ->    
    PostVals = maps:get(<<"qs_body">>, Params),
    Username = proplists:get_value(<<"username">>, PostVals),
    Password = proplists:get_value(<<"password">>, PostVals),

    case Username =:= <<>> orelse Password =:= <<>> of
        true ->
            {render, Action, [{error, <<"All fields are required.">>}]};
        _ ->
            case model_user:authenticate(Username, Password) of
                error ->
                    {render, Action, [{error, <<"Invalid username, or password">>}]};
                {ok, User} ->
                    Sid = maps:get(<<"sid">>, Params),
                    session_worker:set_cookies(Sid, #{
                            <<"username">> => maps:get(<<"username">>, User),
                            <<"role">> => maps:get(<<"role">>, User)
                        }),

                    %% redirect, assuming "main" is defined.
                    {redirect, <<"/">>, {cookie, <<"auth">>, Username}}
            end
    end;

handle_request(<<"GET">>, <<"register">> = Action, _Args, _Params, _Req) -> 
    {render, Action, []};

handle_request(<<"POST">>, <<"register">> = Action, _Args, Params, _Req) ->
    PostVals = maps:get(<<"qs_body">>, Params),
    Username = proplists:get_value(<<"username">>, PostVals),
    Fullname = proplists:get_value(<<"fullname">>, PostVals),
    Email = proplists:get_value(<<"email">>, PostVals),
    Mobile = proplists:get_value(<<"mobile">>, PostVals),
    Pass1 = proplists:get_value(<<"password1">>, PostVals),
    Pass2 = proplists:get_value(<<"password2">>, PostVals),
    Role = proplists:get_value(<<"role">>, PostVals),

    case Pass1 =/= Pass2 of
        true ->
            {render, Action, [{reg_error, <<"Passwords are not the same">>} | PostVals]};
        _ ->
            %% ok, we can register
            User = model_user:new(Username, Fullname, Role, Email, Mobile, Pass1, 
                #{<<"username">> => <<"admin">>, <<"page">> => <<"register">>}),
            case model_user:save(User) of
                {ok, _} ->
                    %% ok, user is not duplicates and all
                    UserId = maps:get(<<"_id">>, User),
                    {Debit, Credit} = {0.0, 0.0},
                    Trx = model_trx:new(UserId, Debit, Credit, <<"done">>),
                    model_trx:save(Trx),
                    {redirect, <<"/auth/login">>};
                _ ->
                    %% we got duplicates
                    {render, Action, [{error, <<"Username/Email has been taken">>}]}
            end
    end;

handle_request(<<"GET">>, <<"reset_pwd">> = Action, _Args, _Params, _Req) ->
    {render, Action, []};

handle_request(<<"POST">>, <<"reset_pwd">> = Action, _Args, Params, _Req) ->
    PostVals = maps:get(<<"qs_body">>, Params),
    Email = proplists:get_value(<<"email">>, PostVals),
    case Email =:= <<>> of
        true ->
            {render, Action, [{error, <<"Email address is required">>}]};
        _ ->
            model_user:reset_password(Email),
            {render, Action, [{error, <<"Please check your email for a password reset">>}]}
    end.
