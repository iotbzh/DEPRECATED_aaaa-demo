var afb = new AFB("api", "mysecret");
var ws;
var sndcard = "hw:0";
var evtidx = 0;

//***********************
// Logger
//***********************
var log = {
    command: function (api, verb, query) {
        var q = urlws + "/" + api + "/" + verb + "?query=" + JSON.stringify(query);
        console.log("command: api=" + api + " verb=" + verb + " query=", query);
        log.write("COMMAND", "", q + "\n\n");
    },

    event: function (obj) {
        console.log("gotevent:" + JSON.stringify(obj));
        log.write("EVENT", (evtidx++), log.syntaxHighlight(obj) + "\n\n");
    },

    reply: function (obj) {
        console.log("replyok:" + JSON.stringify(obj));
        log.write("REPLY", "", log.syntaxHighlight(obj) + "\n\n");
    },

    error: function (obj) {
        console.log("replyerr:" + JSON.stringify(obj));
        log.write("ERROR", "", log.syntaxHighlight(obj) + "\n\n");
    },

    write: function (action, index, msg) {
        var logger = document.getElementById(action == "EVENT" ? "logger-event" : "logger-cmd");

        cls = 'action-' + action.toLowerCase();
        var txt = action
        if (index.toString() != "") {
            txt += " " + index.toString();
        }
        logger.innerHTML += '<span class="' + cls + ' ">' + txt + ':</span> ';
        logger.innerHTML += msg;

        // auto scroll down
        setTimeout(function () {
            logger.scrollTop = logger.scrollHeight;
        }, 100);

    },

    syntaxHighlight: function (json) {
        if (typeof json !== 'string') {
            json = JSON.stringify(json, undefined, 2);
        }
        json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
            var cls = 'number';
            if (/^"/.test(match)) {
                if (/:$/.test(match)) {
                    cls = 'key';
                } else {
                    cls = 'string';
                }
            } else if (/true|false/.test(match)) {
                cls = 'boolean';
            } else if (/null/.test(match)) {
                cls = 'null';
            }
            return '<span class="' + cls + '">' + match + '</span>';
        });
    },

};

//***********************
// Generic function to call binder
//************************
function callbinder(api, verb, query, cbOK, cbErr) {
    log.command(api, verb, query)

    // FIXME SEB A SUP
    // Update UI according to target action
    switch (query.target) {
        case "phone":
            btnPhoneAnimate(5);
            break;

        case "navigation":
            /* just for test
            btnShake("navigation");
            btnShake("phone-call");
            */
            break;

    }

    var ccbOK = cbOK;
    var replyok = function (obj) {
        log.reply(obj);
        if (ccbOK)
            ccbOK(obj);
    }

    var ccbErr = cbErr;
    var replyerr = function (obj) {
        log.error(obj);
        if (ccbErr)
            ccbErr();
    }

    ws.call(api + "/" + verb, query).then(replyok, replyerr);
}

function callRequest(target, args) {
    return callbinder('control', 'request', {target: target, args: args});
}

function callDispatch() {
    return callbinder('control', 'dispatch', {target: target, args: args});
}

//***********************
// Buttons bar management
//***********************

//*******
// Music
//*******
var btnMusicState = 1;

function IconMusicToogle() {
    var elem = document.getElementById("music");
    elem.style.backgroundImage = (btnMusicState) ? 'url(assets/music-pause.png)' : 'url(assets/music-play.png)';
    btnMusicState = !btnMusicState;
}

function btnMusicStartStop() {
    var query = {
        target: 'multimedia',
        args: {
            action: '',
            toggle: true
        }
    };
    query.args.action = (btnMusicState) ? 'play' : 'stop';
    callbinder('control', 'dispatch', query,
        function (res) {
            IconMusicToogle();
        }
    );
}

//*******
// Phone
//*******
var btnPhoneImages = [
    "assets/phone-call.png",
    "assets/phone-call-emit1.png",
    "assets/phone-call-emit2.png",
    "assets/phone-call-emit3.png",
];

