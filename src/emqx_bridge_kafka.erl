%%--------------------------------------------------------------------
%% Copyright (c) 2020 EMQ Technologies Co., Ltd. All Rights Reserved.
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

-module(emqx_bridge_kafka).

-include_lib("emqx/include/emqx.hrl").
-include_lib("brod/include/brod.hrl").

-export([ load/1
        , unload/0
        ]).

%% Client Lifecircle Hooks
-export([ on_client_connect/3
        , on_client_connack/4
        , on_client_connected/3
        , on_client_disconnected/4
        , on_client_authenticate/3
        , on_client_check_acl/5
        , on_client_subscribe/4
        , on_client_unsubscribe/4
        ]).

%% Session Lifecircle Hooks
-export([ on_session_created/3
        , on_session_subscribed/4
        , on_session_unsubscribed/4
        , on_session_resumed/3
        , on_session_discarded/3
        , on_session_takeovered/3
        , on_session_terminated/4
        ]).

%% Message Pubsub Hooks
-export([ on_message_publish/2
        , on_message_delivered/3
        , on_message_acked/3
        , on_message_dropped/4
        ]).

%% Called when the plugin application start
load(Env) ->
    brod_init([Env]),
    % ekaf_init([Env]),
    % emqx:hook('client.connect',      {?MODULE, on_client_connect, [Env]}),
    % emqx:hook('client.connack',      {?MODULE, on_client_connack, [Env]}),
    emqx:hook('client.connected',    {?MODULE, on_client_connected, [Env]}),
    emqx:hook('client.disconnected', {?MODULE, on_client_disconnected, [Env]}),
    % emqx:hook('client.authenticate', {?MODULE, on_client_authenticate, [Env]}),
    % emqx:hook('client.check_acl',    {?MODULE, on_client_check_acl, [Env]}),
    % emqx:hook('client.subscribe',    {?MODULE, on_client_subscribe, [Env]}),
    % emqx:hook('client.unsubscribe',  {?MODULE, on_client_unsubscribe, [Env]}),
    % emqx:hook('session.created',     {?MODULE, on_session_created, [Env]}),
    % emqx:hook('session.subscribed',  {?MODULE, on_session_subscribed, [Env]}),
    % emqx:hook('session.unsubscribed',{?MODULE, on_session_unsubscribed, [Env]}),
    % emqx:hook('session.resumed',     {?MODULE, on_session_resumed, [Env]}),
    % emqx:hook('session.discarded',   {?MODULE, on_session_discarded, [Env]}),
    % emqx:hook('session.takeovered',  {?MODULE, on_session_takeovered, [Env]}),
    % emqx:hook('session.terminated',  {?MODULE, on_session_terminated, [Env]}),
    emqx:hook('message.publish',     {?MODULE, on_message_publish, [Env]}).
    % emqx:hook('message.delivered',   {?MODULE, on_message_delivered, [Env]}),
    % emqx:hook('message.acked',       {?MODULE, on_message_acked, [Env]}),
    % emqx:hook('message.dropped',     {?MODULE, on_message_dropped, [Env]}).

%%--------------------------------------------------------------------
%% Client Lifecircle Hooks
%%--------------------------------------------------------------------

