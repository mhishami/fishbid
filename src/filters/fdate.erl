-module (fdate).
-behaviour(erlydtl_library).

-export([version/0, inventory/1, fdate/1]).

%% dummy behaviour for lib_test2
-export([behaviour_info/1]).
behaviour_info(callbacks) -> [].
%% end behaviour


version() -> 1.

inventory(filters) -> [fdate];
inventory(tags) -> [].

fdate(_Data) ->
    "November 16, 2015".
