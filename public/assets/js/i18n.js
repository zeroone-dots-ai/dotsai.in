/**
 * dotsai.in — Language switcher
 * EN / HI / GU — persisted via localStorage, applies to all pages
 */
(function () {
  'use strict';

  const LANGS  = ['en', 'hi', 'gu'];
  const LABELS = { en: 'EN', hi: 'हिं', gu: 'ગુ' };
  const NAMES  = { en: 'English', hi: 'हिंदी', gu: 'ગુજરાતી' };
  const KEY    = 'dotsai-lang';

  /* ── CSS ─────────────────────────────────────────────── */
  const css = `
.lang-switcher{
  display:inline-flex;align-items:center;gap:2px;
  background:rgba(255,255,255,.07);
  border:1px solid rgba(255,255,255,.13);
  border-radius:5px;padding:3px;margin-right:10px;
  flex-shrink:0;
}
.nav.on-light .lang-switcher{
  background:rgba(25,25,36,.06);
  border-color:rgba(25,25,36,.13);
}
.lang-btn{
  font-family:'Space Mono','Courier New',monospace;
  font-size:10px;font-weight:700;letter-spacing:.04em;
  padding:4px 7px;border:none;background:transparent;
  color:rgba(255,255,255,.44);cursor:pointer;
  border-radius:3px;
  transition:background 140ms ease,color 140ms ease;
  line-height:1;white-space:nowrap;
}
.nav.on-light .lang-btn{color:rgba(25,25,36,.4);}
.lang-btn:hover{color:#fff;}
.nav.on-light .lang-btn:hover{color:#191924;}
.lang-btn.is-active{
  background:rgba(255,255,255,.16);color:#fff;
}
.nav.on-light .lang-btn.is-active{
  background:rgba(25,25,36,.11);color:#191924;
}
@media(max-width:899px){.lang-switcher{display:none;}}
@media(min-width:900px){
  .nav{grid-template-columns:1fr auto auto auto !important;}
  .nav-cta{justify-self:end;}
}
`;
  const styleEl = document.createElement('style');
  styleEl.textContent = css;
  document.head.appendChild(styleEl);

  /* ── State ───────────────────────────────────────────── */
  const originals = new Map(); // el → original innerHTML

  function getLang() {
    return localStorage.getItem(KEY) || 'en';
  }

  /* ── Save originals before any mutation ─────────────── */
  function snapshot() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
      if (!originals.has(el)) originals.set(el, el.innerHTML);
    });
  }

  /* ── Apply a language ────────────────────────────────── */
  function applyLang(lang) {
    document.documentElement.lang = lang;

    if (lang === 'en') {
      originals.forEach((html, el) => { el.innerHTML = html; });
      syncButtons(lang);
      return;
    }

    fetch('/assets/i18n/' + lang + '.json?v=2')
      .then(function (r) { return r.json(); })
      .then(function (t) {
        document.querySelectorAll('[data-i18n]').forEach(function (el) {
          var k = el.getAttribute('data-i18n');
          if (t[k] !== undefined) el.innerHTML = t[k];
        });
        syncButtons(lang);
      })
      .catch(function () {
        console.warn('[i18n] Could not load translations for:', lang);
      });
  }

  /* ── Set & persist language ──────────────────────────── */
  function setLang(lang) {
    localStorage.setItem(KEY, lang);
    applyLang(lang);
  }

  /* ── Sync all switcher buttons on the page ───────────── */
  function syncButtons(lang) {
    document.querySelectorAll('.lang-btn').forEach(function (b) {
      var active = b.dataset.lang === lang;
      b.classList.toggle('is-active', active);
      b.setAttribute('aria-pressed', active ? 'true' : 'false');
    });
  }

  /* ── Build switcher widget ───────────────────────────── */
  function buildSwitcher() {
    var cur = getLang();
    var wrap = document.createElement('div');
    wrap.className = 'lang-switcher';
    wrap.setAttribute('role', 'group');
    wrap.setAttribute('aria-label', 'Change website language');

    LANGS.forEach(function (l) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'lang-btn' + (l === cur ? ' is-active' : '');
      btn.textContent = LABELS[l];
      btn.dataset.lang = l;
      btn.title = NAMES[l];
      btn.setAttribute('aria-pressed', l === cur ? 'true' : 'false');
      btn.addEventListener('click', function () { setLang(l); });
      wrap.appendChild(btn);
    });

    return wrap;
  }

  /* ── Boot ────────────────────────────────────────────── */
  document.addEventListener('DOMContentLoaded', function () {
    snapshot();

    // Inject before the Book Meet CTA in every page's nav
    var navCta = document.querySelector('.nav-cta');
    if (navCta && navCta.parentNode) {
      navCta.parentNode.insertBefore(buildSwitcher(), navCta);
    }

    var lang = getLang();
    if (lang !== 'en') applyLang(lang);
  });

}());
