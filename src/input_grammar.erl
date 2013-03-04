-module(input_grammar).
-export([parse/1,file/1]).
-compile(nowarn_unused_vars).
-compile({nowarn_unused_function,[p/4, p/5, p_eof/0, p_optional/1, p_not/1, p_assert/1, p_seq/1, p_and/1, p_choose/1, p_zero_or_more/1, p_one_or_more/1, p_label/2, p_string/1, p_anything/0, p_charclass/1, p_regexp/1, p_attempt/4, line/1, column/1]}).



-spec file(file:name()) -> any().
file(Filename) -> {ok, Bin} = file:read_file(Filename), parse(Bin).

-spec parse(binary() | list()) -> any().
parse(List) when is_list(List) -> parse(list_to_binary(List));
parse(Input) when is_binary(Input) ->
  setup_memo(),
  Result = case 'mfa'(Input,{{line,1},{column,1}}) of
             {AST, <<>>, _Index} -> AST;
             Any -> Any
           end,
  release_memo(), Result.

'mfa'(Input, Index) ->
  p(Input, Index, 'mfa', fun(I,D) -> (p_seq([p_optional(fun 'module'/2), p_optional(fun 'function'/2), p_optional(fun 'arglist'/2), p_optional(fun 'return'/2), p_optional(fun 'dot'/2)]))(I,D) end, fun(Node, Idx) -> transform('mfa', Node, Idx) end).

'module'(Input, Index) ->
  p(Input, Index, 'module', fun(I,D) -> (p_seq([p_optional(fun 'module_name'/2), p_string(<<":">>)]))(I,D) end, fun(Node, Idx) -> transform('module', Node, Idx) end).

'module_name'(Input, Index) ->
  p(Input, Index, 'module_name', fun(I,D) -> (fun 'mf_name'/2)(I,D) end, fun(Node, Idx) -> transform('module_name', Node, Idx) end).

'function'(Input, Index) ->
  p(Input, Index, 'function', fun(I,D) -> (fun 'mf_name'/2)(I,D) end, fun(Node, Idx) -> transform('function', Node, Idx) end).

'arglist'(Input, Index) ->
  p(Input, Index, 'arglist', fun(I,D) -> (p_seq([p_string(<<"(">>), fun 'ws'/2, p_optional(fun 'arguments'/2), fun 'ws'/2, p_string(<<")">>)]))(I,D) end, fun(Node, Idx) -> transform('arglist', Node, Idx) end).

'arguments'(Input, Index) ->
  p(Input, Index, 'arguments', fun(I,D) -> (p_seq([fun 'argument'/2, p_zero_or_more(p_seq([fun 'ws'/2, p_string(<<",">>), fun 'ws'/2, fun 'argument'/2]))]))(I,D) end, fun(Node, Idx) -> transform('arguments', Node, Idx) end).

'argument'(Input, Index) ->
  p(Input, Index, 'argument', fun(I,D) -> (p_seq([fun 'argument_var'/2, p_zero_or_more(p_seq([fun 'ws'/2, p_string(<<"|">>), fun 'ws'/2, fun 'argument_var'/2]))]))(I,D) end, fun(Node, Idx) -> transform('argument', Node, Idx) end).

'argument_var'(Input, Index) ->
  p(Input, Index, 'argument_var', fun(I,D) -> (p_choose([p_seq([p_optional(p_seq([fun 'variable'/2, p_string(<<"::">>)])), fun 'type'/2]), fun 'variable'/2]))(I,D) end, fun(Node, Idx) -> transform('argument_var', Node, Idx) end).

'return'(Input, Index) ->
  p(Input, Index, 'return', fun(I,D) -> (p_seq([fun 'ws'/2, p_string(<<"->">>), fun 'ws'/2, fun 'return_list'/2, p_optional(fun 'where'/2)]))(I,D) end, fun(Node, Idx) -> transform('return', Node, Idx) end).

