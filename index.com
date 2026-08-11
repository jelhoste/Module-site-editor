<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>SiteForge — Éditeur</title>

<!-- Material Icons & Google Fonts -->
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600;700&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet"/>

<!-- SortableJS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/Sortable/1.15.2/Sortable.min.js"></script>

<style>
/* ═══════════════════════════════════════════════════════════
   TOKENS GLOBAUX — Material Design 3 + thèmes
═══════════════════════════════════════════════════════════ */
:root {
  --font-sans: 'DM Sans', sans-serif;
  --font-display: 'DM Serif Display', serif;
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 20px;
  --shadow-1: 0 1px 3px rgba(0,0,0,.12), 0 1px 2px rgba(0,0,0,.08);
  --shadow-2: 0 3px 8px rgba(0,0,0,.15), 0 2px 4px rgba(0,0,0,.10);
  --shadow-3: 0 8px 24px rgba(0,0,0,.18);
  --transition: 180ms cubic-bezier(.2,.0,.2,1);
  --container-pad: 24px;
}

/* ── Identité SiteForge : encre & laiton ──────────────────────
   Un seul système de couleurs, décliné en 3 thèmes exclusifs :
   clair (papier), sombre (encre), haut contraste (WCAG AAA).
   Plus de tokens "container" MD3 — teintes dérivées directement. */

/* ── Thème Clair ── */
[data-theme="light"] {
  --c-primary:       #194F49;   /* encre teal */
  --c-primary-cont:  #DCEBE8;
  --c-secondary:     #92652C;   /* laiton */
  --c-tertiary:      #5B4C7A;   /* violet sourdine, accents rares */
  --c-surface:       #FBFAF7;
  --c-surface-1:     #F2F0EA;
  --c-surface-2:     #E8E5DC;
  --c-surface-3:     #DEDACD;
  --c-on-surface:    #1C2023;
  --c-on-surface-v:  #52565A;
  --c-outline:       #C9C4B7;
  --c-outline-v:     #E2DFD5;
  --c-error:         #A3312A;
  --c-bg:            #F2F0EA;
}

/* ── Thème Sombre ── */
[data-theme="dark"] {
  --c-primary:       #5FBAB0;
  --c-primary-cont:  #1F5C56;
  --c-secondary:     #D9A455;
  --c-tertiary:      #A491C4;
  --c-surface:       #1A1F21;
  --c-surface-1:     #20262A;
  --c-surface-2:     #262D31;
  --c-surface-3:     #2D3539;
  --c-on-surface:    #E7E4DC;
  --c-on-surface-v:  #A9A79D;
  --c-outline:       #3C4448;
  --c-outline-v:     #2A3134;
  --c-error:         #F0938A;
  --c-bg:            #14181A;
}

/* ── Thème Haut Contraste (WCAG AAA, ≥7:1) ── */
[data-theme="hc"] {
  --c-primary:       #00453E;
  --c-primary-cont:  #FFFFFF;
  --c-secondary:     #5C3A00;
  --c-tertiary:      #2E1A5C;
  --c-surface:       #FFFFFF;
  --c-surface-1:     #F2F2F2;
  --c-surface-2:     #E5E5E5;
  --c-surface-3:     #D9D9D9;
  --c-on-surface:    #000000;
  --c-on-surface-v:  #1A1A1A;
  --c-outline:       #000000;
  --c-outline-v:     #333333;
  --c-error:         #A30000;
  --c-bg:            #FFFFFF;
}

/* ═══════════════════════════════════════════════════════════
   RESET & BASE
═══════════════════════════════════════════════════════════ */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; font-family: var(--font-sans); }
body {
  background: var(--c-bg);
  color: var(--c-on-surface);
  display: flex; flex-direction: column;
  transition: background var(--transition), color var(--transition);
}
button { font-family: var(--font-sans); cursor: pointer; border: none; outline: none; }
input, textarea, select { font-family: var(--font-sans); }
.ms { font-family: 'Material Symbols Outlined'; font-style: normal; font-weight: normal;
       line-height: 1; letter-spacing: normal; text-transform: none; white-space: nowrap;
       word-wrap: normal; direction: ltr; font-size: 20px; user-select: none; }

