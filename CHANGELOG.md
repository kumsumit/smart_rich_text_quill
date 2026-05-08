## 1.0.8

* Fix: Improved file type detection by checking both the URL and the link text (filename). This ensures reports like "Annual leave handover report.pdf" correctly trigger download/view actions even if the URL is a generic asset path.
* Fix: Restored opening behavior for standard `https` links that are not organizational chips.

## 1.0.7

* Fix: Resolved issue where "Mention Chips" (links containing `/goto/` or internal relative paths) were incorrectly triggering file download dialogs.
* Fix: Improved classification logic to ensure standard file downloads still work while keeping organizational tags silent as requested.

## 1.0.5 (Merged 1.0.6)
* Fix: Updated `file_picker` dependency to `^10.3.2` to resolve version conflicts with parent mobile applications.

* Feature: Switched to `file_picker` for generic file uploads.
* Feature: Added automatic filtering in file picker to exclude images and restrict to `pdf`, `doc`, `docx`, `xls`, and `xlsx`.
* Fix: Improved image URL detection to handle URLs with query parameters or complex structures, ensuring they correctly open in the image viewer.
* Fix: Refined "mention/chip" link logic to ensure standard file links still trigger appropriate actions while purely organizational links remain view-only.

## 1.0.3
* Feature: Added a date picker and time picker dialog to the editor's toolbar (`isNeedTimeCl` flag). Dates are inserted as visually highlighted, view-only blue text within the preview.

* Feature: Added basic syntax highlighting support in edit mode for markdown styles like `**bold**`, `*italic*`,  `~~strike~~`, and \`code\`.
* Feature: Added auto-list numbering continuation behavior in editor for ordered lists, bulleted lists, and blockquotes upon pressing Return.
* Fix: Prevented default download dialogue from showing when user taps on regular web links like chip-style tags in the markdown preview.

## 1.0.2

* Initial release.
* Adds `SmartRichTextViewer` for decoupled markdown rendering.
* Adds Image fetching with `headers` payload support.
* Introduces file download and PDF hooks.
* Incorporates inline editing and generic markdown components.
