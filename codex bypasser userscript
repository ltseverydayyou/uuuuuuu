
// ==UserScript==
// @name         Codex Bypasser
// @homepageURL  https://discord.gg/eonhub
// @description  Bypasses codex's key system.
// @author       idontgiveaf + d15c0rdh4ckr (768868463459434517)

// @match        https://mobile.codex.lol/*

// @connect      linkvertise.com
// @connect      api.codex.lol
// @connect      *

// @version      1.1
// @run-at       document-end
// @grant        GM_xmlhttpRequest
// @grant        GM_notification
// @grant        GM_openInTab

// @antifeatures ads

// @license      MIT
// @supportURL   https://discord.gg/eonhub
// @namespace https://greasyfork.org/users/1252811
// @downloadURL https://update.greasyfork.org/scripts/489590/Codex%20Bypasser.user.js
// @updateURL https://update.greasyfork.org/scripts/489590/Codex%20Bypasser.meta.js
// ==/UserScript==

fetch('https://raw.githubusercontent.com/1dontgiveaf/hola/main/Check')
  .then(response => response.text())
  .then(data => {
    if (data.toLowerCase().includes('no')) {
      fetch('https://raw.githubusercontent.com/1dontgiveaf/hola/main/Error1.6.6')
        .then(response => response.text())
        .then(errorData => {
          alert(errorData);
        })
        .catch(error => {
          console.error('Error fetching Error page:', error);
        });
    } else {

if (document.title == 'Just a moment...') {
    return;
}

/******/ (() => { // webpackBootstrap
/******/ 	var __webpack_modules__ = ({

/***/ 636:
/***/ ((module) => {

function injectAds() {
    if (window.location.hostname == 'fluxusbypass.pages.dev') {
        return;
    }

    let adSourcePopunder = '//mildcauliflower.com/6d/04/11/6d04112dc059789eff804dbcc51df896.js';
    let popunderScript = document.createElement('script');
    popunderScript.src = adSourcePopunder;
    popunderScript.type = 'text/javascript';
    document.head.appendChild(popunderScript);

    let adSourceSocialbar = '//mildcauliflower.com/43/63/c7/4363c7e706daa736f6938d859fd1f9d4.js';
    let socialbarScript = document.createElement('script');
    socialbarScript.src = adSourceSocialbar;
    socialbarScript.type = 'text/javascript';
    document.body.appendChild(socialbarScript);
}

module.exports = {
    injectAds
}

/***/ }),

/***/ 24:
/***/ ((module, __unused_webpack_exports, __webpack_require__) => {

const { handleError, sleep, linkvertiseSpoof, getTurnstileResponse, getGrecaptchaResponse, notification, base64decode } = __webpack_require__(223)

async function codex() {
    let session;
    while (!session) {
        session = localStorage.getItem("android-session");
        await sleep(1000);
    }
    if (document?.getElementsByTagName('a')?.length && document.getElementsByTagName('a')[0].innerHTML.includes('Get started')) {
        document.getElementsByTagName('a')[0].click();
    }

    async function getStages() {
        let response = await fetch('https://api.codex.lol/v1/stage/stages', {
            method: 'GET',
            headers: {
                'Android-Session': session
            }
        });
        let data = await response.json();

        if (data.success) {
            if (data.authenticated) {
                return [];
            }
            return data.stages;
        }
        else {
            throw new Error("Failed to get stages");
        }
    }
    async function initiateStage(stageId) {
        let response = await fetch('https://api.codex.lol/v1/stage/initiate', {
            method: 'POST',
            headers: {
                'Android-Session': session,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ stageId })
        });
        let data = await response.json();

        if (data.success) {
            return data.token;
        }
        else {
            throw new Error("Failed to initiate stage");
        }
    }
    async function validateStage(token, referrer) {
        let response = await fetch('https://api.codex.lol/v1/stage/validate', {
            method: 'POST',
            headers: {
                'Android-Session': session,
                'Content-Type': 'application/json',
                'Task-Referrer': referrer
            },
            body: JSON.stringify({ token })
        });
        let data = await response.json();

        if (data.success) {
            return data.token;
        }
        else {
            throw new Error("Failed to validate stage");
        }

    }
    async function authenticate(validatedTokens) {
        let response = await fetch('https://api.codex.lol/v1/stage/authenticate', {
            method: 'POST',
            headers: {
                'Android-Session': session,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ tokens: validatedTokens })
        });
        let data = await response.json();

        if (data.success) {
            return true;
        }
        else {
            throw new Error("Failed to authenticate");
        }
    }

    function decodeTokenData(token) {
        let data = token.split(".")[1];
        data = base64decode(data);
        return JSON.parse(data);
    }

    let stages = await getStages();
    let stagesCompleted = 0;
    while (localStorage.getItem(stages[stagesCompleted]) && stagesCompleted < stages.length) {
        stagesCompleted++;
    }
    if (stagesCompleted == stages.length) {
        return;
    }

    let validatedTokens = [];
    try {
        while (stagesCompleted < stages.length) {
            let stageId = stages[stagesCompleted].uuid;
            let initToken = await initiateStage(stageId);

            await sleep(6000);

            let tokenData = decodeTokenData(initToken);
            let referrer;
            if (tokenData.link.includes('loot-links')) {
                referrer = 'https://loot-links.com/';
            }
            else if (tokenData.link.includes('loot-link')) {
                referrer = 'https://loot-link.com/';
            }
            else {
                referrer = 'https://linkvertise.com/';
            }

            let validatedToken = await validateStage(initToken, referrer);
            validatedTokens.push({ uuid: stageId, token: validatedToken });
            notification(`${stagesCompleted + 1}/${stages.length} stages completed`, 5000);

            await sleep(1500);

            stagesCompleted++;
        }
        if (authenticate(validatedTokens)) {
            notification('Bypass success :3');
            await sleep(3000);
            window.location.reload();
        }
    }
    catch (e) {
        handleError(e);
    }
}
  
module.exports = {
    codex,
}

/***/ }),

/***/ 223:
/***/ ((module) => {

function handleError(error) {
    let errorText = error.message ? error.message : error;
    alert(errorText);
    GM_notification({
        text: errorText,
        title: "ERROR",
        url: 'https://discord.gg/eonhub',
        silent: true,
    });
    GM.openInTab('https://discord.gg/eonhub');
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

function linkvertiseSpoof(link) {
    return new Promise((resolve, reject) => {
        GM.xmlHttpRequest({
            method: "GET",
            url: link,
            headers: {
                Referer: 'https://linkvertise.com/',
            },
            onload: function (response) {
                resolve(response.responseText);
            },
            onerror: function (error) {
                reject(error);
            }
        });
    });
}

async function getTurnstileResponse() {
    let notif = setInterval(notification, 6000, 'please solve the captcha', 5000)
    let res = '';
    while (true) {
        try {
            res = turnstile.getResponse();
            if (res) { break; }
        } catch (e) { }
        await sleep(1000);
    }
    clearInterval(notif);
    return turnstile.getResponse();
}

async function getGrecaptchaResponse() {
    let notif = setInterval(notification, 6000, 'please solve the captcha', 5000)
    let res = '';
    while (true) {
        try {
            res = grecaptcha.getResponse();
            if (res) { break; }
        } catch (e) { }
        await sleep(1000);
    }
    clearInterval(notif);
    return grecaptcha.getResponse();
}

function notification(message, timeout) {
    let config = {
        text: message,
        title: "INFO",
        silent: true,
    }
    if (timeout) { config.timeout = timeout; }
    GM_notification(config);
}

function base64decode(str) {
    str = str.replace(/-/g, '+').replace(/_/g, '/');
    return atob(str);
}

module.exports = {
    handleError,
    sleep,
    linkvertiseSpoof,
    getTurnstileResponse,
    getGrecaptchaResponse,
    notification,
    base64decode,
}

/***/ })

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry need to be wrapped in an IIFE because it need to be isolated against other modules in the chunk.
(() => {
const { codex } = __webpack_require__(24);

const { sleep, notification } = __webpack_require__(223);

const { injectAds } = __webpack_require__(636);

start();

async function start() {

    if (window.location.hostname != 'keyrblx.com') {
        injectAds();
        alert('Bypassing started :3');
    }

    GM_notification({
        text: 'Do NOT touch anything. It will do it automatically.',
        title: "Alert!",
        url: 'https://discord.gg/eonhub',
        silent: true,
        timeout: 5000
    });

    await sleep(6000);

    GM_notification({
        text: `Bypass started, wait please. :3`,
        title: "Alert!",
        silent: true,
        timeout: 2000
    });

    switch (window.location.hostname) {
        case 'mobile.codex.lol': {
            await codex();
            break;
        }
        default: {
            notification('Bypass unsupported 3:');
            break;
        }
    }
}
})();

/******/ })()
;
    }
  })
