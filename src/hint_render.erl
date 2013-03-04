%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% @doc Rendering utils
%%% @copyright 2013 HINT
%%% @end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%_* Module declaration =======================================================
-module(hint_render).

%%%_* Exports ==================================================================
-export([ render/3
        ]).

-spec render(string(), list(), cowboy_req:req()) -> iolist().
render(TemplateName, Variables, Req) ->
  {Path, Module} = template(TemplateName, Req),
  case erlydtl:compile(Path, Module) of
    ok -> Module:render(Variables, []);
    {error, _} = Err -> Err
  end.
%%%_* Internal =================================================================
template(TemplateName, Req) ->
  Sub = subdir(Req),
  Path = filename:join([ "priv" %code:priv_dir(hint)
                       , "templates"
                       , subdir(Req)
                       , TemplateName ++ ".dtl"
                       ]),
  Module = list_to_atom(lists:flatten([Sub, "_", TemplateName])),
  {Path, Module}.

subdir(Req) ->
  case hint_util:is_xhr(Req) of
    true  -> "xhr";
    false -> "html"
  end.

template_module(TemplateName) ->
  atom_to_list(TemplateName).
%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