/* ═══════════════════════════════════════════════════════════
   TOPBAR
═══════════════════════════════════════════════════════════ */
#topbar {
  display: flex; align-items: center; gap: 4px;
  padding: 0 12px;
  height: 56px; min-height: 56px;
  background: var(--c-surface);
  border-bottom: 1px solid var(--c-outline-v);
  box-shadow: var(--shadow-1);
  z-index: 400; flex-shrink: 0;   /* nettement au-dessus des modules du canevas (navbar=100, etc.) */
  transition: background var(--transition), border-color var(--transition);
}
#topbar .brand {
  font-family: var(--font-display);
  font-size: 20px; font-weight: 400;
  color: var(--c-primary);
  margin-right: 8px; white-space: nowrap;
  flex-shrink: 0;
}
.tb-sep { width: 1px; height: 24px; background: var(--c-outline-v); margin: 0 2px; flex-shrink: 0; }
.tb-group { display: flex; align-items: center; gap: 1px; }

/* Boutons topbar — icône seule, compact */
.tb-btn {
  display: flex; align-items: center; justify-content: center; gap: 4px;
  padding: 5px 7px; border-radius: var(--radius-sm);
  font-size: 12px; font-weight: 500;
  background: transparent; color: var(--c-on-surface-v);
  transition: background var(--transition), color var(--transition);
  white-space: nowrap; position: relative;
}
.tb-btn:hover { background: var(--c-surface-2); color: var(--c-on-surface); }
.tb-btn.active { background: var(--c-primary-cont); color: var(--c-primary); }
.tb-btn .ms { font-size: 20px; }
/* Chevron des menus déroulants */
.tb-btn .tb-chevron { font-size: 14px; margin-left: -2px; }
.tb-spacer { flex: 1; }

/* Tooltip natif amélioré */
.tb-btn[title]:hover::after {
  content: attr(title);
  position: absolute; top: calc(100% + 6px); left: 50%;
  transform: translateX(-50%);
  background: #1e2128; color: #e2e5ee;
  font-size: 11px; font-weight: 500; white-space: nowrap;
  padding: 4px 8px; border-radius: 4px;
  pointer-events: none; z-index: 1000;
}

/* ── Barre de prévisualisation ── */
#preview-bar {
  display: flex; align-items: center; gap: 8px;
  padding: 0 16px;
  height: 38px; min-height: 38px;
  background: var(--c-surface-1);
  border-bottom: 1px solid var(--c-outline-v);
  flex-shrink: 0; z-index: 90;
}
.pvbar-label {
  font-size: 11px; font-weight: 600; text-transform: uppercase;
  letter-spacing: .06em; color: var(--c-on-surface-v);
  white-space: nowrap;
}
.pvbar-btns {
  display: flex; gap: 2px;
  background: var(--c-surface-2);
  border: 1px solid var(--c-outline-v);
  border-radius: 20px; padding: 2px;
}
.pvbar-btn {
  display: flex; align-items: center; gap: 5px;
  padding: 3px 12px; border-radius: 16px;
  font-size: 12px; font-weight: 500;
  color: var(--c-on-surface-v); background: transparent;
  transition: background var(--transition), color var(--transition);
  white-space: nowrap;
}
.pvbar-btn:hover { color: var(--c-on-surface); }
.pvbar-btn.active {
  background: var(--c-surface); color: var(--c-primary);
  box-shadow: 0 1px 4px rgba(0,0,0,.12);
  font-weight: 600;
}
.pvbar-btn .ms { font-size: 16px; }
.pvbar-txt { font-size: 12px; }
.pvbar-size {
  margin-left: auto;
  font-size: 11px; font-weight: 500;
  color: var(--c-on-surface-v);
  font-variant-numeric: tabular-nums;
}

/* Dropdown Menu */
.dropdown { position: relative; }
.dropdown-menu {
  position: absolute; top: calc(100% + 6px); left: 0; z-index: 999;
  background: var(--c-surface);
  border: 1px solid var(--c-outline-v);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-3);
  min-width: 200px; overflow: hidden;
  display: none;
  transition: background var(--transition);
}
.dropdown-menu.open { display: block; }
.dm-item {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 16px; font-size: 13px; font-weight: 500;
  color: var(--c-on-surface-v);
  cursor: pointer; transition: background var(--transition);
}
.dm-item:hover { background: var(--c-surface-2); color: var(--c-on-surface); }
.dm-item.active { background: var(--c-primary-cont); font-weight: 600; }
.dm-item.active .ms { color: var(--c-primary); }
.dm-item.dm-item-publish { color: var(--c-primary); font-weight: 600; }
.dm-item.dm-item-publish .ms { color: var(--c-primary); }
.dm-item.dm-item-publish:hover { background: var(--c-primary-cont); }
.dm-item .ms { font-size: 18px; color: var(--c-primary); }
.dm-sep { height: 1px; background: var(--c-outline-v); margin: 4px 0; }
.dm-title { padding: 8px 16px 4px; font-size: 11px; font-weight: 600;
             text-transform: uppercase; letter-spacing: .08em; color: var(--c-on-surface-v); }

