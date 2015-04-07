// This file is part of MusicBrainz, the open internet music database.
// Copyright (C) 2014 MetaBrainz Foundation
// Licensed under the GPL version 2, or (at your option) any later version:
// http://www.gnu.org/licenses/gpl-2.0.txt

var request = require('./utility/request.js');

(function () {
    // https://wiki.musicbrainz.org/Development/Supported_browsers
    var browser = $.browser,
        browserVersion = browser.version,
        browserIsSupported = (
            (browser.safari && browserVersion >= "5.1") ||
            (browser.chrome && browserVersion >= "31") ||
            (browser.msie && browserVersion >= "8.0") ||
            (browser.mozilla && browserVersion >= "24") ||
            (browser.opera && browserVersion >= "12.10")
        );

    if (!browserIsSupported) {
        var notice = "Unsupported browser detected: " + window.navigator.userAgent;
        if (window.console) {
            console.log(notice);
        } else if (window.opera) {
            opera.postError(notice);
        }
        return;
    }

    var location = window.location,
        origin = location.origin || (location.protocol + "//" + location.host),
        urlRegex = new RegExp("^" + origin + "/static/.*\\.js$"),
        reported = {};

    window.onerror = function (message, url, line, column, error) {
        if (!urlRegex.test(url)) {
            return;
        }

        message += "\n\nURL: " + url + "\nLine: " + line;

        // Unavailable in Firefox<31 or Opera 12
        if (column !== undefined) {
            message += "\nColumn: " + column;
        }

        // Unavailable in IE<10 or Opera 12
        if (error && error.stack) {
            message += "\n\n" + error.stack;
        }

        if (reported[message] === undefined) {
            reported[message] = true;

            request({
                type: "POST",
                url: "/ws/js/error",
                data: JSON.stringify({ error: message }),
                contentType: "application/json; charset=utf-8"
            });
        }
    };
}());
