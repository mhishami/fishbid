

-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

-define(DEBUG(Text, Args), lager:log(debug, ?MODULE, "~p:~p: " ++ Text, [?MODULE, ?LINE | Args])).
-define(INFO(Text, Args), lager:log(info, ?MODULE, "~p:~p: " ++ Text, [?MODULE, ?LINE | Args])).
-define(ERROR(Text, Args), lager:log(error, ?MODULE, "~p:~p: " ++ Text, [?MODULE, ?LINE | Args])).

-define(DB_USERS, <<"users">>).
-define(DB_FISHES, <<"fishes">>).
-define(DB_OFFERS, <<"offers">>).
-define(DB_BIDS, <<"bids">>).
-define(DB_TRXS, <<"transactions">>).
-define(DB_INVOICES, <<"invoices">>).
-define(DB_SETTINGS, <<"settings">>).



