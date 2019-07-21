/*
  Convert the HTML URL of the game into the WS URL of the graphics.
  */

function graphicsURL(window_location_href) {
    var url = new URL(window_location_href);

    switch (url.protocol) {
        case 'http:':
            url.protocol = 'ws';
            break;
        case 'https:':
            url.protocol = 'wss';
            break;
    }

    /* If running in development, override with default ports. TODO config? */
    switch (url.port) {
        case '3030':
            url.port = 8065;
            break;
        case '8000':
            url.port = 8065;
            break;
    }

    /* If in development, hardcode to game zero. TODO config? */
    if (url.pathname.match(/\/\d+\/game\w*/)) {
        url.pathname = url.pathname.replace(/game\w*$/, 'graphics');
    } else {
        url.pathname = "/0/graphics";
    }

    return url;
}