/* ═══════════════════════════════════════════════════════════
   MAIN LAYOUT
═══════════════════════════════════════════════════════════ */
#main {
  display: flex; flex: 1;
  overflow: hidden;        /* garde le scroll général */
  min-height: 0;
  position: relative;      /* contexte pour les onglets fixed */
}

/* Permettre à la poignée toggle de dépasser, mais le body interne scrolle */
#sidebar { overflow: visible !important; }
#props-panel { overflow: hidden; }   /* hidden pour que flex-child puisse scroller */
#sidebar > *:not(#sidebar-toggle) { overflow: visible; }
#props-panel > *:not(#props-toggle) { overflow: visible; }
/* Les sections scrollables gardent leur scroll */
.sb-section { overflow-y: auto; }

/* ── Sidebar gauche ── */
#sidebar {
  width: 186px; min-width: 186px;
  background: var(--c-surface);
  border-right: 1px solid var(--c-outline-v);
  display: flex; flex-direction: column;
  overflow-y: auto; overflow-x: hidden;
  transition: background var(--transition), width 240ms cubic-bezier(.4,0,.2,1),
              min-width 240ms cubic-bezier(.4,0,.2,1), opacity 200ms;
  flex-shrink: 0;
  position: relative;
}
#sidebar.collapsed {
  width: 0 !important; min-width: 0 !important;
  overflow: hidden; opacity: 0;
}

/* Poignée de rabattement sidebar gauche — style épuré inline */
#sidebar-toggle {
  position: absolute; top: 50%; right: -12px;
  transform: translateY(-50%);
  width: 12px; height: 40px;
  background: var(--c-surface-2);
  border: 1px solid var(--c-outline);
  border-left: none;
  border-radius: 0 4px 4px 0;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; z-index: 210;
  color: var(--c-on-surface-v);
  transition: background var(--transition), color var(--transition), border-color var(--transition);
}
#sidebar-toggle:hover { background: var(--c-primary-cont); border-color: var(--c-primary); color: var(--c-primary); }
#sidebar-toggle .ms { font-size: 11px; }

/* Bouton flottant pour rouvrir la sidebar quand fermée */
#sidebar-reopen {
  position: fixed; left: 0; top: 50%;
  transform: translateY(-50%);
  width: 14px; height: 40px;
  background: var(--c-surface-2);
  border: 1px solid var(--c-outline);
  border-left: none;
  border-radius: 0 4px 4px 0;
  display: none; align-items: center; justify-content: center;
  cursor: pointer; z-index: 300;
  color: var(--c-on-surface-v);
  transition: background var(--transition), color var(--transition);
}
#sidebar-reopen:hover { background: var(--c-primary-cont); color: var(--c-primary); }
#sidebar-reopen.show { display: flex; }
#sidebar-reopen .ms { font-size: 11px; }
.sb-section { padding: 12px 8px 4px; }
.sb-title {
  font-size: 11px; font-weight: 600; text-transform: uppercase;
  letter-spacing: .08em; color: var(--c-on-surface-v);
  padding: 0 8px 6px;
}
.module-palette {
  display: grid; grid-template-columns: repeat(3, 1fr);
  gap: 4px; padding: 0 4px 8px;
}
.palette-item {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 2px; padding: 7px 2px 6px;
  border-radius: var(--radius-sm);
  background: var(--c-surface-1);
  border: 1.5px solid var(--c-outline-v);
  cursor: grab; font-size: 9px; font-weight: 600;
  color: var(--c-on-surface-v); text-align: center;
  text-transform: uppercase; letter-spacing: .03em;
  transition: background var(--transition), border-color var(--transition), transform 100ms;
  user-select: none; line-height: 1.2;
}
/* Touch — items palette cliquables/tappables */
.palette-item { touch-action: none; }
.palette-item:hover, .palette-item.touch-active {
  background: var(--c-primary-cont);
  border-color: var(--c-primary);
  color: var(--c-primary);
  transform: translateY(-1px);
  box-shadow: var(--shadow-1);
}
.palette-item .ms { font-size: 18px; }

