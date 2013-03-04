%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc Display the front page
%%% @copyright 2013 HINT
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%_* Module declaration =======================================================
-module(frontpage_handler).

%%%_* Exports ==================================================================
%% REST callbacks
-export([ init/3
        , content_types_provided/2
        ]).

%% Specifics
-export([ allowed_methods/2
        , to_html/2]).

init(_Transport, _Req, []) ->
  {upgrade, protocol, cowboy_rest}.

allowed_methods(Req, State) ->
  {[<<"GET">>], Req, State}.

content_types_provided(Req, State) ->
  {[
    {<<"text/html">>, to_html}
  ], Req, State}.

to_html(Req, State) ->
  Data = retrieve_data(Req, State),
  {ok, Body} = hint_render:render("frontpage", Data, Req),
  {Body, Req, State}.

%%%_* Internal =================================================================

retrieve_data(Req, _State) ->
  case cowboy_req:qs_val(<<"q">>, Req) of
    {undefined, _Req2} ->
      [];
    {String, _Req2} ->
      [{req, String}]
  end.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
