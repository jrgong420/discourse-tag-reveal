import { schedule } from "@ember/runloop";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  // Combine theme setting with site setting to respect both limits
  const siteSettings = api.container.lookup("service:site-settings");
  const limit = Math.min(settings.max_tags_visible, siteSettings.max_tags_per_topic);

  // Parse highlighted tags from theme setting (pipe-separated)
  const highlightedTags = (settings.highlighted_tags || "")
    .split("|")
    .map((t) => t.trim().toLowerCase())
    .filter(Boolean);
  const highlightedTagsSet = new Set(highlightedTags);

  // Generate and inject dynamic CSS for highlighted tags
  function injectHighlightedTagsCSS() {
    // Remove any existing injected styles
    const existingStyle = document.getElementById("ts-highlighted-css");
    if (existingStyle) {
      existingStyle.remove();
    }

    // Only inject if we have highlighted tags configured
    if (highlightedTags.length === 0) {
      return;
    }

    // Build CSS selectors for topic rows and tag chips
    const rowSelectors = highlightedTags
      .map((tag) => `.topic-list-item.tag-${tag}`)
      .join(", ");
    const tagSelectors = highlightedTags
      .map((tag) => `.discourse-tag[data-tag-name="${tag}"]`)
      .join(", ");

    // Get selected style preset (default: left-border)
    const style = settings.highlighted_style || "left-border";

    // Generate row accent CSS based on selected style
    let rowCSS = "";
    if (style === "left-border") {
      // Minimal: left border + subtle tint + hover shadow
      rowCSS = `
        ${rowSelectors} {
          border-left: 3px solid var(--tertiary);
          background: color-mix(in srgb, var(--tertiary) 6%, transparent);
          transition: box-shadow 160ms ease;
        }
        ${rowSelectors}:hover {
          box-shadow: 0 2px 10px rgba(0, 0, 0, 0.08);
        }
      `;
    } else if (style === "outline") {
      // Crisper: outline + tint + base elevation + stronger hover tint
      rowCSS = `
        ${rowSelectors} {
          outline: 1px solid var(--tertiary);
          background: color-mix(in srgb, var(--tertiary) 5%, transparent);
          box-shadow: 0 1px 6px rgba(0, 0, 0, 0.06);
          transition: background-color 160ms ease;
        }
        ${rowSelectors}:hover {
          background: color-mix(in srgb, var(--tertiary) 8%, transparent);
        }
      `;
    } else if (style === "card") {
      // Card-like: left border + rounded + padding + stronger elevation on hover
      rowCSS = `
        ${rowSelectors} {
          border-left: 3px solid var(--tertiary);
          background: var(--tertiary-very-low);
          border-radius: var(--border-radius);
          padding-block: var(--space-2);
          box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
          transition: box-shadow 160ms ease;
        }
        ${rowSelectors}:hover {
          box-shadow: 0 3px 12px rgba(0, 0, 0, 0.10);
        }
      `;
    }

    // Tag chip accent (common across all styles)
    const chipCSS = `
      ${tagSelectors} {
        color: var(--tertiary);
        border-color: var(--tertiary);
        background: color-mix(in srgb, var(--tertiary) 12%, transparent);
        font-weight: 600;
      }
    `;

    const css = `
      /* Highlighted topic rows - ${style} style */
      ${rowCSS}

      /* Highlighted tag chips - higher contrast */
      ${chipCSS}
    `;

    const styleEl = document.createElement("style");
    styleEl.id = "ts-highlighted-css";
    styleEl.textContent = css;
    document.head.appendChild(styleEl);
  }

  // Process a single topic row to truncate tags and add toggle
  function processTopic(row) {
    // Skip if already processed
    if (row.dataset.tsProcessed) {
      return;
    }

    // Find the tags container
    const tagsContainer = row.querySelector(".discourse-tags");
    if (!tagsContainer) {
      return;
    }

    // Reorder tags by highlighted tags (if configured) BEFORE any visibility calculations
    const origTags = Array.from(tagsContainer.querySelectorAll("a.discourse-tag"));
    if (highlightedTagsSet.size > 0 && origTags.length > 1) {
      const highlightedNodes = [];
      const otherNodes = [];
      origTags.forEach((a) => {
        const name =
          a.dataset?.tagName?.toLowerCase?.() ||
          (a.textContent || "").trim().toLowerCase();
        if (highlightedTagsSet.has(name)) {
          highlightedNodes.push(a);
        } else {
          otherNodes.push(a);
        }
      });

      if (highlightedNodes.length > 0) {
        const ordered = highlightedNodes.concat(otherNodes);
        const existingSeps = Array.from(
          tagsContainer.querySelectorAll(".discourse-tags__tag-separator")
        );

        // Rebuild container: tag, sep, tag, sep, ...
        tagsContainer.innerHTML = "";
        ordered.forEach((tagEl, idx) => {
          tagsContainer.appendChild(tagEl);
          if (idx < ordered.length - 1) {
            // Reuse existing separators if available
            const sepEl = existingSeps[idx] || document.createElement("span");
            if (!existingSeps[idx]) {
              sepEl.className = "discourse-tags__tag-separator";
            }
            tagsContainer.appendChild(sepEl);
          }
        });
      }
    }

    // Get fresh tag and separator arrays after potential reordering
    const tags = Array.from(tagsContainer.querySelectorAll("a.discourse-tag"));
    const seps = Array.from(
      tagsContainer.querySelectorAll(".discourse-tags__tag-separator")
    );

    // If tags count is within limit, no need to truncate
    if (tags.length <= limit) {
      return;
    }

    // Mark as processed
    row.dataset.tsProcessed = "true";

    // Calculate hidden count
    const hiddenCount = tags.length - limit;

    // Hide tags beyond the limit and related separators
    tags.forEach((tag, index) => {
      if (index >= limit) {
        tag.classList.add("ts-hidden");
        // hide the separator before this tag (index-1)
        if (index - 1 >= 0 && seps[index - 1]) {
          seps[index - 1].classList.add("ts-hidden");
        }
      }
    });
    // Also hide separator after the last visible tag (limit - 1)
    if (seps[limit - 1]) {
      seps[limit - 1].classList.add("ts-hidden");
    }

    // Create toggle element
    const toggle = document.createElement("a");

    // Build class list: base classes + optional style class
    const classList = ["discourse-tag", "ts-toggle"];
    if (settings.toggle_tag_style === "box") {
      classList.push("box");
    }
    toggle.className = classList.join(" ");

    toggle.setAttribute("href", "#");
    toggle.setAttribute("role", "button");
    toggle.setAttribute("aria-expanded", "false");
    toggle.textContent = i18n(themePrefix("js.tag_reveal.more_tags"), {
      count: hiddenCount,
    });

    // Toggle click handler
    function handleToggle(e) {
      e.preventDefault();
      e.stopPropagation();

      const isExpanded = toggle.getAttribute("aria-expanded") === "true";

      if (isExpanded) {
        // Collapse: hide tags beyond limit and restore correct separators
        // First show all separators to recompute state cleanly
        seps.forEach((sep) => sep.classList.remove("ts-hidden"));

        tags.forEach((tag, index) => {
          if (index >= limit) {
            tag.classList.add("ts-hidden");
            if (index - 1 >= 0 && seps[index - 1]) {
              seps[index - 1].classList.add("ts-hidden");
            }
          }
        });

        if (seps[limit - 1]) {
          seps[limit - 1].classList.add("ts-hidden");
        }

        toggle.setAttribute("aria-expanded", "false");
        toggle.textContent = i18n(themePrefix("js.tag_reveal.more_tags"), {
          count: hiddenCount,
        });
      } else {
        // Expand: show all tags and separators
        tags.forEach((tag) => tag.classList.remove("ts-hidden"));
        seps.forEach((sep) => sep.classList.remove("ts-hidden"));

        toggle.setAttribute("aria-expanded", "true");
        toggle.textContent = i18n(themePrefix("js.tag_reveal.hide"));
      }
    }

    // Bind click event
    toggle.addEventListener("click", handleToggle);

    // Bind keyboard events (Enter and Space)
    toggle.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        handleToggle(e);
      }
    });

    // Insert toggle after the last visible tag
    tagsContainer.appendChild(toggle);
  }

  // Process all topic rows on the page
  function processAllTopics() {
    const topicRows = document.querySelectorAll(".topic-list-item, .latest-topic-list-item");
    topicRows.forEach((row) => {
      processTopic(row);
    });
  }

  // Process after render on each page change and (re)attach observer
  api.onPageChange(() => {
    // Disconnect existing observer to avoid duplicates
    if (observer) {
      observer.disconnect();
      observer = null;
    }

    // Reset state first
    document.querySelectorAll("[data-ts-processed]").forEach((row) => {
      delete row.dataset.tsProcessed;

      // Remove any existing toggles
      const existingToggle = row.querySelector(".ts-toggle");
      if (existingToggle) {
        existingToggle.remove();
      }

      // Unhide tags and separators
      row.querySelectorAll(".ts-hidden").forEach((el) => {
        el.classList.remove("ts-hidden");
      });
    });

    // Inject highlighted tags CSS (removes previous injection if exists)
    injectHighlightedTagsCSS();

    // After render, process current topics and observe for changes
    schedule("afterRender", () => {
      processAllTopics();
      setupObserver();
    });
  });


  // MutationObserver lifecycle (scoped and reattached per page)
  let observer = null;

  function setupObserver() {
    const containers = document.querySelectorAll(
      ".topic-list, .latest-topic-list, #list-area, #main-outlet"
    );
    if (!containers || containers.length === 0) {
      return;
    }

    observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === 1) {
            if (
              node.classList &&
              (node.classList.contains("topic-list-item") ||
                node.classList.contains("latest-topic-list-item"))
            ) {
              processTopic(node);
            }
            const topicRows =
              node.querySelectorAll &&
              node.querySelectorAll(".topic-list-item, .latest-topic-list-item");
            if (topicRows) {
              topicRows.forEach((row) => processTopic(row));
            }
          }
        });
      });
    });

    containers.forEach((el) => {
      observer.observe(el, { childList: true, subtree: true });
    });
  }
});
