var afb = new AFB("api", "mysecret");
var ws;
var sndcard = "hw:0";
var evtidx = 0;
var numid = 0;

var musicList = [
    "Track 1",
    "Track 2",
    "Track 3"
];

function replyok(obj) {
    log.reply(obj);
}

function replyerr(obj) {
    log.error(obj);
}

function gotevent(obj) {
    log.event(obj);

}

/************************/
// Logger
/************************/
var log = {
    logger: document.getElementById("logger"),

    command: function (api, verb, query) {
        var q = urlws + "/" + api + "/" + verb + "?query=" + JSON.stringify(query);
        console.log("subscribe api=" + api + " verb=" + verb + " query=" + query);
        log.write("COMMAND", q + "\n\n");
    },

    event: function (obj) {
        console.log("gotevent:" + JSON.stringify(obj));
        log.write("EVENT", (evtidx++) + ": " + JSON.stringify(obj) + "\n\n");
    },

    reply: function (obj) {
        console.log("replyok:" + JSON.stringify(obj));
        log.write("REPLY", log.syntaxHighlight(obj) + "\n\n");
    },

    error: function (obj) {
        console.log("replyerr:" + JSON.stringify(obj));
        log.write("ERROR", log.syntaxHighlight(obj) + "\n\n");
    },

    write: function (action, msg) {
        aclass = 'action-' + action.toLowerCase();
        logger.innerHTML += '<span class="' + aclass + ' ">' + action + ':</span> ';
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


/************************/
// Buttons bar management
/************************/

// On button click from HTML page
function callbinder(api, verb, query) {
    log.command(api, verb, query)

    switch (query.target) {
        case "phone":
            btnPhoneAnimate(5);
            break;
        case "multimedia":
            btnMusicToogle();
            break;

        case "navigation":
            btnShake("navigation");
            btnShake("phone-call");
            break;

    }
    ws.call(api + "/" + verb, query).then(replyok, replyerr);

}

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

var btnMusicState = 0;

function btnMusicToogle() {
    var elem = document.getElementById("music");
    elem.style.backgroundImage = (btnMusicState) ? 'url(assets/music-play.png)' : 'url(assets/music-pause.png)';
    btnMusicState = !btnMusicState;
}

function btnShake(btnId) {
    var elem = document.getElementById(btnId);
    prevClass = elem.className;
    elem.className += " shake";
    setTimeout(function () {
        elem.className = prevClass;
    }, 1000);
}
/************************/
// Speed management
/************************/
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

/************************/
// Sound volume management
/************************/
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





// Retrieve Select value and Text from the binder
// Note: selection of value/text for a given context is huggly!!!
function querySelectList(elemid, api, verb, query) {

    console.log("querySelectList elemid=%s api=%s verb=%s query=%s", elemid, api, verb, query);

    var selectobj = document.getElementById(elemid);
    if (!selectobj) {
        return;
    }

    // onlick update selected HAL api
    selectobj.onclick = function () {
        sndcard = this.value;
        console.log("Default Selection=" + sndcard);
    };

    function gotit(result) {

        // display response as for normal onclick action
        replyok(result);
        var response = result.response;

        // fulfill select with avaliable active HAL
        for (idx = 0; idx < response.length; idx++) {
            var opt = document.createElement('option');

            // Alsa LowLevel selection mode
            if (response[idx].name) opt.text = response[idx].name;
            if (response[idx].devid) opt.value = response[idx].devid;

            // HAL selection mode
            if (response[idx].shortname) opt.text = response[idx].shortname;
            if (response[idx].api) opt.value = response[idx].api;

            selectobj.appendChild(opt);
        }

        sndcard = selectobj.value;
    }

    var question = urlws + "/" + api + "/" + verb + "?query=" + JSON.stringify(query);
    document.getElementById("question").innerHTML = syntaxHighlight(question);

    // request lowlevel ALSA to get API list
    ws.call(api + "/" + verb, query).then(gotit, replyerr);
}

function refresh_list(self, api, verb, query) {
    console.log("refresh_list id=%s api=%s verb=%s query=%s", self.id, api, verb, query);

    if (self.value > 0) return;

    // onlick update selected HAL api
    self.onclick = function () {
        numid = parseInt(self.value);
        console.log("Default numid=%d", numid);
    };

    function gotit(result) {

        // display response as for normal onclick action
        replyok(result);
        var response = result.response;



        // fulfill select with avaliable active HAL
        for (idx = 0; idx < response.length; idx++) {
            var opt = document.createElement('option');

            // Alsa LowLevel selection mode
            opt.text = response[idx].name + ' id=' + response[idx].id;
            opt.value = response[idx].id;

            self.appendChild(opt);
        }
        self.selectedIndex = 2;
        numid = parseInt(self.value);
    }

    var question = urlws + "/" + api + "/" + verb + "?query=" + JSON.stringify(query);
    document.getElementById("question").innerHTML = syntaxHighlight(question);

    // request lowlevel ALSA to get API list
    ws.call(api + "/" + verb, query).then(gotit, replyerr);
}

function init(elemid, api, verb, query) {

    var btnConn = document.getElementById("connected");
    var page = document.getElementsByClassName("page-content")[0];
    var dashboard = document.getElementsByClassName("dashboard")[0];
    var musicSelect = document.getElementById("musicSelect");

    function onopen() {
        setTimeout(function() { btnShake("phone-call");}, 2000);

        // check for active HALs
        //querySelectList(elemid, api, verb, query);
        // Init playlist
        queryPlaylist(elemid, api, verb, query);

        // update music selection list
        musicList.forEach(function (el) {
            var option = document.createElement("option");
            option.text = el;
            musicSelect.add(option);
        });

        btnConn.innerHTML = "Binder Connection Active";
        btnConn.style.background = "lightgreen";
        page.style.background = dashboard.style.opacity = dashboard.style.zIndex = "";

        ws.onevent("*", gotevent);
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