'return_list'(Input, Index) ->
  p(Input, Index, 'return_list', fun(I,D) -> (p_seq([fun 'return_type'/2, p_zero_or_more(p_seq([fun 'ws'/2, p_string(<<"|">>), fun 'ws'/2, fun 'return_type'/2]))]))(I,D) end, fun(Node, Idx) -> transform('return_list', Node, Idx) end).

'return_type'(Input, Index) ->
  p(Input, Index, 'return_type', fun(I,D) -> (p_choose([fun 'type'/2, fun 'variable'/2]))(I,D) end, fun(Node, Idx) -> transform('return_type', Node, Idx) end).

'where'(Input, Index) ->
  p(Input, Index, 'where', fun(I,D) -> (p_seq([fun 'ws'/2, p_string(<<"where">>), fun 'ws'/2, fun 'where_arguments'/2]))(I,D) end, fun(Node, Idx) -> transform('where', Node, Idx) end).

'where_arguments'(Input, Index) ->
  p(Input, Index, 'where_arguments', fun(I,D) -> (p_seq([fun 'where_argument'/2, p_zero_or_more(p_seq([fun 'ws'/2, p_string(<<",">>), fun 'ws'/2, fun 'where_argument'/2]))]))(I,D) end, fun(Node, Idx) -> transform('where_arguments', Node, Idx) end).

'where_argument'(Input, Index) ->
  p(Input, Index, 'where_argument', fun(I,D) -> (p_seq([fun 'variable'/2, fun 'ws'/2, p_string(<<"::">>), fun 'ws'/2, fun 'return_list'/2]))(I,D) end, fun(Node, Idx) -> transform('where_argument', Node, Idx) end).

'mf_name'(Input, Index) ->
  p(Input, Index, 'mf_name', fun(I,D) -> (p_choose([p_seq([p_string(<<"_">>), p_optional(p_choose([fun 'valid_name'/2, p_string(<<"_">>)]))]), p_seq([fun 'atom'/2, p_optional(fun 'valid_name'/2)])]))(I,D) end, fun(Node, Idx) -> transform('mf_name', Node, Idx) end).

'valid_name'(Input, Index) ->
  p(Input, Index, 'valid_name', fun(I,D) -> (p_one_or_more(p_choose([fun 'atom'/2, fun 'numeric'/2])))(I,D) end, fun(Node, Idx) -> transform('valid_name', Node, Idx) end).

'variable'(Input, Index) ->
  p(Input, Index, 'variable', fun(I,D) -> (p_seq([fun 'uppercase'/2, p_zero_or_more(p_choose([fun 'uppercase'/2, fun 'valid_name'/2]))]))(I,D) end, fun(Node, Idx) -> transform('variable', Node, Idx) end).

'type'(Input, Index) ->
  p(Input, Index, 'type', fun(I,D) -> (p_choose([fun 'range'/2, fun 'fun_type'/2, fun 'simple_type'/2, fun 'nested_type'/2, fun 'atom'/2, fun 'number'/2, fun 'bit_string'/2]))(I,D) end, fun(Node, Idx) -> transform('type', Node, Idx) end).

'range'(Input, Index) ->
  p(Input, Index, 'range', fun(I,D) -> (p_seq([fun 'number'/2, p_string(<<"..">>), fun 'number'/2]))(I,D) end, fun(Node, Idx) -> transform('range', Node, Idx) end).

'fun_type'(Input, Index) ->
  p(Input, Index, 'fun_type', fun(I,D) -> (p_choose([p_string(<<"fun()">>), p_seq([p_string(<<"fun(">>), fun 'ws'/2, fun 'arglist'/2, fun 'ws'/2, p_string(<<"->">>), fun 'ws'/2, fun 'return_list'/2, p_string(<<")">>)])]))(I,D) end, fun(Node, Idx) -> transform('fun_type', Node, Idx) end).

