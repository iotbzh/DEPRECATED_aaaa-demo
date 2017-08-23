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

function _Hal_SetVolume (request, args, control)
    printf ("--InLua-- _Hal_SetVolume request args=%s", Dump_Table(args))

     -- in strict mode every variables should be declared
    local err=0
    local response={}

    if (GetTableSize(_HAL_CTX) == 0) then
       AFB:fail("_Hal_SetVolume HAL context _HAL_CTX not intialized")
       return 1 -- request refuse
    end

    for k, zn in pairs(_HAL_CTX[args["zone"]]) do
        -- send request to alsa synchronously
        local query = {
            ["devid"]="hw:0",
            ["ctl"]= {
                ["id"] = zn["numid"],
                ["val"] = args["volume"]
            }
        }
        printf("--InLua-- _Hal_SetVolume query %s", Dump_Table(query))
        err, response= AFB:servsync ("alsacore", "setctl", query)
        if (err) then
            AFB:fail(request, "--LUA:_Hal_SetVolume refuse response=%s", response)
            return 1 -- request refused
        end
    end

    AFB:success(request, response)
    return 0 -- control accepted
end

function _Hal_GetVolume (request, args, control)
    printf ("--InLua-- _Hal_GetVolume request args=%s", Dump_Table(args))

     -- in strict mode every variables should be declared
    local err=0
    local res={}

    if (GetTableSize(_HAL_CTX) == 0) then
       AFB:fail("_Hal_SetVolume HAL context _HAL_CTX not intialized")
       return 1 -- request refuse
    end

    for k, zn in pairs(_HAL_CTX[args["zone"]]) do
        -- send request to alsa synchronously
        local query = {
            ["devid"]="hw:0",
            ["ctl"]= {
                ["id"] = zn["numid"],
                ["val"] = ""
            }
        }
        printf("--InLua-- _Hal_GetVolume query %s", Dump_Table(query))
        err, res= AFB:servsync ("alsacore", "getctl", query)
        if (err) then
            AFB:fail(request, "--LUA:_Hal_SetVolume refuse response=%s", res)
            return 1 -- request refused
        end
    end

    AFB:success(request, res.response)

    return 0 -- control accepted

end
