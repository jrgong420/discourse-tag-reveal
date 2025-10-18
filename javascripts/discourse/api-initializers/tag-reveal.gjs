import { apiInitializer } from "discourse/lib/api";
import { i18n } from "discourse-i18n";

export default apiInitializer((api) => {
  // Use theme setting; fallback to 5 if missing
  const limit = (typeof settings !== "undefined" && Number.isInteger(settings.max_tags_per_topic))
    ? settings.max_tags_per_topic
    : 5;

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

    // Get all tag elements
    const tags = Array.from(tagsContainer.querySelectorAll("a.discourse-tag"));
    const seps = Array.from(tagsContainer.querySelectorAll(".discourse-tags__tag-separator"));

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
        // Collapse: hide tags beyond limit
        tags.forEach((tag, index) => {
          if (index >= limit) {
            tag.classList.add("ts-hidden");
          }
        });
        toggle.setAttribute("aria-expanded", "false");
        toggle.textContent = i18n(themePrefix("js.tag_reveal.more_tags"), {
          count: hiddenCount,
        });
      } else {
        // Expand: show all tags
        tags.forEach((tag) => {
          tag.classList.remove("ts-hidden");
        });
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

  // Initial processing after DOM is ready
  api.onPageChange(() => {
    // Reset state first
    document.querySelectorAll("[data-ts-processed]").forEach((row) => {
      delete row.dataset.tsProcessed;

      // Remove any existing toggles
      const existingToggle = row.querySelector(".ts-toggle");
      if (existingToggle) {
        existingToggle.remove();
      }

      // Unhide all tags
      row.querySelectorAll(".ts-hidden").forEach((tag) => {
        tag.classList.remove("ts-hidden");
      });
    });

    // Process topics after a short delay to ensure DOM is ready
    setTimeout(() => {
      processAllTopics();
    }, 100);
  });

  // Also process on initial load
  setTimeout(() => {
    processAllTopics();
  }, 100);

  // Watch for new topics added via infinite scroll
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === 1) {
          // Check if the added node is a topic row
          if (node.classList && (node.classList.contains("topic-list-item") || node.classList.contains("latest-topic-list-item"))) {
            processTopic(node);
          }
          // Also check for topic rows within the added node
          const topicRows = node.querySelectorAll && node.querySelectorAll(".topic-list-item, .latest-topic-list-item");
          if (topicRows) {
            topicRows.forEach((row) => processTopic(row));
          }
        }
      });
    });
  });

  // Observe the main content area for changes
  const targetNode = document.querySelector("#main-outlet");
  if (targetNode) {
    observer.observe(targetNode, {
      childList: true,
      subtree: true,
    });
  }
});