/* Page tree */
.page-tree { padding: 0 4px 8px; }
.page-item {
  display: flex; align-items: center; gap: 6px;
  padding: 7px 8px; border-radius: var(--radius-sm);
  font-size: 13px; font-weight: 500;
  color: var(--c-on-surface-v); cursor: pointer;
  transition: background var(--transition);
}
.page-item:hover { background: var(--c-surface-2); }
.page-item.active { background: var(--c-primary-cont); color: var(--c-primary); }
.page-item .ms { font-size: 16px; }
.page-add {
  display: flex; align-items: center; gap: 6px;
  padding: 7px 8px; border-radius: var(--radius-sm);
  font-size: 12px; font-weight: 600; color: var(--c-primary);
  cursor: pointer; transition: background var(--transition);
}
.page-add:hover { background: var(--c-primary-cont); }

/* ── Canvas zone ── */
#canvas-wrap {
  flex: 1; display: flex; flex-direction: column;
  align-items: center; overflow-y: auto; overflow-x: hidden;
  background: var(--c-bg);
  padding: 24px 24px 60px;
  transition: background var(--transition);
}
#canvas-frame {
  width: 100%; max-width: 1200px;
  background: var(--c-surface);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-2);
  min-height: 600px;
  overflow: hidden;
  transition: width var(--transition), max-width var(--transition),
              background var(--transition), box-shadow var(--transition);
}
#canvas-frame.preview-tablet { max-width: 768px; }
#canvas-frame.preview-mobile { max-width: 390px; }

/* Canvas drop zone */
#canvas {
  min-height: 200px;
  padding: 0;
  position: relative;
}
#canvas.drag-over::after {
  content: '';
  position: absolute; inset: 0; z-index: 100; pointer-events: none;
  outline: 3px dashed var(--c-primary);
  outline-offset: -3px;
  background: rgba(21, 101, 192, .06);
  border-radius: var(--radius-sm);
}
.canvas-empty {
  display: flex; flex-direction: column; align-items: center;
  justify-content: center; gap: 12px;
  padding: 80px 20px; text-align: center;
  color: var(--c-on-surface-v); pointer-events: none;
}
.canvas-empty .ms { font-size: 48px; opacity: .4; }
.canvas-empty p { font-size: 15px; opacity: .6; }

/* ── Properties panel (droite) ── */
#props-panel {
  width: 280px; min-width: 280px;
  background: var(--c-surface);
  border-left: 1px solid var(--c-outline-v);
  display: flex; flex-direction: column;
  overflow-y: auto; overflow-x: hidden;
  transition: background var(--transition), width 240ms cubic-bezier(.4,0,.2,1),
              min-width 240ms cubic-bezier(.4,0,.2,1), opacity 200ms;
  flex-shrink: 0;
  position: relative;
}
#props-panel.hidden { display: none; }
#props-panel.collapsed {
  width: 0 !important; min-width: 0 !important;
  overflow: hidden; opacity: 0;
}

/* Poignée de rabattement props panel — style épuré inline */
#props-toggle {
  position: absolute; top: 50%; left: -12px;
  transform: translateY(-50%);
  width: 12px; height: 40px;
  background: var(--c-surface-2);
  border: 1px solid var(--c-outline);
  border-right: none;
  border-radius: 4px 0 0 4px;
  display: flex; align-items: center; justify-content: center;
  cursor: pointer; z-index: 210;
  color: var(--c-on-surface-v);
  transition: background var(--transition), color var(--transition), border-color var(--transition);
}
#props-toggle:hover { background: var(--c-primary-cont); border-color: var(--c-primary); color: var(--c-primary); }
#props-toggle .ms { font-size: 11px; }

/* Bouton flottant pour rouvrir le panel quand fermé */
#props-reopen {
  position: fixed; right: 0; top: 50%;
  transform: translateY(-50%);
  width: 14px; height: 40px;
  background: var(--c-surface-2);
  border: 1px solid var(--c-outline);
  border-right: none;
  border-radius: 4px 0 0 4px;
  display: none; align-items: center; justify-content: center;
  cursor: pointer; z-index: 300;
  color: var(--c-on-surface-v);
  transition: background var(--transition), color var(--transition);
}
#props-reopen:hover { background: var(--c-primary-cont); color: var(--c-primary); }
#props-reopen.show { display: flex; }
#props-reopen .ms { font-size: 11px; }
.pp-sep { height: 1px; background: var(--c-outline-v); margin: 8px 0; }
.pp-hint { font-size: 11px; color: var(--c-on-surface-v); line-height: 1.5; }
.pp-check-row { display: flex; align-items: center; gap: 8px; cursor: pointer; font-size: 13px; }
.pp-slider-val { text-align: right; font-size: 11px; color: var(--c-on-surface-v); margin-top: 2px; }

