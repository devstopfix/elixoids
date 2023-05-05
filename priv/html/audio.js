'use strict';

function toggleSound() {
    if (fxAudioContext == undefined) {
        initFX();
    } else {
        fxAudioContext = undefined;
        document.getElementById('toggle_audio').innerText = "AUDIO";
    }
}

function loadSoundBuffers(n, type, buffers) {
    if (buffers.length < n) {
        var root = [window.location.protocol, window.location.host].join('//');
        for (var i = 1; i <= n; i++) {
            var url = [root, 'audio', type, i + '.mp3'].join('/');
            loadSoundBuffer(url, buffers);
        }
    }
}

function initFX() {
    try {
        fxAudioContext = new AudioContext();
        document.getElementById('toggle_audio').innerText = "AUDIO 🔉";
        loadSoundBuffers(7, 'explosion', fxAudioBuffers.explosion);
        loadSoundBuffers(8, 'shoot', fxAudioBuffers.bullet);
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

function playExplosion(audio, buffers) {
    if (buffers.length > 0) {
        var index = (audio.index || 0) % buffers.length;
        var source = fxAudioContext.createBufferSource();
        source.buffer = buffers[index];
        var gainFadeOut = fxAudioContext.createGain();
        gainFadeOut.gain.setValueAtTime(gainFadeOut.gain.value - 0.2, fxAudioContext.currentTime);
        source.connect(gainFadeOut)
        gainFadeOut.connect(fxAudioContext.destination);
        gainFadeOut.gain.exponentialRampToValueAtTime(0.01, fxAudioContext.currentTime + 2);
        source.start();
    }
}

function playShot(audio, buffers, context) {
    if (buffers.length > 0) {
        var index = (audio.index || 0) % buffers.length;
        var source = context.createBufferSource();
        source.buffer = buffers[index];
        var gainFadeOut = context.createGain();
        gainFadeOut.gain.setValueAtTime(gainFadeOut.gain.value - 0.2, context.currentTime);
        source.connect(gainFadeOut)
        gainFadeOut.connect(context.destination);
        gainFadeOut.gain.exponentialRampToValueAtTime(0.01, context.currentTime + 0.5);
        source.start();
    }
}

function playSound(audio, context) {
    console.log(audio)
    switch(audio.name) {
        case "explosion":
          playExplosion(audio, fxAudioBuffers.explosion);
          break;
        case "bullet":
          playShot(audio, fxAudioBuffers.bullet, context);
          break;
      }
}