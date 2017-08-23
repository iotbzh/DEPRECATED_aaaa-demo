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

-- Declare a global Context table to keep track of different HAL
_HAL_CTX={}

-- Init HAL
function _Init_Hal (source, args)
    printf ("--InLua-- _Init_Hal args=%s", Dump_Table(args))

    -- Create HAL contexts by zone and add "all" zone
    _HAL_CTX={}
    _HAL_CTX["all"]={}
    local idx=0
    for k, v in pairs(args) do
        _HAL_CTX[v["zone"]] = {[0] = v}
        _HAL_CTX["all"][idx] = v
        idx = idx + 1
    end

    return 0 -- happy end
end