/* Toolbar lien inline flottant */
#inline-link-bar {
  position: fixed; z-index: 500;
  display: none; align-items: center; gap: 4px;
  background: #1e2128;
  border-radius: 8px; padding: 5px 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,.32), 0 0 0 1px rgba(255,255,255,.06);
  color: #fff; font-size: 12px; white-space: nowrap;
}
#inline-link-bar.show { display: flex; }
#inline-link-bar select {
  background: rgba(255,255,255,.1); border: 1px solid rgba(255,255,255,.15);
  border-radius: 5px; color: #fff; padding: 3px 5px; font-size: 11px;
  max-width: 100px; outline: none; cursor: pointer;
}
#inline-link-bar select option { background: #1e2128; color: #fff; }
#inline-link-bar input[type="url"] { display: none; } /* caché, géré dans le popup */

/* Popup lien */
#ilb-link-popup {
  position: fixed; z-index: 501;
  display: none;
  flex-direction: column; gap: 6px;
  background: #1e2128;
  border-radius: 10px; padding: 10px;
  box-shadow: 0 6px 24px rgba(0,0,0,.4), 0 0 0 1px rgba(255,255,255,.07);
  min-width: 240px;
}
#ilb-link-popup.show { display: flex; }
.ilp-row { display: flex; align-items: center; gap: 6px; }
.ilp-row input[type="url"] {
  flex: 1; background: rgba(255,255,255,.1);
  border: 1px solid rgba(255,255,255,.15);
  border-radius: 5px; color: #fff; padding: 5px 8px; font-size: 12px; outline: none;
}
.ilp-row input[type="url"]::placeholder { color: rgba(255,255,255,.4); }
.ilp-apply {
  width: 28px; height: 28px; border-radius: 6px; flex-shrink: 0;
  background: var(--c-primary); color: #fff;
  display: flex; align-items: center; justify-content: center; border: none; cursor: pointer;
}
.ilp-apply .ms { font-size: 16px; }
.ilp-sep { height: 1px; background: rgba(255,255,255,.1); margin: 2px 0; }
.ilp-label { font-size: 10px; font-weight: 700; text-transform: uppercase;
  letter-spacing: .06em; color: rgba(255,255,255,.45); padding: 0 2px; }
.ilp-page-btn {
  display: flex; align-items: center; gap: 8px;
  width: 100%; padding: 7px 8px; border-radius: 6px;
  background: transparent; color: rgba(255,255,255,.8);
  font-size: 12px; text-align: left; border: none; cursor: pointer;
  transition: background 100ms;
}
.ilp-page-btn:hover { background: rgba(255,255,255,.12); color: #fff; }
.ilp-page-btn .ms { font-size: 14px; opacity: .6; flex-shrink: 0; }
#inline-link-bar input[type="number"] {
  background: transparent; border: none;
  color: #fff; padding: 2px 0; font-size: 12px;
  width: 34px; outline: none; text-align: center;
}
#inline-link-bar input::placeholder { color: rgba(255,255,255,.4); }
#inline-link-bar input:focus { border-color: rgba(255,255,255,.4); }
.ilb-btn {
  width: 26px; height: 26px; border-radius: 4px; background: transparent;
  color: rgba(255,255,255,.75); display: flex; align-items: center; justify-content: center;
  flex-shrink: 0; transition: background 100ms, color 100ms;
}
.ilb-btn:hover { background: rgba(255,255,255,.16); color: #fff; }
.ilb-btn.active { background: rgba(255,255,255,.22); color: #fff; }
.ilb-btn .ms { font-size: 15px; line-height: 1; }
.ilb-sep { width: 1px; height: 16px; background: rgba(255,255,255,.18); margin: 0 2px; flex-shrink: 0; }
/* Lien de bloc - visuellement transparent dans l'éditeur */
.block-link-wrap { display: contents; }
.mod-content a[data-block-link] { color: inherit; text-decoration: none; display: block; }

/* ── Module Partition (Sheet) — couleurs fixes (identiques light/dark) ── */
.mod-sheet { padding: 0
