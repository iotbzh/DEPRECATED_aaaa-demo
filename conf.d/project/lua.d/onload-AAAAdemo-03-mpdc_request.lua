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

  NOTE: strict mode: every global variables should be prefixed by '_'
--]]

function _Mpdc_To_Request (mpcName, request, args)

     -- in strict mode every variables should be declared
    local err=0
    local response={}

    if (_MPDC_CTX[mpcName] == nil) then
       AFB_ERROR("_Mpdc_To_Request no MPDC context for %s in _MPDC_CTX=%s",
            mpcName, Dump_Table(_MPDC_CTX))
       return 1 -- request refuse
    end

    -- Parse args and search for action
    if (args["action"] == nil) then
      AFB_ERROR ("_Mpdc_To_Request %s no action in request=%s", mpcName, args)
      return 1 -- request refused
    end

    -- So far request looks good let's send it to MPDC
    local verb= args["action"]          -- use action as API verb
    args["action"]=nil                  -- remove action and use remain args part as it
    args["session"]=_MPDC_CTX[mpcName]  -- retreive  MPDC session

    -- send request to MPDC synchronously
    err, response= AFB:servsync ("mpdc", verb, args)
    if (err) then
        AFB:fail(request, "--LUA:_Mpdc_To_Request %s refuse response=%s",
                mpcName, response)
        return 1 -- request refused
    end

    AFB:success(request, response)
    return 0 -- control accepted
end

function _Mpdc_To_Multimedia_Request (request, args, control)
    printf ("--InLua-- _Mpdc_To_Multimedia_Request request args=%s", Dump_Table(args))
    return _Mpdc_To_Request("multimedia", request, args, control)
end

function _Mpdc_To_Emergency_Request (request, args, control)
    printf ("--InLua-- _Mpdc_To_Emergency request args=%s", Dump_Table(args))
    return _Mpdc_To_Request("emergency", request, args, control)
end

function _Mpdc_To_Navigation_Request (request, args, control)
    printf ("--InLua-- _Mpdc_To_Navigation request args=%s", Dump_Table(args))
    return _Mpdc_To_Request("navigation", request, args, control)
end
