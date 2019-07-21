
function fullscreenFirstCanvas(ctrl) {
    ctrl.onclick = function () {
        var elem = document.querySelector("canvas");
        if (elem && elem.requestFullscreen) {
            elem.requestFullscreen();
        } else if (elem && elem.msRequestFullscreen) {
            elem.msRequestFullscreen();
        } else if (elem && elem.mozRequestFullScreen) {
            elem.mozRequestFullScreen();
        } else if (elem && elem.webkitRequestFullscreen) {
            elem.webkitRequestFullscreen();
        }
    }
}