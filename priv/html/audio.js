'use strict';

window.addEventListener('load', initFX, false);
function initFX() {
    try {
        fxAudioContext = new AudioContext();
        var root = [window.location.protocol, window.location.host].join('//');
        var url = [root, 'audio', 'explosion', '1.mp3'].join('/');
        loadSoundBuffer(url, fxAudioBuffers.explosion);
    }
    catch(e) {
        console.error('Web Audio API is not supported in this browser');
        console.error(e)
    }
}

function loadSoundBuffer(url, target) {
    var request = new XMLHttpRequest();
    request.open('GET', url, true);
    request.responseType = 'arraybuffer';

    // Decode asynchronously
    request.onload = function() {
        fxAudioContext.decodeAudioData(request.response, function(buffer) {
        target.push(buffer);
    }, function(e) {
        console.error(e);
    });
    }
    request.send();
}

function testSound() {
    var source = fxAudioContext.createBufferSource(); // creates a sound source
    source.buffer = fxAudioBuffers.explosion[0];    // tell the source which sound to play
    source.connect(fxAudioContext.destination);       // connect the source to the context's destination (the speakers)
    source.start(0);      
}
