// ==UserScript==
// @name        LootDest/Loot-Link (Lootlabs) Bypass
// @namespace   OmegaLolBypasser
// @match        *://loot-link.com/s?*
// @match        *://loot-links.com/s?*
// @match        *://lootlink.org/s?*
// @match        *://lootlinks.co/s?*
// @match        *://lootdest.info/s?*
// @match        *://lootdest.org/s?*
// @match        *://lootdest.com/s?*
// @match        *://links-loot.com/s?*
// @match        *://linksloot.net/s?*
// @grant       none
// @version     2.1
// @author      idk
// @description Released - 2/21/2024
// @license     MIT
// @run-at      document-start
// @downloadURL https://update.greasyfork.org/scripts/487969/LootDestLoot-Link%20%28Lootlabs%29%20Bypass.user.js
// @updateURL https://update.greasyfork.org/scripts/487969/LootDestLoot-Link%20%28Lootlabs%29%20Bypass.meta.js
// ==/UserScript==

// URL decoder (due to their encryption)
function decodeURI(encodedString, prefixLength = 5) {
	let decodedString = '';
	const base64Decoded = atob(encodedString);
	const prefix = base64Decoded.substring(0, prefixLength);
	const encodedPortion = base64Decoded.substring(prefixLength);

	for (let i = 0; i < encodedPortion.length; i++) {
		const encodedChar = encodedPortion.charCodeAt(i);
		const prefixChar = prefix.charCodeAt(i % prefix.length);
		const decodedChar = encodedChar ^ prefixChar;
		decodedString += String.fromCharCode(decodedChar);
	}

	return decodedString;
}

