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

function _Mpdc_To_Multimedia (source, args, query)
     printf ("--InLua-- _Mpdc_To_Multimedia arg=%s query=%s", Dump_Table(args), Dump_Table(query))

     -- in strict mode every variables should be declared
    local err=0
    local response={}

    if (_MPDC_CTX["multimedia"] == nil) then
       AFB_ERROR("_Mpdc_To_Multimedia no MPDC context for multimedia in _MPDC_CTX=%s", Dump_Table(_MPDC_CTX))
       return 1 -- control refuse
    end

    -- Parse query and search for action
    if (query["action"] == nil) then
      AFB_ERROR ("_Mpdc_To_Multimedia no action in request=%s", query)
      return 1 -- control refused
    end

    -- So far request looks good let's send it to MPDC
    local verb= query["action"]  -- use action as API verb
    query["action"]=nil  -- remove action and use remain query part as it
    query["session"]=_MPDC_CTX["multimedia"] -- retreive multimedia MPDC session

    -- send request to MPDC synchronously
    local err, response= AFB:servsync ("mpdc", verb, query)

    -- Note: in current version controls only return a status. Also we may safely ignore API response
    -- Api returning Data may use request. In the feature a special tag may indicate that a control
    -- is allowed to return data.

    if (err) then
        AFB:error("--LUA:_Mpdc_To_Multimedia refuse response=%s", response)
        return 1 -- control refused
    end

    return 0 -- control accepted
end

-- merge information from control and from event and push to HTML5 UI
function _Mpdc_Get_Event (source, control, event)
    printf ("--InLua-- _Mpdc_Get_Event source=%s control=%s event=%s", Dump_Table(source), Dump_Table(control),  Dump_Table(event))

    -- simply send back every we get to UI
    local data = {
      ["control"]=control,
      ["event"]=event,
    }

    AFB:evtpush (_EventHandle, data)
end

