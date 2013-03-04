%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc HINT app. Use hint:start().
%%% @copyright 2013 HINT
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%_* Module declaration =======================================================
%% @private
-module(hint_app).
-behaviour(application).

%%%_* Exports ==================================================================
-export([ start/2
        , stop/1
        ]).

%%%_* API ======================================================================
start(_Type, _Args) ->
  Dispatch = cowboy_router:compile([
    {'_', [ {"/", frontpage_handler, []}
          , {"/search", search_handler, []}
          , { "/assets/[...]", cowboy_static
            , [ {directory, {priv_dir, hint, [<<"assets">>]}}
              , {mimetypes, {fun mimetypes:path_to_mimes/2, default}}
              ]
            }
          ]
    }
  ]),
  {ok, _} = cowboy:start_http(http, 100, [{port, 8080}], [
    {env, [{dispatch, Dispatch}]}
  ]),
  hint_sup:start_link().

stop(_State) ->
  ok.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
