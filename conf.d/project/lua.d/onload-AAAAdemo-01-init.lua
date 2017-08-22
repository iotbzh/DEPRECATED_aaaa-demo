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


  During Initialisation we open one connection for each of the MPD
  attached to Multimedia, Navigation and Emergency. We then store
  the session handle in a global table (_MPDC_CTX). Controls defined
  in 'onload-AAAAdemo-02-control.lua' will reference this table
  to send the request to the right MPD.

  NOTE: strict mode: every global variables should be prefixed by '_'
--]]

-- Declare a global Context table to keep track of different MPDC connections
_MPDC_CTX={}

-- Create event on Lua script load
_EventHandle={}

function _Mpdc_Async_CB (error, result, context)
    if (error) then
      AFB_ERROR ("--InLua-- _Mpdc_Async_CB result=%s context=%s", Dump_Table(result), Dump_Table(context))
      return
    end

    -- No error we should have a response
    local response=result["response"]

    if (response["session"] == nil) then
      AFB_ERROR("_Init_AAAAdemo_App: (Hoops Internal Error!!! )No Session Return by MPDC")
      return
    end

    -- store MPDC session indexed by label (multimedia, navigation, ...)
    printf ("--InLua-- _Mpdc_Async_CB _MPDC_CTX[%s]=%s\n", context["label"], response["session"])
    _MPDC_CTX[string.lower(context["label"])]= response["session"]

end

-- Display receive arguments and echo them to caller
function _Init_AAAAdemo_App (source, args)
    printf ("--InLua-- _Init_AAAAdemo_App args=%s", Dump_Table(args))

    _EventHandle=AFB:evtmake("AAAADemoEvent")

    -- Connect to 3 configured MPDc. Note that we use the same
    -- table for service query and callback context.
    -- Lua context can remain local as LUA never use references
    -- and callback always recieve a copy of context

    if (args["mpdc_multimedia"] ~= nil) then
      local MediaCtx = {
        ["label"]="Multimedia",
        ["hostname"]= args["mpdc_hostname"],
        ["port"]= args["mpdc_multimedia"],
        ["subscribe"]=true
      }
      AFB:service("mpdc","connect", MediaCtx, "_Mpdc_Async_CB", MediaCtx)
    end

    if (args["mpdc_navigation"] ~= nil) then
      local MediaCtx = {
        ["label"]="Navigation",
        ["hostname"]= args["mpdc_hostname"],
        ["port"]= args["mpdc_navigation"],
        ["subscribe"]=true
      }
      AFB:service("mpdc","connect", MediaCtx, "_Mpdc_Async_CB", MediaCtx)
    end

    if (args["mpdc_emergency"] ~= nil) then
      local MediaCtx = {
        ["label"]="Emergency",
        ["hostname"]= args["mpdc_hostname"],
        ["port"]= args["mpdc_emergency"],
        ["subscribe"]=true
      }
      AFB:service("mpdc","connect", MediaCtx, "_Mpdc_Async_CB", MediaCtx)
    end

    return 0 -- happy end
end

-- Events subsricption and retreive initial Multimedia state
function _Subscribe (request, args)
    printf ("--InLua-- Subscribe to events")

    if (args == nil or args["label"] == nil) then
        AFB:fail(request, "_Subscribe: missing args:{'label':xxx}")
        return
    end

    -- subscribe to event
    AFB:subscribe (request, _EventHandle)

    -- Retrieve initial state of MPDC / Multimedia
    local qVersion = {
        ["session"]=_MPDC_CTX["multimedia"]
    }
    local err, version = AFB:servsync("mpdc", "version", qVersion)
    if err then
        AFB:fail(request, "_Subscribe: fail to connect to MPDC server")
        return
    end
    version = version.response

    local qPlaylist = {
        ["session"]=_MPDC_CTX["multimedia"],
        ["current"]= true
    }
    local err, playlist = AFB:servsync("mpdc", "playlist", qPlaylist)
    printf ("--InLua-- playlist = %s", Dump_Table(playlist))
    if (not err) then
        playlist = playlist["response"]
    end

    local qOutput = {
        ["session"]=_MPDC_CTX["multimedia"],
        ["list"]=true,
        ["target"] = {
            ["all"]=true,
            ["enable"]=true
        }
    }
    local err, mpcOutput = AFB:servsync("mpdc","output", qOutput)
    printf ("--InLua-- mpcOutput = %s", Dump_Table(mpcOutput))
    if (not err) then
        mpcOutput = mpcOutput["response"]
    end

    local response = {
        ["version"]=version,
        ["playlist"]= playlist,
        ["output"]= mpcOutput
    }

    AFB:success(request, response)

    -- notify any clients
    local evt = {
        ["label"]="newClient",
        ["value"]=args["label"],
        ["info"]=args["info"]
    }
    AFB:evtpush (_EventHandle, evt)

    return 0 -- happy end
end
