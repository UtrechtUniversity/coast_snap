// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import NProgress from "nprogress"
import {LiveSocket} from "phoenix_live_view"

import $ from "jquery"
require("what-input");
window.$ = $;

import Foundation from "foundation-sites";
$(document).foundation();
$(function() {
    console.log('ready');
    $('.title-bar').on('toggled.zf.responsiveToggle', function() {
        $(this).toggleClass('open');
    });
});

import css from "../css/app.scss"
import "phoenix_html"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}})

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket

// click submit when file input has been changed
if (document.getElementById("upload-btn")!=null) {
    document.getElementById("upload-btn").onchange = function() {
        document.getElementById("upload-form").submit();
    };
}

window.copyToClipboard = function(file_path) {
    const cb = navigator.clipboard;
    cb.writeText(file_path).then(() => alert('URL copied'));
}

