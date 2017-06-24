-module(rlp).

%% API exports
-export([encode/1, decode/1]).

%% debug
-export([encode_length/2, decode_length/2]).

-type value() :: binary().
-type rlist() :: list(rlist()) | value().

-type bytel() :: pos_integer().
-type length() :: pos_integer().
-type rlp() :: binary().
-type offset() :: 128 | 192.

%%====================================================================
%% API functions
%%====================================================================

-spec encode(rlist()) -> rlp().
encode(X) ->
    {_Length, Result} = encode_wl(X),
    Result.

-spec decode(rlp()) -> rlist().
decode(Binary) when is_binary(Binary) ->
    case decode_partial(Binary) of
        {_, Value, <<>>} ->
            Value;
        {_, _, Junk} ->
            error({trailing_data, Junk})
    end.

%%====================================================================
%% Internal functions
%%====================================================================

-spec encode_wl(rlist()) -> {bytel(), rlp()}.
encode_wl(List) when is_list(List) ->
    encode_list(List);
encode_wl(Value) when is_binary(Value) ->
    encode_value(Value).

encode_list(List) ->
    {Lengths, BinsList} = lists:unzip([ encode_wl(X) || X <- List ]),
    Total = lists:sum(Lengths),
    Bins = binary:list_to_bin(BinsList),
    {SH, Header} = encode_length(Total, 192),
    {SH + Total, <<Header/binary, Bins/binary>>}.

encode_value(Bin) ->
    encode_value(size(Bin), Bin).

encode_value(0, <<>>) ->
    {1, <<128>>};
encode_value(1, <<Bin/integer>> = Data) when Bin < 128 ->
    {1, Data};
encode_value(L, Bin) ->
    {SH, H} = encode_length(L, 128),
    {SH + L, <<H/binary, Bin/binary>>}.

-spec encode_length(length(), offset()) -> {bytel(), binary()}.
encode_length(L, Offset) when L < 56 ->
    X = L + Offset,
    {1, <<X>>};
encode_length(L, Offset) ->
    Len = binary:encode_unsigned(L, big),
    Byte = size(Len) + Offset + 55,
    {size(Len)+1, <<Byte:8, Len/binary>>}.

-spec decode_length(binary(), offset()) -> {bytel(), length(), Rest::binary()}.
decode_length(<<Data:8/big-unsigned-integer, Rest/binary>>, Offset) when Data < Offset + 56 ->
    {1, Data - Offset, Rest};
decode_length(<<Byte:8/big-unsigned-integer, LEnc/binary>>, Offset) ->
    SizeLen = Byte - Offset - 55,
    <<Len:SizeLen/big-unsigned-integer-unit:8, Rest/binary>> = LEnc,
    {SizeLen+1, Len, Rest};
decode_length(_, _) ->
    error(encoding_of_length_is_too_short).

-spec decode_partial(binary()) -> {bytel(), rlist(), Rest::binary()}.
decode_partial(<<128, Rest/binary>>) ->
    {1, <<>>, Rest};
decode_partial(<<X:8/big-unsigned-integer, Rest/binary>>) when X < 128 ->
    {1, <<X>>, Rest};
decode_partial(<<X:8/big-unsigned-integer, _/binary>> = Binary) when X =< 182 ->
    {SizeLen, DataLen, Tail} = decode_length(Binary, 128),
    case Tail of
        <<Data:DataLen/binary, Rest/binary>> ->
            {SizeLen + DataLen, Data, Rest};
        _ ->
            error(encoding_of_value_is_too_short)
    end;
decode_partial(<<_/binary>> = Binary) ->
    {SizeLen, BytesNo, Tail} = decode_length(Binary, 192),
    {Items, Tail2}  = loop_decode_list(Tail, BytesNo, []),
    {BytesNo + SizeLen, Items, Tail2}.

loop_decode_list(Data, 0, Acc) ->
    {lists:reverse(Acc), Data};
loop_decode_list(Data, BytesLeft, Acc) ->
    {Spent, Item, Rest} = decode_partial(Data),
    loop_decode_list(Rest, BytesLeft-Spent, [Item | Acc]).