function btnPhoneAnimate(timeout) {
    var infoText = document.getElementById("info-text");
    var elem = document.getElementById("phone-call");
    var loop = 0;
    var idx = 1;
    elem.style.backgroundImage = 'url(' + btnPhoneImages[idx] + ')';
    var id = setInterval(anim, 500);
    infoText.innerHTML = "Calling...";

    function anim() {
        if (++idx >= btnPhoneImages.length) {
            idx = 0;
        }
        elem.style.backgroundImage = 'url(' + btnPhoneImages[idx] + ')';
        if (loop++ > timeout) {
            elem.style.backgroundImage = 'url(' + btnPhoneImages[0] + ')';
            infoText.innerHTML = "";
            clearInterval(id);
        }
    }
}

function btnShake(btnId) {
    var elem = document.getElementById(btnId);
    prevClass = elem.className;
    elem.className += " shake";
    setTimeout(function () {
        elem.className = prevClass;
    }, 1000);
}

//***********************
// Speed management
//***********************
var SPEED_INCREMENT = 5;

function speedInc() {
    speedUpdateInput(SPEED_INCREMENT);
}

function speedDec() {
    speedUpdateInput(0 - SPEED_INCREMENT);
}

function speedUpdateInput(val) {
    var elem = document.getElementById("speed");
    var speed = parseInt(elem.value.split(' ')[0]);
    elem.value = (speed + val).toString() + ' km/h';
}

//***********************
// Sound volume management
//***********************
var VOLUME_INCREMENT = 1;

function volumeInc() {
    volumeUpdateInput(VOLUME_INCREMENT);
}

function volumeDec() {
    volumeUpdateInput(0 - VOLUME_INCREMENT);
}

function volumeUpdateInput(val) {
    var elem = document.getElementById("volume");
    var volume = parseInt(elem.value.split(' ')[0]);
    if ((volume == 0 && val < 0) ||
        (volume == 100 && val > 0)) {
        return;
    }
    elem.value = (volume + val).toString();
}

//***********************
// Music playlist and zone
//***********************
function updatePlaylist(list) {
    var musicSelect = document.getElementById("musicSelect");
    var el;
    for (el in list) {
        var option = document.createElement("option");
        option.text = "";
        if (list[el].artist && list[el].artist.length > 0) {
            option.text += list[el].artist[0];
        }
        if (list[el].title && list[el].title.length > 0) {
            option.text += " - " + list[el].title[0];
        } else if (list[el].uri) {
            option.text += " - " + list[el].uri.replace(".mp3", "");
        }
        musicSelect.add(option);
    }
}

function updateZones(output) {
    var zoneSelect = document.getElementById("musicZonesSelect");
    var el;

    // Add all entry
    var option = document.createElement("option");
    option.text = "all";
    option.selected = "selected";
    option.value = JSON.stringify({"all": true, "enable": true})
    zoneSelect.add(option);

    for (el in output) {
        if (!output[el].enable) {
            continue;
        }
        var option = document.createElement("option");
        option.text = output[el].name;
        option.value = JSON.stringify({"name": output[el].name, "enable": true})
        zoneSelect.add(option);
    }
}

//***********************
// Initialization
//***********************
function init(api, verb, query) {

    var btnConn = document.getElementById("connected");
    var page = document.getElementsByClassName("page-content")[0];
    var dashboard = document.getElementsByClassName("dashboard")[0];

    function onopen() {
        // FIXME SEB A SUP
        setTimeout(function () {
            btnShake("phone-call");
        }, 2000);

        // Event subscription + retrieve initial state
        callbinder(api, verb, query, function (res) {
            if (res.response && res.response.playlist) {
                updatePlaylist(res.response.playlist);
            } else {
                console.error("Invalid response, missing playlist\n", res.response);
            }
            if (res.response && res.response.output) {
                updateZones(res.response.output);
            } else {
                console.error("Invalid response, missing output\n", res.response);
            }

        });

        ws.onevent("*", function gotevent(obj) {
            log.event(obj);
        });

        btnConn.innerHTML = "Binder Connection Active";
        btnConn.style.background = "lightgreen";
        page.style.background = dashboard.style.opacity = dashboard.style.zIndex = "";
    }

    function onabort() {
        btnConn.innerHTML = "Connection Closed";
        btnConn.style.background = "red";

        return;
        // Grey out page and disable dashboard
        page.style.background = "rgba(0,0,0,.5)";
        dashboard.style.opacity = "0.2";
        dashboard.style.zIndex = "-1";
    }
    ws = new afb.ws(onopen, onabort);
}