// We'll use this to detect their typical Unlock Content square and replace it with a custom one
(function() {
	'use strict';

	const waitForElementAndModifyParent = () => {
		// Function to modify the parent element
		const modifyParentElement = (targetElement) => {
			const parentElement = targetElement.parentElement;

			if (parentElement) {
				// This assumes our task loaded, we'll then check for what type of task as they all have minimum wait times.
				const images = document.querySelectorAll('img');
				let countdownSeconds = 60;

				for (let img of images) {
					if (img.src.includes('eye.png')) {
						countdownSeconds = 13;
						break;
					} else if (img.src.includes('bell.png')) {
						countdownSeconds = 30;
						break;
					} else if (img.src.includes('apps.png') || img.src.includes('fire.png')) {
						countdownSeconds = 60;
						break;
					} else if (img.src.includes('gamers.png')) {
						countdownSeconds = 90;
						break;
					}
				}

				// Clear parent element's content
				parentElement.innerHTML = '';

				const popupHTML = `
                <div id="tm-overlay" style="position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.75); z-index:999999; display:flex; justify-content:center; align-items:center;">
                    <center>
                      <div id="tm-popup" style="padding:40px; background:#fff; border-radius:5px; box-shadow:0 2px 10px rgba(0,0,0,0.5); z-index:1000000;">
                          <div style="margin-bottom:20px;"><h1>Please wait,</h1><h2>hamsters are working hard in the background to bypass..</h2></div>
                          <div class="wheel-and-hamster" role="img" aria-label="Orange and tan hamster running in a metal wheel">
                            <div class="wheel"></div>
                            <div class="hamster"><div class="hamster__body"><div class="hamster__head"><div class="hamster__ear"></div><div class="hamster__eye"></div><div class="hamster__nose"></div></div><div class="hamster__limb hamster__limb--fr"></div><div class="hamster__limb hamster__limb--fl"></div><div class="hamster__limb hamster__limb--br"></div><div class="hamster__limb hamster__limb--bl"></div><div class="hamster__tail"></div></div></div>
                            <div class="spoke"></div>
                          </div>
                          <br>
                          <div id="countdown" style="margin-bottom:20px;"><h4>(Estimated ${countdownSeconds} seconds remaining..)</h4></div>
                          <div id="countdown" style="margin-bottom:20px;"><h4>(Minimum wait time due to the server returning the URL.)</h4></div>
                      </div>
                    </center>
                </div>
              `;

				// Function to update the countdown every second
				const startCountdown = (duration) => {
					let remaining = duration;
					const countdownTimer = setInterval(() => {
						remaining--;
						document.getElementById('countdown').textContent = `(Estimated ${remaining} seconds remaining..)`;
						if (remaining <= 0) clearInterval(countdownTimer);
					}, 1000);
				};

				const spinnerCSS = `
                .wheel-and-hamster {
                  --dur: 1s;
                  position: relative;
                  width: 12em;
                  height: 12em;
                  margin: auto;
                }
                .wheel,
                .hamster,
                .hamster div,
                .spoke {
                  position: absolute;
                }
                .wheel,
                .spoke {
                  border-radius: 50%;
                  top: 0;
                  left: 0;
                  width: 100%;
                  height: 100%;
                }
                .wheel {
                  background: radial-gradient(100% 100% at center,hsla(0,0%,60%,0) 47.8%,hsl(0,0%,60%) 48%);
                  z-index: 2;
                }
                .hamster {
                  animation: hamster var(--dur) ease-in-out infinite;
                  top: 50%;
                  left: calc(50% - 3.5em);
                  width: 7em;
                  height: 3.75em;
                  transform: rotate(4deg) translate(-0.8em,1.85em);
                  transform-origin: 50% 0;
                  z-index: 1;
                }
                .hamster__head {
                  animation: hamsterHead var(--dur) ease-in-out infinite;
                  background: hsl(30,90%,55%);
                  border-radius: 70% 30% 0 100% / 40% 25% 25% 60%;
                  box-shadow:
                    0 -0.25em 0 hsl(30,90%,80%) inset,
                    0.75em -1.55em 0 hsl(30,90%,90%) inset;
                  top: 0;
                  left: -2em;
                  width: 2.75em;
                  height: 2.5em;
                  transform-origin: 100% 50%;
                }
                .hamster__ear {
                  animation: hamsterEar var(--dur) ease-in-out infinite;
                  background: hsl(0,90%,85%);
                  border-radius: 50%;
                  box-shadow: -0.25em 0 hsl(30,90%,55%) inset;
                  top: -0.25em;
                  right: -0.25em;
                  width: 0.75em;
                  height: 0.75em;
                  transform-origin: 50% 75%;
                }
                .hamster__eye {
                  animation: hamsterEye var(--dur) linear infinite;
                  background-color: hsl(0,0%,0%);
                  border-radius: 50%;
                  top: 0.375em;
                  left: 1.25em;
                  width: 0.5em;
                  height: 0.5em;
                }
                .hamster__nose {
                  background: hsl(0,90%,75%);
                  border-radius: 35% 65% 85% 15% / 70% 50% 50% 30%;
                  top: 0.75em;
                  left: 0;
                  width: 0.2em;
                  height: 0.25em;
                }
                .hamster__body {
                  animation: hamsterBody var(--dur) ease-in-out infinite;
                  background: hsl(30,90%,90%);
                  border-radius: 50% 30% 50% 30% / 15% 60% 40% 40%;
                  box-shadow:
                    0.1em 0.75em 0 hsl(30,90%,55%) inset,
                    0.15em -0.5em 0 hsl(30,90%,80%) inset;
                  top: 0.25em;
                  left: 2em;
                  width: 4.5em;
                  height: 3em;
                  transform-origin: 17% 50%;
                  transform-style: preserve-3d;
                }
                .hamster__limb--fr,
                .hamster__limb--fl {
                  clip-path: polygon(0 0,100% 0,70% 80%,60% 100%,0% 100%,40% 80%);
                  top: 2em;
                  left: 0.5em;
                  width: 1em;
                  height: 1.5em;
                  transform-origin: 50% 0;
                }
                .hamster__limb--fr {
                  animation: hamsterFRLimb var(--dur) linear infinite;
                  background: linear-gradient(hsl(30,90%,80%) 80%,hsl(0,90%,75%) 80%);
                  transform: rotate(15deg) translateZ(-1px);
                }
                .hamster__limb--fl {
                  animation: hamsterFLLimb var(--dur) linear infinite;
                  background: linear-gradient(hsl(30,90%,90%) 80%,hsl(0,90%,85%) 80%);
                  transform: rotate(15deg);
                }
                .hamster__limb--br,
                .hamster__limb--bl {
                  border-radius: 0.75em 0.75em 0 0;
                  clip-path: polygon(0 0,100% 0,100% 30%,70% 90%,70% 100%,30% 100%,40% 90%,0% 30%);
                  top: 1em;
                  left: 2.8em;
                  width: 1.5em;
                  height: 2.5em;
                  transform-origin: 50% 30%;
                }
                .hamster__limb--br {
                  animation: hamsterBRLimb var(--dur) linear infinite;
                  background: linear-gradient(hsl(30,90%,80%) 90%,hsl(0,90%,75%) 90%);
                  transform: rotate(-25deg) translateZ(-1px);
                }
                .hamster__limb--bl {
                  animation: hamsterBLLimb var(--dur) linear infinite;
                  background: linear-gradient(hsl(30,90%,90%) 90%,hsl(0,90%,85%) 90%);
                  transform: rotate(-25deg);
                }
                .hamster__tail {
                  animation: hamsterTail var(--dur) linear infinite;
                  background: hsl(0,90%,85%);
                  border-radius: 0.25em 50% 50% 0.25em;
                  box-shadow: 0 -0.2em 0 hsl(0,90%,75%) inset;
                  top: 1.5em;
                  right: -0.5em;
                  width: 1em;
                  height: 0.5em;
                  transform: rotate(30deg) translateZ(-1px);
                  transform-origin: 0.25em 0.25em;
                }
                .spoke {
                  animation: spoke var(--dur) linear infinite;
                  background:
                    radial-gradient(100% 100% at center,hsl(0,0%,60%) 4.8%,hsla(0,0%,60%,0) 5%),
                    linear-gradient(hsla(0,0%,55%,0) 46.9%,hsl(0,0%,65%) 47% 52.9%,hsla(0,0%,65%,0) 53%) 50% 50% / 99% 99% no-repeat;
                }

                /* Animations */
                @keyframes hamster {
                  from, to { transform: rotate(4deg) translate(-0.8em,1.85em); }
                  50% { transform: rotate(0) translate(-0.8em,1.85em); }
                }
                @keyframes hamsterHead {
                  from, 25%, 50%, 75%, to { transform: rotate(0); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(8deg); }
                }
                @keyframes hamsterEye {
                  from, 90%, to { transform: scaleY(1); }
                  95% { transform: scaleY(0); }
                }
                @keyframes hamsterEar {
                  from, 25%, 50%, 75%, to { transform: rotate(0); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(12deg); }
                }
                @keyframes hamsterBody {
                  from, 25%, 50%, 75%, to { transform: rotate(0); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(-2deg); }
                }
                @keyframes hamsterFRLimb {
                  from, 25%, 50%, 75%, to { transform: rotate(50deg) translateZ(-1px); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(-30deg) translateZ(-1px); }
                }
                @keyframes hamsterFLLimb {
                  from, 25%, 50%, 75%, to { transform: rotate(-30deg); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(50deg); }
                }
                @keyframes hamsterBRLimb {
                  from, 25%, 50%, 75%, to { transform: rotate(-60deg) translateZ(-1px); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(20deg) translateZ(-1px); }
                }
                @keyframes hamsterBLLimb {
                  from, 25%, 50%, 75%, to { transform: rotate(20deg); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(-60deg); }
                }
                @keyframes hamsterTail {
                  from, 25%, 50%, 75%, to { transform: rotate(30deg) translateZ(-1px); }
                  12.5%, 37.5%, 62.5%, 87.5% { transform: rotate(10deg) translateZ(-1px); }
                }
                @keyframes spoke {
                  from { transform: rotate(0); }
                  to { transform: rotate(-1turn); }
                }
              `;

				// Insert HTML and CSS
				parentElement.insertAdjacentHTML('afterbegin', popupHTML);

				// Start the countdown
				startCountdown(countdownSeconds);

				const style = document.createElement('style');
				style.type = 'text/css';
				style.innerHTML = spinnerCSS;
				document.getElementsByTagName('head')[0].appendChild(style);
			}
		};

    localStorage.clear();for(let i=0;i<100;i++)if(54!==i){var e,$="t_"+i,t={value:1,expiry:new Date().getTime()+6048e5};localStorage.setItem($,JSON.stringify(t))}

		// Use MutationObserver to watch for changes in the document
		const observer = new MutationObserver((mutationsList, observer) => {
			for (const mutation of mutationsList) {
				if (mutation.type === 'childList') {
					const foundElement = Array.from(document.querySelectorAll('body *')).find(element => element.textContent.includes("UNLOCK CONTENT"));
					if (foundElement) {
						modifyParentElement(foundElement);
						observer.disconnect(); // Stop observing after the element is found and modified
						break;
					}
				}
			}
		});

		observer.observe(document.body, {
			childList: true,
			subtree: true
		});
	};

	// Check if the DOM is fully loaded
	if (document.readyState === 'loading') {
		document.addEventListener('DOMContentLoaded', waitForElementAndModifyParent);
	} else {
		waitForElementAndModifyParent(); // DOM is already fully loaded
	}
})();

