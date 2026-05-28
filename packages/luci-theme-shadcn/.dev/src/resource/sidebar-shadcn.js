"use strict";
"require baseclass";

const THEME_KEY = "shadcn.theme";
const SIDEBAR_KEY = "shadcn.sidebar";

return baseclass.extend({
  __init__() {
    this.initTheme();
    this.initSidebar();
    this.initMobileDrawer();
    this.initThemeToggle();
  },

  /* ── Theme ── */

  initTheme() {
    const saved = localStorage.getItem(THEME_KEY) || "device";
    this.applyTheme(saved);
  },

  applyTheme(theme) {
    const isDark =
      theme === "dark" ||
      (theme === "device" &&
        window.matchMedia("(prefers-color-scheme: dark)").matches);
    document.documentElement.setAttribute("data-darkmode", isDark);
    localStorage.setItem(THEME_KEY, theme);
    this._updateThemeIcon(isDark);
  },

  _updateThemeIcon(isDark) {
    const btn = document.getElementById("theme-toggle-btn");
    if (!btn) return;
    const img = btn.querySelector("img");
    if (!img) return;
    const media =
      document.documentElement.getAttribute("data-shadcn-media") ||
      "/luci-static/shadcn";
    const base = String(media).replace(/\/$/, "");
    img.src = base + (isDark ? "/icons/moon.svg" : "/icons/sun.svg");
  },

  initThemeToggle() {
    const btn = document.getElementById("theme-toggle-btn");
    if (!btn) return;
    btn.addEventListener("click", () => {
      const isDark = document.documentElement.getAttribute("data-darkmode") === "true";
      this.applyTheme(isDark ? "light" : "dark");
    });
    window
      .matchMedia("(prefers-color-scheme: dark)")
      .addEventListener("change", () => {
        if ((localStorage.getItem(THEME_KEY) || "device") === "device") {
          this.applyTheme("device");
        }
      });
  },

  /* ── Sidebar collapse (desktop icon rail) ── */

  initSidebar() {
    const sidebar = document.getElementById("sidebar");
    if (!sidebar) return;

    const collapsed = localStorage.getItem(SIDEBAR_KEY) === "true";
    sidebar.setAttribute("data-collapsed", collapsed);

    const toggleBtn = document.getElementById("sidebar-toggle-btn");
    if (toggleBtn) {
      toggleBtn.addEventListener("click", () => this.toggleCollapse());
    }

    this._initAccordion();
  },

  toggleCollapse() {
    const sidebar = document.getElementById("sidebar");
    if (!sidebar) return;
    const next = sidebar.getAttribute("data-collapsed") !== "true";
    sidebar.setAttribute("data-collapsed", next);
    localStorage.setItem(SIDEBAR_KEY, next);

    if (next) {
      document.querySelectorAll(".sidebar-accordion-item[data-open='true']").forEach((item) => {
        this._closeAccordionItem(item);
      });
    }
  },

  /* ── Accordion ── */

  _initAccordion() {
    document.addEventListener("click", (e) => {
      const trigger = e.target.closest(".sidebar-nav-parent");
      if (!trigger) return;

      const sidebar = document.getElementById("sidebar");
      if (sidebar?.getAttribute("data-collapsed") === "true") return;

      const item = trigger.closest(".sidebar-accordion-item");
      if (!item) return;

      const isOpen = item.getAttribute("data-open") === "true";

      document.querySelectorAll(".sidebar-accordion-item[data-open='true']").forEach((other) => {
        if (other !== item) this._closeAccordionItem(other);
      });

      if (isOpen) {
        this._closeAccordionItem(item);
      } else {
        this._openAccordionItem(item);
      }
    });
  },

  _openAccordionItem(item) {
    const sub = item.querySelector(".sidebar-accordion-sub");
    if (!sub) return;
    item.setAttribute("data-open", "true");
    sub.style.maxHeight = sub.scrollHeight + "px";
  },

  _closeAccordionItem(item) {
    const sub = item.querySelector(".sidebar-accordion-sub");
    if (!sub) return;
    item.setAttribute("data-open", "false");
    sub.style.maxHeight = "0";
  },

  /* ── Mobile drawer ── */

  initMobileDrawer() {
    const hamburger = document.getElementById("sidebar-hamburger");
    const overlay = document.getElementById("sidebar-overlay");

    if (hamburger) {
      hamburger.addEventListener("click", () => this.openDrawer());
    }
    if (overlay) {
      overlay.addEventListener("click", () => this.closeDrawer());
    }

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") this.closeDrawer();
    });
  },

  openDrawer() {
    const sidebar = document.getElementById("sidebar");
    const overlay = document.getElementById("sidebar-overlay");
    if (!sidebar) return;
    sidebar.setAttribute("data-drawer-open", "true");
    overlay?.classList.add("active");
    document.body.style.overflow = "hidden";
  },

  closeDrawer() {
    const sidebar = document.getElementById("sidebar");
    const overlay = document.getElementById("sidebar-overlay");
    if (!sidebar) return;
    sidebar.setAttribute("data-drawer-open", "false");
    overlay?.classList.remove("active");
    document.body.style.overflow = "";
  },
});
