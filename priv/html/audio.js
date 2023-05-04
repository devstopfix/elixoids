'use strict';

function toggleSound() {
    if (fxAudioContext == undefined) {
        initFX();
    } else {
        fxAudioContext = undefined;
        document.getElementById('toggle_audio').innerText = "AUDIO";
    }
}

function initFX() {
    try {
        fxAudioContext = new AudioContext();
        document.getElementById('toggle_audio').innerText = "AUDIO 🔉";
        var root = [window.location.protocol, window.location.host].join('//');
        for (var i = 1; i <= 7; i++) {
            var url = [root, 'audio', 'explosion', i + '.mp3'].join('/');
            loadSoundBuffer(url, fxAudioBuffers.explosion);
        }
        return true;
    }
    catch (e) {
        document.getElementById('toggle_audio').innerText = "AUDIO \u274c";
        console.error('Web Audio API is not supported in this browser');
        console.error(e)
        return false;
    }
}

function loadSoundBuffer(url, target) {
    var request = new XMLHttpRequest();
    request.open('GET', url, true);
    request.responseType = 'arraybuffer';

    request.onload = function () {
        fxAudioContext.decodeAudioData(request.response, function (buffer) {
            target.push(buffer);
        }, function (e) {
            console.error(e);
        });
    }
    request.send();
}

function playExplosion(audio) {
    // TODO check for empty buffer list
    var index = (audio.index || 0) % fxAudioBuffers.explosion.length;
    var source = fxAudioContext.createBufferSource();
    source.buffer = fxAudioBuffers.explosion[index];
    var gainFadeOut = fxAudioContext.createGain();
    gainFadeOut.gain.setValueAtTime(gainFadeOut.gain.value - 0.2, fxAudioContext.currentTime);
    source.connect(gainFadeOut)
    gainFadeOut.connect(fxAudioContext.destination);
    gainFadeOut.gain.exponentialRampToValueAtTime(0.01, fxAudioContext.currentTime + 2);
    source.start();
}