on_client_connect(ConnInfo = #{clientid := ClientId}, Props, _Env) ->
    % io:format("Client(~s) connect, ConnInfo: ~p, Props: ~p~n",
    %           [ClientId, ConnInfo, Props]),
    % {M, S, _} = os:timestamp(),
    % Json = jsx:encode([
    %         {type,<<"connected">>},
    %         {clientid,ClientId},
    %         {ts,M * 1000000 + S},
    %         {cluster_node,node()}
    % ]),
    % ekaf:produce_async(<<"linkstatus">>, Json),
    {ok, Props}.

on_client_connack(ConnInfo = #{clientid := ClientId}, Rc, Props, _Env) ->
    io:format("Client(~s) connack, ConnInfo: ~p, Rc: ~p, Props: ~p~n",
              [ClientId, ConnInfo, Rc, Props]),
    {ok, Props}.

on_client_connected(ClientInfo = #{clientid := ClientId}, ConnInfo, _Env) ->
    % io:format("Client(~s) connected, ClientInfo:~n~p~n, ConnInfo:~n~p~n",
    %           [ClientId, ClientInfo, ConnInfo]),
    {M, S, _} = os:timestamp(),
    Json = jsx:encode([
            {type,<<"connected">>},
            {clientid,ClientId},
            {ts,M * 1000000 + S},
            {cluster_node,node()}
    ]),
    % ekaf:produce_async(<<"linkstatus">>, Json).
    PartitionFun = fun(_Topic, PartitionsCount, _Key, _Value) ->
                {ok, crypto:rand_uniform(0, PartitionsCount)}
                end,
    brod:produce_sync(brod_client_1, <<"linkstatus">>, PartitionFun, <<>>, Json).

on_client_disconnected(ClientInfo = #{clientid := ClientId}, ReasonCode, ConnInfo, _Env) ->
    % io:format("Client(~s) disconnected due to ~p, ClientInfo:~n~p~n, ConnInfo:~n~p~n",
    %           [ClientId, ReasonCode, ClientInfo, ConnInfo]),
    {M, S, _} = os:timestamp(),
    
    Json = jsx:encode([
            {type,<<"disconnected">>},
            {clientid,ClientId},
            {reasoncode,ReasonCode},
            {ts,M * 1000000 + S},
            {cluster_node,node()}
    ]),
    % ekaf:produce_async(<<"linkstatus">>, Json).
    PartitionFun = fun(_Topic, PartitionsCount, _Key, _Value) ->
                {ok, crypto:rand_uniform(0, PartitionsCount)}
                end,
    brod:produce_sync(brod_client_1, <<"linkstatus">>, PartitionFun, <<>>, Json).

on_client_authenticate(_ClientInfo = #{clientid := ClientId}, Result, _Env) ->
    io:format("Client(~s) authenticate, Result:~n~p~n", [ClientId, Result]),
    {ok, Result}.

on_client_check_acl(_ClientInfo = #{clientid := ClientId}, Topic, PubSub, Result, _Env) ->
    io:format("Client(~s) check_acl, PubSub:~p, Topic:~p, Result:~p~n",
              [ClientId, PubSub, Topic, Result]),
    {ok, Result}.

on_client_subscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
    io:format("Client(~s) will subscribe: ~p~n", [ClientId, TopicFilters]),
    {ok, TopicFilters}.

on_client_unsubscribe(#{clientid := ClientId}, _Properties, TopicFilters, _Env) ->
    io:format("Client(~s) will unsubscribe ~p~n", [ClientId, TopicFilters]),
    {ok, TopicFilters}.

%%--------------------------------------------------------------------
%% Session Lifecircle Hooks
%%--------------------------------------------------------------------

on_session_created(#{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) created, Session Info:~n~p~n", [ClientId, SessInfo]).

on_session_subscribed(#{clientid := ClientId}, Topic, SubOpts, _Env) ->
    io:format("Session(~s) subscribed ~s with subopts: ~p~n", [ClientId, Topic, SubOpts]).

on_session_unsubscribed(#{clientid := ClientId}, Topic, Opts, _Env) ->
    io:format("Session(~s) unsubscribed ~s with opts: ~p~n", [ClientId, Topic, Opts]).

on_session_resumed(#{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) resumed, Session Info:~n~p~n", [ClientId, SessInfo]).

on_session_discarded(_ClientInfo = #{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) is discarded. Session Info: ~p~n", [ClientId, SessInfo]).

on_session_takeovered(_ClientInfo = #{clientid := ClientId}, SessInfo, _Env) ->
    io:format("Session(~s) is takeovered. Session Info: ~p~n", [ClientId, SessInfo]).

on_session_terminated(_ClientInfo = #{clientid := ClientId}, Reason, SessInfo, _Env) ->
    io:format("Session(~s) is terminated due to ~p~nSession Info: ~p~n",
              [ClientId, Reason, SessInfo]).

%%--------------------------------------------------------------------
%% Message PubSub Hooks
%%--------------------------------------------------------------------

%% Transform message and return
on_message_publish(Message = #message{topic = <<"$SYS/", _/binary>>}, _Env) ->
    {ok, Message};

%% on_message_publish(Message, _Env) ->
%%     io:format("Publish ~s~n", [emqx_message:format(Message)]),
%%     {ok, Message}.

on_message_publish(Message, _Env) ->
    % io:format("Publish ~s~n", [emqx_message:format(Message)]),
    {ok, KafkaTopic} = application:get_env(emqx_bridge_kafka, values),
    % ProduceTopic = proplists:get_value(kafka_producer_topic, KafkaTopic),
    % KafkaTopic = proplists:get_value(kafka_producer_topic, Values),
    Topic=Message#message.topic,
    TopicStr = erlang:binary_to_list(Topic),
    LinkFlag = string:chr(TopicStr,$$),
    OtherFlag = string:chr(TopicStr,$/),
    if 
        LinkFlag == 1 ->
            ProduceTopicStr = "linktrace",
            ProduceTopic = erlang:list_to_binary(ProduceTopicStr);
            % ProduceTopic = ProduceTopicStr;
        OtherFlag /= 0 ->
            Tmp = string:tokens(TopicStr,"/"),
            ProduceTopicStr = erlang:hd(Tmp),
            ProduceTopic = erlang:list_to_binary(ProduceTopicStr);
            % ProduceTopic = ProduceTopicStr;
        true ->
            ProduceTopic = proplists:get_value(kafka_producer_topic, KafkaTopic)
            % ProduceTopic = KafkaTopic
    end,

    Payload=Message#message.payload,
    Qos=Message#message.qos,
    From=Message#message.from,
    % Headers=Message#message.headers#username,
    Username=maps:get(username,Message#message.headers),
    Timestamp=Message#message.timestamp,
    Json = jsx:encode([
            {type,<<"publish">>},
            {topic,Topic},
            {payload,Payload},
            {qos,Qos},
            {clientid,From},
            {username,Username},
            {cluster_node,node()},
            {ts,Timestamp}
    ]),
    PartitionFun = fun(_Topic, PartitionsCount, _Key, _Value) ->
                {ok, crypto:rand_uniform(0, PartitionsCount)}
                end,
    brod:produce_sync(brod_client_1, ProduceTopic, PartitionFun, <<>>, Json),

    % ekaf:produce_async(ProduceTopic, Json),
    % ekaf:produce_async(Topic, Payload),
    {ok, Message}.


on_message_dropped(#message{topic = <<"$SYS/", _/binary>>}, _By, _Reason, _Env) ->
    ok;
on_message_dropped(Message, _By = #{node := Node}, Reason, _Env) ->
    io:format("Message dropped by node ~s due to ~s: ~s~n",
              [Node, Reason, emqx_message:format(Message)]).

on_message_delivered(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
    io:format("Message delivered to client(~s): ~s~n",
              [ClientId, emqx_message:format(Message)]),
    {ok, Message}.

on_message_acked(_ClientInfo = #{clientid := ClientId}, Message, _Env) ->
    io:format("Message acked by client(~s): ~s~n",
              [ClientId, emqx_message:format(Message)]).

%% Called when the plugin application stop
unload() ->
    brod_close(),
    % emqx:unhook('client.connect',      {?MODULE, on_client_connect}),
    % emqx:unhook('client.connack',      {?MODULE, on_client_connack}),
    emqx:unhook('client.connected',    {?MODULE, on_client_connected}),
    emqx:unhook('client.disconnected', {?MODULE, on_client_disconnected}),
    % emqx:unhook('client.authenticate', {?MODULE, on_client_authenticate}),
    % emqx:unhook('client.check_acl',    {?MODULE, on_client_check_acl}),
    % emqx:unhook('client.subscribe',    {?MODULE, on_client_subscribe}),
    % emqx:unhook('client.unsubscribe',  {?MODULE, on_client_unsubscribe}),
    % emqx:unhook('session.created',     {?MODULE, on_session_created}),
    % emqx:unhook('session.subscribed',  {?MODULE, on_session_subscribed}),
    % emqx:unhook('session.unsubscribed',{?MODULE, on_session_unsubscribed}),
    % emqx:unhook('session.resumed',     {?MODULE, on_session_resumed}),
    % emqx:unhook('session.discarded',   {?MODULE, on_session_discarded}),
    % emqx:unhook('session.takeovered',  {?MODULE, on_session_takeovered}),
    % emqx:unhook('session.terminated',  {?MODULE, on_session_terminated}),
    emqx:unhook('message.publish',     {?MODULE, on_message_publish}).
    % emqx:unhook('message.delivered',   {?MODULE, on_message_delivered}),
    % emqx:unhook('message.acked',       {?MODULE, on_message_acked}),
    % emqx:unhook('message.dropped',     {?MODULE, on_message_dropped}).

%% Init kafka server parameters
% ekaf_init(_Env) ->
%     application:load(ekaf),
%     {ok, Values} = application:get_env(emqx_bridge_kafka, values),
%     BootstrapBroker = proplists:get_value(bootstrap_broker, Values),
%     PartitionStrategy= proplists:get_value(partition_strategy, Values),
%     application:set_env(ekaf, ekaf_partition_strategy, PartitionStrategy),
%     application:set_env(ekaf, ekaf_bootstrap_broker, BootstrapBroker),
%     {ok, _} = application:ensure_all_started(ekaf),
%     io:format("Initialized ekaf with ~p~n", [BootstrapBroker]).        

%% 初始化brod https://github.com/klarna/brod
brod_init(_Env) ->
    {ok, _} = application:ensure_all_started(brod), 
    {ok, Values} = application:get_env(emqx_bridge_kafka, values),
    BootstrapBroker = proplists:get_value(bootstrap_broker, Values),  
    KafkaTopic = proplists:get_value(kafka_producer_topic, Values),
    ClientConfig = [{auto_start_producers, true},
                    {allow_auto_topic_creation,true},
                    {default_producer_config, []}],%% socket error recovery
    ok = brod:start_client(BootstrapBroker, brod_client_1, ClientConfig),
    % ok = brod:start_producer(brod_client_1, KafkaTopic, _ProducerConfig = []),   
    io:format("Init brod KafkaBroker with ~p~n", [BootstrapBroker]),
    io:format("Init brod KafkaTopic with ~p~n", [KafkaTopic]).

%% 关闭brod
brod_close() ->
    {ok, Values} = application:get_env(emqx_plugin_kafka, values),
    BootstrapBroker = proplists:get_value(bootstrap_broker, Values), 
    io:format("Close brod with ~p~n", [BootstrapBroker]),
    brod:stop_client(brod_client_1).