'simple_type'(Input, Index) ->
  p(Input, Index, 'simple_type', fun(I,D) -> (p_seq([p_optional(p_seq([fun 'module_name'/2, p_string(<<":">>)])), fun 'atom'/2, p_string(<<"()">>)]))(I,D) end, fun(Node, Idx) -> transform('simple_type', Node, Idx) end).

'nested_type'(Input, Index) ->
  p(Input, Index, 'nested_type', fun(I,D) -> (p_choose([fun 'tuple'/2, fun 'list'/2]))(I,D) end, fun(Node, Idx) -> transform('nested_type', Node, Idx) end).

'tuple'(Input, Index) ->
  p(Input, Index, 'tuple', fun(I,D) -> (p_choose([p_seq([p_string(<<"{">>), fun 'ws'/2, p_optional(fun 'arguments'/2), fun 'ws'/2, p_string(<<"}">>)]), p_seq([p_string(<<"tuple(">>), fun 'ws'/2, p_optional(fun 'arguments'/2), fun 'ws'/2, p_string(<<")">>)])]))(I,D) end, fun(Node, Idx) -> transform('tuple', Node, Idx) end).

'list'(Input, Index) ->
  p(Input, Index, 'list', fun(I,D) -> (p_choose([p_seq([p_string(<<"[">>), fun 'ws'/2, p_optional(fun 'arguments'/2), fun 'ws'/2, p_string(<<"]">>)]), p_seq([p_string(<<"list(">>), fun 'ws'/2, p_optional(fun 'arguments'/2), fun 'ws'/2, p_string(<<")">>)]), fun 'other_list'/2]))(I,D) end, fun(Node, Idx) -> transform('list', Node, Idx) end).

'other_list'(Input, Index) ->
  p(Input, Index, 'other_list', fun(I,D) -> (p_choose([p_seq([p_string(<<"improper_list(">>), fun 'ws'/2, p_optional(fun 'arguments'/2), fun 'ws'/2, p_string(<<")">>)]), p_seq([p_string(<<"maybe_improper_list(">>), fun 'ws'/2, p_optional(fun 'arguments'/2), fun 'ws'/2, p_string(<<")">>)])]))(I,D) end, fun(Node, Idx) -> transform('other_list', Node, Idx) end).

'bit_string'(Input, Index) ->
  p(Input, Index, 'bit_string', fun(I,D) -> (p_choose([p_string(<<"<<>>">>), p_seq([p_string(<<"<<_:">>), p_one_or_more(fun 'numeric'/2), p_string(<<">>">>)]), p_seq([p_string(<<"<<_:_*">>), p_one_or_more(fun 'numeric'/2), p_string(<<">>">>)]), p_seq([p_string(<<"<<_:">>), p_one_or_more(fun 'numeric'/2), p_string(<<",">>), fun 'ws'/2, p_string(<<"_:_*">>), p_one_or_more(fun 'numeric'/2), p_string(<<">>">>)])]))(I,D) end, fun(Node, Idx) -> transform('bit_string', Node, Idx) end).

'atom'(Input, Index) ->
  p(Input, Index, 'atom', fun(I,D) -> (p_charclass(<<"[a-z]">>))(I,D) end, fun(Node, Idx) -> transform('atom', Node, Idx) end).

'uppercase'(Input, Index) ->
  p(Input, Index, 'uppercase', fun(I,D) -> (p_charclass(<<"[A-Z]">>))(I,D) end, fun(Node, Idx) -> transform('uppercase', Node, Idx) end).

'number'(Input, Index) ->
  p(Input, Index, 'number', fun(I,D) -> (p_choose([fun 'base'/2, p_seq([p_optional(p_string(<<"-">>)), p_one_or_more(fun 'numeric'/2)])]))(I,D) end, fun(Node, Idx) -> transform('number', Node, Idx) end).

