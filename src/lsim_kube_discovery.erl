%%
%% Copyright (c) 2016 SyncFree Consortium.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

-module(lsim_kube_discovery).
-author("Vitor Enes Duarte <vitorenesduarte@gmail.com").

-include("lsim.hrl").

-behaviour(lsim_discovery).

-export([rsg/1,
         nodes/1]).

-spec rsg(node_port()) ->
    {ok, node_spec()} | {error, not_connected}.
rsg(Port) ->
    Nodes = get_tasks(rsg, Port),

    case Nodes of
        [] ->
            {error, not_connected};
        [RSG|_] ->
            {ok, RSG}
    end.

-spec nodes(node_port()) ->
    [node_spec()].
nodes(Port) ->
    get_tasks(lsim, Port).

%% @private
get_tasks(Tag, Port) ->
    Headers = headers(),
    URL = url(Tag),
    Options = [{body_format, binary}],
    DecodeFun = fun(Body) -> jsx:decode(Body, [return_maps]) end,

    Reply = case httpc:request(get, {URL, Headers}, [], Options) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, DecodeFun(Body)};
        {error, Reason} ->
            lager:info("Couldn't get list of nodes. Reason ~p",
                       [Reason]),
            {error, invalid}
    end,

    generate_nodes(Reply, Port).

%% @private
headers() ->
    Token = lsim_config:get(lsim_token),
    [{"Authorization", "Bearer " ++ Token}].

%% @private
url(Tag) ->
    APIServer = lsim_config:get(lsim_api_server),
    Timestamp = lsim_config:get(lsim_timestamp),

    APIServer ++ "/api/v1/pods?labelSelector="
              ++ "timestamp%3D" ++ integer_to_list(Timestamp)
              ++ ",tag%3D" ++ atom_to_list(Tag).

%% @private
generate_nodes(Reply, Port) ->
    List = case Reply of
        {ok, Map} ->
            #{<<"items">> := Items} = Map,
            case Items of
                null ->
                    [];
                _ ->
                    Items
            end;
        _ ->
            []
    end,

    generate_spec(List, Port).

%% @private
generate_spec(List, Port) ->
    lists:map(
        fun(E) ->
            IP = get_ip(E),
            %_Port = list_to_integer(get_port(E)),
            lsim_util:generate_spec(IP, Port)
        end,
        List
    ).

%% @private
get_ip(E) ->
    #{<<"status">> := Status} = E,
    #{<<"podIP">> := IP} = Status,
    decode(IP).

%% @private
%get_port(E) ->
%    #{<<"spec">> := Spec} = E,
%    #{<<"containers">> := [Container|_]} = Spec,
%    #{<<"env">> := Envs} = Container,
%
%    PortBinary = lists:foldl(
%        fun(Env, Acc) ->
%            #{<<"name">> := Name} = Env,
%            case Name of
%                <<"PEER_PORT">> ->
%                    #{<<"value">> := Value} = Env,
%                    Value;
%                _ ->
%                    Acc
%            end
%        end,
%        undefined,
%        Envs
%    ),
%
%    decode(PortBinary).

%% @private
decode(Binary) ->
    binary_to_list(Binary).
