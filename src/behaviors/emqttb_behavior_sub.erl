%%--------------------------------------------------------------------
%% Copyright (c) 2022 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------
-module(emqttb_behavior_sub).

-behavior(emqttb_worker).

%% behavior callbacks:
-export([create_settings/2, init/1, handle_message/3, terminate/2]).

-export_type([]).

%%================================================================================
%% Type declarations
%%================================================================================

-define(CNT_SUB_MESSAGES(GRP), {emqttb_received_messages, GRP}).

%%================================================================================
%% behavior callbacks
%%================================================================================

create_settings(Group,
                #{ topic := Topic
                 }) when is_binary(Topic) ->
  SubCnt = emqttb_metrics:new_counter(?CNT_SUB_MESSAGES(Group),
                                      [ {help, <<"Number of received messages">>}
                                      , {labels, [group]}
                                      ]),
  #{ topic       => Topic
   , sub_counter => SubCnt
   }.

init(#{topic := T}) ->
  {ok, Conn} = emqttb_worker:connect([], []),
  emqtt:subscribe(Conn, T),
  Conn.

handle_message(#{sub_counter := Cnt}, Conn, {publish, #{client_pid := Pid}}) when
    Pid =:= Conn ->
  emqttb_metrics:counter_inc(Cnt, 1),
  {ok, Conn};
handle_message(_, Conn, _) ->
  {ok, Conn}.

terminate(_Shared, Conn) ->
  emqtt:disconnect(Conn),
  emqtt:stop(Conn).

%%================================================================================
%% Internal functions
%%================================================================================
