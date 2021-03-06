%%
%%   Copyright 2015 Zalando SE
%%
%%   Licensed under the Apache License, Version 2.0 (the "License");
%%   you may not use this file except in compliance with the License.
%%   You may obtain a copy of the License at
%%
%%       http://www.apache.org/licenses/LICENSE-2.0
%%
%%   Unless required by applicable law or agreed to in writing, software
%%   distributed under the License is distributed on an "AS IS" BASIS,
%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%   See the License for the specific language governing permissions and
%%   limitations under the License.
%%
%% @doc
%%   rest api - scenario management
-module(zephyrus_scenario).
-author('dmitry.kolesnikov@zalando.fi').

-include_lib("ambitz/include/ambitz.hrl").

-export([
   allowed_methods/1,
   content_provided/1, 
   content_accepted/1,
   'GET'/3,
   'PUT'/3,
   'DELETE'/3
]).

%%
allowed_methods(_Req) ->
   ['GET', 'PUT', 'DELETE'].

%%
content_provided(_Req) ->
   [{application, erlang}].

%%
content_accepted(_Req) ->
   [{application, erlang}, {application, json}].

%%
%%
'GET'(_Type, _Msg, {Url, _Head, Env}) ->
   Id = lens:get(lens:pair(<<"id">>), Env),
   R  = scalar:i(uri:q(<<"r">>, 1, Url)), 
   {ok, #entity{val = Val}} = typhoon:get({urn, root, Id}, [{r, R}]),
   case crdts:value(Val) of
      undefined ->
         404;
      
      {_, _, [_, Spec]} ->
         {200, Spec}
   end.

%%
%%
'PUT'({application, erlang}, Spec, {Url, _Head, Env}) ->
   Id = lens:get(lens:pair(<<"id">>), Env),
   W  = scalar:i(uri:q(<<"w">>, 1, Url)),
   {ok, _} = typhoon:put({urn, root, Id}, Spec, [{w, W}]),
   {ok, _} = typhoon:scenario({urn, user, root}, {urn, root, Id}, [{w, W}]),
   201;

%%
%%
'PUT'({application, json}, Spec, {Url, _Head, Env}) ->
   Id = lens:get(lens:pair(<<"id">>), Env),
   W  = scalar:i(uri:q(<<"w">>, 1, Url)),

   Json = jsx:decode(Spec),
   ScenarioName = lens:get(lens:pair(<<"scenarioName">>), Json),
   SpecToUse = create_skeleton(Id, ScenarioName),

   {ok, _} = typhoon:put({urn, root, Id}, SpecToUse, [{w, W}]),
   {ok, _} = typhoon:scenario({urn, user, root}, {urn, root, Id}, [{w, W}]),
   201.

%%
%%
'DELETE'(_Type, _Msg, {Url, _Head, Env}) ->
   Id = lens:get(lens:pair(<<"id">>), Env),
   W  = scalar:i(uri:q(<<"w">>, 1, Url)),   
   {ok,_} = typhoon:remove({urn, root, Id}, [{w, W}]),
   200.

create_skeleton(Id, ScenarioName) ->
   {ok, Skeleton} = file:read_file(
      filename:join([code:priv_dir(zephyrus), <<"skeleton.erl.tpl">>])
   ),

   Skeleton1 = binary:replace(
      Skeleton,
      <<"${MODULE_NAME_PLACEHOLDER}">>,
      Id),

   Skeleton2 = binary:replace(
      Skeleton1,
      <<"${TITLE_PLACEHOLDER}">>,
      ScenarioName),

   Skeleton2.