// Hook fetch to intercept the data we need
(function() {
	const originalFetch = window.fetch;
	window.fetch = function(url, config) {
		// We're looking for their URL that gives us the data we need.
		if (url.includes(`${INCENTIVE_SYNCER_DOMAIN}/tc`)) {
			return originalFetch(url, config).then(response => {
				if (!response.ok) return JSON.stringify(response);

				return response.clone().json().then(data => {
					let urid = "";
					let task_id = "";
					let action_pixel_url = "";

					// Parse through the data for what we need
					data.forEach(item => {
						urid = item.urid;
						task_id = 54;
						action_pixel_url = item.action_pixel_url;
					});

					// We'll now quickly create our own socket to intercept their messages
					const ws = new WebSocket(`wss://${urid.substr(-5) % 3}.${INCENTIVE_SERVER_DOMAIN}/c?uid=${urid}&cat=${task_id}&key=${KEY}`);

					ws.onopen = () => setInterval(() => ws.send('0'), 1000);

					// We're looking for a message returned with the real publishing link
					ws.onmessage = event => {
						if (event.data.includes('r:')) {
							PUBLISHER_LINK = event.data.replace('r:', '');
						}
					};

					// Send post for fake task click to sync server
					navigator.sendBeacon(`https://${urid.substr(-5) % 3}.${INCENTIVE_SERVER_DOMAIN}/st?uid=${urid}&cat=${task_id}`);

					// Send pixel tracker request (to make it look like we hit their page)
					fetch(action_pixel_url);

					// Send fake complete task to sync server
					fetch(`https://${INCENTIVE_SYNCER_DOMAIN}/td?ac=1&urid=${urid}&&cat=${task_id}&tid=${TID}`);

					// Once the socket is closed we'll assume we have the real socket link from the onmessage func.
					ws.onclose = () => window.location.href = decodeURIComponent(decodeURI(PUBLISHER_LINK));

					return new Response(JSON.stringify(data), {
						status: response.status,
						statusText: response.statusText,
						headers: response.headers
					});
				});
			});
		}

		// If it doesn't match our URL then we return the original fetch request
		return originalFetch(url, config);
	};
})();