'base'(Input, Index) ->
  p(Input, Index, 'base', fun(I,D) -> (p_seq([fun 'numeric'/2, p_optional(fun 'numeric'/2), p_string(<<"#">>), p_one_or_more(p_choose([fun 'numeric'/2, p_charclass(<<"[a-f]">>)]))]))(I,D) end, fun(Node, Idx) -> transform('base', Node, Idx) end).

'numeric'(Input, Index) ->
  p(Input, Index, 'numeric', fun(I,D) -> (p_charclass(<<"[0-9]">>))(I,D) end, fun(Node, Idx) -> transform('numeric', Node, Idx) end).

'ws'(Input, Index) ->
  p(Input, Index, 'ws', fun(I,D) -> (p_optional(p_charclass(<<"[\s\t]">>)))(I,D) end, fun(Node, Idx) -> transform('ws', Node, Idx) end).

'dot'(Input, Index) ->
  p(Input, Index, 'dot', fun(I,D) -> (p_string(<<".">>))(I,D) end, fun(Node, Idx) -> transform('dot', Node, Idx) end).


transform(Symbol,Node,Index) -> input_parser:transform(Symbol, Node, Index).

p(Inp, Index, Name, ParseFun) ->
  p(Inp, Index, Name, ParseFun, fun(N, _Idx) -> N end).

p(Inp, StartIndex, Name, ParseFun, TransformFun) ->
  case get_memo(StartIndex, Name) of      % See if the current reduction is memoized
    {ok, Memo} -> %Memo;                     % If it is, return the stored result
      Memo;
    _ ->                                        % If not, attempt to parse
      Result = case ParseFun(Inp, StartIndex) of
        {fail,_} = Failure ->                       % If it fails, memoize the failure
          Failure;
        {Match, InpRem, NewIndex} ->               % If it passes, transform and memoize the result.
          Transformed = TransformFun(Match, StartIndex),
          {Transformed, InpRem, NewIndex}
      end,
      memoize(StartIndex, Name, Result),
      Result
  end.

setup_memo() ->
  put({parse_memo_table, ?MODULE}, ets:new(?MODULE, [set])).

release_memo() ->
  ets:delete(memo_table_name()).

memoize(Index, Name, Result) ->
  Memo = case ets:lookup(memo_table_name(), Index) of
              [] -> [];
              [{Index, Plist}] -> Plist
         end,
  ets:insert(memo_table_name(), {Index, [{Name, Result}|Memo]}).

get_memo(Index, Name) ->
  case ets:lookup(memo_table_name(), Index) of
    [] -> {error, not_found};
    [{Index, Plist}] ->
      case proplists:lookup(Name, Plist) of
        {Name, Result}  -> {ok, Result};
        _  -> {error, not_found}
      end
    end.

memo_table_name() ->
    get({parse_memo_table, ?MODULE}).

p_eof() ->
  fun(<<>>, Index) -> {eof, [], Index};
     (_, Index) -> {fail, {expected, eof, Index}} end.

p_optional(P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} -> {[], Input, Index};
        {_, _, _} = Success -> Success
      end
  end.

p_not(P) ->
  fun(Input, Index)->
      case P(Input,Index) of
        {fail,_} ->
          {[], Input, Index};
        {Result, _, _} -> {fail, {expected, {no_match, Result},Index}}
      end
  end.

p_assert(P) ->
  fun(Input,Index) ->
      case P(Input,Index) of
        {fail,_} = Failure-> Failure;
        _ -> {[], Input, Index}
      end
  end.

p_and(P) ->
  p_seq(P).

p_seq(P) ->
  fun(Input, Index) ->
      p_all(P, Input, Index, [])
  end.

p_all([], Inp, Index, Accum ) -> {lists:reverse( Accum ), Inp, Index};
p_all([P|Parsers], Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail, _} = Failure -> Failure;
    {Result, InpRem, NewIndex} -> p_all(Parsers, InpRem, NewIndex, [Result|Accum])
  end.

