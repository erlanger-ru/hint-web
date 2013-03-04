%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc Various utils
%%% @copyright 2013 HINT
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%_* Module declaration =======================================================
-module(hint_util).

%%%_* Exports ==================================================================
-export([ is_xhr/1
        ]).

%%
%% @doc Retuns true if the request was made via Ajax (XHR, xmlhttprequest)
%%
-spec is_xhr(cowboy_req:req()) -> boolean().
is_xhr(Req) ->
  case cowboy_req:header(<<"xmlhttprequest">>, Req) of
    {undefined, _} -> false;
    {_, _}         -> true
  end.
%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
