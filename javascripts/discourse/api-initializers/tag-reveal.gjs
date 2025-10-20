import { computed } from "@ember/object";
import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  // Combine theme setting with site setting to respect both limits
  const siteSettings = api.container.lookup("service:site-settings");
  const maxVisibleTags = Math.min(
    settings.max_tags_visible,
    siteSettings.max_tags_per_topic
  );

  // Parse highlighted tags from theme setting (pipe-separated)
  const highlightedTags = (settings.highlighted_tags || "")
    .split("|")
    .map((t) => t.trim().toLowerCase())
    .filter(Boolean);
  const highlightedTagsSet = new Set(highlightedTags);

  // Store topic models by ID for click handler access
  let topicModels = {};

  // Track current route context
  const router = api.container.lookup("service:router");
  let isTopicRoute = false;

  // Helper to determine if tags should be collapsed in current context
  function shouldCollapseTags() {
    if (isTopicRoute) {
      return !!settings.collapse_in_topic_view;
    }
    return true; // always collapse on list pages
  }

  // Override topic model to control visible tags based on revealTags state
  api.modifyClass(
    "model:topic",
    (Superclass) =>
      class extends Superclass {
        revealTags = false;

        init() {
          super.init(...arguments);
          topicModels[this.id] = this;
        }

        @computed("tags")
        get visibleListTags() {
          const baseTags = super.visibleListTags || [];

          // Separate highlighted tags from regular tags
          const highlightedList = [];
          const regularList = [];

          baseTags.forEach((tag) => {
            const tagName = (tag || "").toLowerCase();
            if (highlightedTagsSet.has(tagName)) {
              highlightedList.push(tag);
            } else {
              regularList.push(tag);
            }
          });

          // If collapsing is disabled in current context, or if expanded, return all tags
          if (!shouldCollapseTags() || this.revealTags) {
            return [...highlightedList, ...regularList];
          }

          // If collapsed, return highlighted + limited regular tags
          const limitedRegular = regularList.slice(0, maxVisibleTags);
          return [...highlightedList, ...limitedRegular];
        }
      }
  );

  // Add toggle button via tags HTML callback
  api.addTagsHtmlCallback(
    (topic) => {
      // Don't show toggle if collapsing is disabled in current context
      if (!shouldCollapseTags()) {
        return "";
      }

      const allTags = topic.tags || [];
      if (allTags.length === 0) {
        return "";
      }

      // Calculate effective limit (highlighted are exempt)
      const highlightedCount = allTags.filter((tag) =>
        highlightedTagsSet.has((tag || "").toLowerCase())
      ).length;
      const regularCount = allTags.length - highlightedCount;
      const effectiveLimit = highlightedCount + Math.min(regularCount, maxVisibleTags);

      // Only show toggle if there are hidden tags
      if (allTags.length <= effectiveLimit) {
        return "";
      }

      const isExpanded = topic.revealTags;
      const hiddenCount = allTags.length - effectiveLimit;
      const label = isExpanded
        ? i18n(themePrefix("js.tag_reveal.hide"))
        : i18n(themePrefix("js.tag_reveal.more_tags"), {
            count: hiddenCount,
          });

      // Build class list: base classes + optional style class
      const classList = ["discourse-tag", "ts-toggle", "reveal-tag-action"];
      if (settings.toggle_tag_style === "box") {
        classList.push("box");
      }

      return `<a class="${classList.join(" ")}" role="button" aria-expanded="${isExpanded}">${label}</a>`;
    },
    {
      priority: siteSettings.max_tags_per_topic + 1,
    }
  );

  // Handle toggle clicks via event delegation
  document.addEventListener(
    "click",
    (event) => {
      const target = event.target;
      if (!target?.matches(".reveal-tag-action")) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();

      // Find topic ID from closest topic row or topic header
      const element =
        target.closest("[data-topic-id]") ||
        document.querySelector("h1[data-topic-id]");
      const topicId = element?.dataset.topicId;
      if (!topicId) {
        return;
      }

      const topicModel = topicModels[topicId];
      if (!topicModel) {
        return;
      }

      // Toggle state and trigger re-render
      topicModel.revealTags = !topicModel.revealTags;
      topicModel.notifyPropertyChange("tags");
    },
    true
  );

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
          outline-offset: -2px;
          border-radius: 7px;
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

  // Inject highlighted tags CSS on page change and update route context
  api.onPageChange(() => {
    // Update route context
    const currentRouteName = router.currentRouteName || "";
    isTopicRoute = currentRouteName.startsWith("topic");

    // Inject highlighted tags CSS
    injectHighlightedTagsCSS();

    // Notify visible topic models to re-render tags if route context changed
    const visibleTopicIds = new Set(
      Array.from(document.querySelectorAll("[data-topic-id]"))
        .map((el) => el.dataset.topicId)
        .filter(Boolean)
    );

    visibleTopicIds.forEach((id) => {
      const model = topicModels[id];
      if (model) {
        model.notifyPropertyChange("tags");
      }
    });
  });
});