p_choose(Parsers) ->
  fun(Input, Index) ->
      p_attempt(Parsers, Input, Index, none)
  end.

p_attempt([], _Input, _Index, Failure) -> Failure;
p_attempt([P|Parsers], Input, Index, FirstFailure)->
  case P(Input, Index) of
    {fail, _} = Failure ->
      case FirstFailure of
        none -> p_attempt(Parsers, Input, Index, Failure);
        _ -> p_attempt(Parsers, Input, Index, FirstFailure)
      end;
    Result -> Result
  end.

p_zero_or_more(P) ->
  fun(Input, Index) ->
      p_scan(P, Input, Index, [])
  end.

p_one_or_more(P) ->
  fun(Input, Index)->
      Result = p_scan(P, Input, Index, []),
      case Result of
        {[_|_], _, _} ->
          Result;
        _ ->
          {fail, {expected, Failure, _}} = P(Input,Index),
          {fail, {expected, {at_least_one, Failure}, Index}}
      end
  end.

p_label(Tag, P) ->
  fun(Input, Index) ->
      case P(Input, Index) of
        {fail,_} = Failure ->
           Failure;
        {Result, InpRem, NewIndex} ->
          {{Tag, Result}, InpRem, NewIndex}
      end
  end.

p_scan(_, [], Index, Accum) -> {lists:reverse( Accum ), [], Index};
p_scan(P, Inp, Index, Accum) ->
  case P(Inp, Index) of
    {fail,_} -> {lists:reverse(Accum), Inp, Index};
    {Result, InpRem, NewIndex} -> p_scan(P, InpRem, NewIndex, [Result | Accum])
  end.

p_string(S) when is_list(S) -> p_string(list_to_binary(S));
p_string(S) ->
    Length = erlang:byte_size(S),
    fun(Input, Index) ->
      try
          <<S:Length/binary, Rest/binary>> = Input,
          {S, Rest, p_advance_index(S, Index)}
      catch
          error:{badmatch,_} -> {fail, {expected, {string, S}, Index}}
      end
    end.

p_anything() ->
  fun(<<>>, Index) -> {fail, {expected, any_character, Index}};
     (Input, Index) when is_binary(Input) ->
          <<C/utf8, Rest/binary>> = Input,
          {<<C/utf8>>, Rest, p_advance_index(<<C/utf8>>, Index)}
  end.

p_charclass(Class) ->
    {ok, RE} = re:compile(Class, [unicode, dotall]),
    fun(Inp, Index) ->
            case re:run(Inp, RE, [anchored]) of
                {match, [{0, Length}|_]} ->
                    {Head, Tail} = erlang:split_binary(Inp, Length),
                    {Head, Tail, p_advance_index(Head, Index)};
                _ -> {fail, {expected, {character_class, binary_to_list(Class)}, Index}}
            end
    end.

p_regexp(Regexp) ->
    {ok, RE} = re:compile(Regexp, [unicode, dotall, anchored]),
    fun(Inp, Index) ->
        case re:run(Inp, RE) of
            {match, [{0, Length}|_]} ->
                {Head, Tail} = erlang:split_binary(Inp, Length),
                {Head, Tail, p_advance_index(Head, Index)};
            _ -> {fail, {expected, {regexp, binary_to_list(Regexp)}, Index}}
        end
    end.

line({{line,L},_}) -> L;
line(_) -> undefined.

column({_,{column,C}}) -> C;
column(_) -> undefined.

p_advance_index(MatchedInput, Index) when is_list(MatchedInput) orelse is_binary(MatchedInput)-> % strings
  lists:foldl(fun p_advance_index/2, Index, unicode:characters_to_list(MatchedInput));
p_advance_index(MatchedInput, Index) when is_integer(MatchedInput) -> % single characters
  {{line, Line}, {column, Col}} = Index,
  case MatchedInput of
    $\n -> {{line, Line+1}, {column, 1}};
    _ -> {{line, Line}, {column, Col+1}}
  end.
