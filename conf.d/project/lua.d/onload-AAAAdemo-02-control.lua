--[[
  Copyright (C) 2016 "IoT.bzh"
  Author Fulup Ar Foll <fulup@iot.bzh>

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  Control are defined in onload-AAAAdemo-config.json

  NOTE: strict mode: every global variables should be prefixed by '_'
--]]

function _Mpdc_To_Multimedia (request, client, control)
    printf ("--InLua-- _Mpdc_To_Multimedia control=%s client=%s", Dump_Table(control), Dump_Table(client))

     -- in strict mode every variables should be declared
    local err=0
    local ctlhal={}
    local response={}
    local apihal={}

    if (_MPDC_CTX["multimedia"] == nil) then
       AFB_ERROR("_Mpdc_To_Multimedia no MPDC context for multimedia in _MPDC_CTX=%s", Dump_Table(_MPDC_CTX))
       return 1 -- control refuse
    end

    -- Parse client and search for action
    if (client["action"] == nil) then
      AFB_ERROR ("_Mpdc_To_Multimedia no action in request=%s", client)
      return 1 -- control refused
    end

    -- So far request looks good let's send it to MPDC
    local verb= client["action"]  -- use action as API verb
    client["action"]=nil  -- remove action and use remain client part as it
    client["session"]=_MPDC_CTX["multimedia"] -- retreive multimedia MPDC session

    -- send request to MPDC synchronously
    err, response= AFB:servsync ("mpdc", verb, client)

    -- Note: in current version controls only return a status. Also we may safely ignore API response
    -- Api returning Data may use request. In the feature a special tag may indicate that a control
    -- is allowed to return data.

    if (err) then
        AFB:error("--LUA:_Mpdc_To_Multimedia refuse response=%s", response)
        return 1 -- control refused
    end

    AFB:success(request, response)

    return 0 -- control accepted
end
