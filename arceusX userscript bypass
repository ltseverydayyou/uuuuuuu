// ==UserScript==
// @name         Arceus X Official Bypass
// @namespace    https://greasyfork.org/en/users/1252811-idontgiveaf
// @version      Yes1.7.3
// @description  The only and offical bypass for Arceus X (by idgaf). None other will update daily. Abuses Arceus's API. ~5 seconds to do.
// @author       idontgiveaf
// @match        https://loot-link.com/s?*
// @match        https://loot-links.com/s?*
// @match        https://lootlink.org/s?*
// @match        https://lootlinks.co/s?*
// @match        https://lootdest.info/s?*
// @match        https://lootdest.org/s?*
// @match        https://lootdest.com/s?*
// @match        https://links-loot.com/s?*
// @match        https://linksloot.net/s?*
// @match        https://spdmteam.com/key-system*
// @grant        none
// @license      no copy ok
// @downloadURL https://update.greasyfork.org/scripts/489587/Arceus%20X%20Official%20Bypass.user.js
// @updateURL https://update.greasyfork.org/scripts/489587/Arceus%20X%20Official%20Bypass.meta.js
// ==/UserScript==

if (document.title == 'Just a moment...') {
  return;
}

var currentURL = window.location.href;
var newerURL = currentURL.replace('https://spdmteam.com/key-system-1?hwid=', 'https://spdmteam.com/api/keysystem?hwid=').replace('&zone=Europe/Rome', '&zone=Europe/Rome&advertiser=lootlabs&OS=ios');
var pageTitle = document.title;
var API = "https://spdmteam.com/api/keysystem?step=";
if (currentURL.includes("https://spdmteam.com/key-system-1?hwid=")) {
  window.location.replace(newerURL);
} else if (pageTitle.includes("NEO") && pageTitle.includes("1")) {
  window.location.href = API + "1&advertiser=linkvertise&OS=ios";
} else if (currentURL.includes("https://spdmteam.com/key-system-2?hwid=")) {
  window.location.replace("https://loot-link.com/s?mYit");
} else if (pageTitle.includes("NEO") && pageTitle.includes("2")) {
  window.location.replace("https://spdmteam.com/api/keysystem?step=2&advertiser=linkvertise&OS=ios");
} else if (currentURL.includes("https://spdmteam.com/key-system-3?hwid=")) {
  window.location.replace("https://loot-link.com/s?qlbU");
} else if (pageTitle.includes("NEO") && pageTitle.includes("3")) {
  window.location.replace("https://spdmteam.com/api/keysystem?step=3&advertiser=linkvertise&OS=ios");
}