# Smart RichText Quill 📝

A production-ready Flutter rich text editor and renderer package built as a zero-dependency drop-in replacement for `flutter_quill`. Designed specifically to support complex backend content payloads including mixed Markdown, authenticated network images, auto-normalized HTML anchors, and downloadable files natively.

## Features ✨

* **Full Markdown Engine:** Renders standard Markdown editing, theming, interactive tasks, blockquotes, and inline code natively.
* **The "Tabbed" Editor:** Ships with a ready-made `SrqTabEditor` providing side-by-side _Edit_ and _Preview_ tabs out of the box.
* **HTML `<a href>` Normalization:** Backend injecting raw HTML tags into the markdown? The package automatically parses them into interactive file download cards.
* **Secure Assets:** Full support for `Headers`. Safely pass dynamic HTTP tokens and UUIDs into images, PDFs, and API file downloads out of the box.
* **Built-in Handlers:** Automatic full-screen hero image previewer and robust background file downloading.
* **Custom PDF Hooking:** Wire up your app's existing PDF viewer or let the package handle downloading automatically.

## 📦 Dependencies & Architecture

This package is designed to be lean and avoids heavy monolithic dependencies. It uses several well-maintained packages to handle specific tasks:

| Package | Purpose |
|---------|---------|
| [flutter_markdown](https://pub.dev/packages/flutter_markdown) | The core rendering engine for displaying Markdown content. |
| [cached_network_image](https://pub.dev/packages/cached_network_image) | Handles secure, cached network images with support for custom HTTP headers. |
| [dio](https://pub.dev/packages/dio) | Powers the file download system and background transfer logic. |
| [path_provider](https://pub.dev/packages/path_provider) | Manages local storage paths for persistent file downloads. |
| [open_filex](https://pub.dev/packages/open_filex) | Opens downloaded files (PDF, XLSX, DOCX) in their native system applications. |
| [image_picker](https://pub.dev/packages/image_picker) | Provides the interface for users to select images and files from their device. |
| [mime](https://pub.dev/packages/mime) | Identifies file types to display the correct iconography in download cards. |
| [markdown](https://pub.dev/packages/markdown) | The underlying logic for parsing raw strings into structured Markdown tokens. |

---

## 🚀 Installation

Add it to your `pubspec.yaml`:

```yaml
dependencies:
  smart_rich_text_quill: ^1.0.2
```

---

## 📖 Complete Usage Guide

### 1. State Initialization (`SrqController`)

Since `smart_rich_text_quill` handles standard markdown payloads rather than `Quill Delta`, generating the state is incredibly straightforward.

```dart
import 'package:smart_rich_text_quill/smart_rich_text_quill.dart';

class MyEditorScreen extends StatefulWidget {
  @override
  State<MyEditorScreen> createState() => _MyEditorScreenState();
}

class _MyEditorScreenState extends State<MyEditorScreen> {
  late final SrqController _controller;

  @override
  void initState() {
    super.initState();
    // Use SrqControllerFactory to safely build a markdown-aware controller
    _controller = SrqControllerFactory.create(initialMarkdown: "**Hello** World!");
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 2. The Global Config (`SmartContentConfig`)

Before rendering any component, build a `SmartContentConfig`. This acts as the centralized glue connecting your remote API limits, authentication headers, and hooks directly into the rich text editors so you never have to deal with UI configuration drilling.

```dart
final myConfig = SmartContentConfig(
  // 1. Headers: Used for downloading images, Docs, PDFs etc.
  headers: {
    "x-unique-id": "your-uuid",
    "Authorization": "Bearer your-token",
    "x-api-key": "your-api-key",
    "Accept": "application/json",
  },
  
  // 2. Image Override: What happens when the user picks an image
  onImageUpload: (localFilePath) async {
    // 1. Upload via your own Dio / HTTP service
    // 2. Return the network URL to be injected into the markdown
    return 'https://devapi.example.com/media/uploaded-img.png';
  },

  // 3. File Override: What happens when the user attaches a file
  onFileUpload: (localFilePath) async {
     return 'https://devapi.example.com/media/uploaded-file.docx';
  },

  // (Optional) 4. Use your own PDF Viewer implementation
  pdfViewerBuilder: (context, url, headers) {
    return MyCustomAppPdfScreen(url: url, headers: headers);
  }
);
```

### 3. Widget: `SrqTabEditor` (Best fully-featured UI)

Your bread and butter UI. It immediately provides users with an "Edit" and "Preview" tab natively wired directly to your controller.

```dart
SrqTabEditor(
  controller: _controller,
  config: myConfig,
  minHeight: 250,
  maxHeight: 500, // Editor stretches dynamically
  placeholder: "Start typing...",
)
```

**Accessing Saved Content:**

When the user hits "Save" safely grab the exact Markdown formatting instantly:

```dart
String finalMarkdown = _controller.markdown;
print(finalMarkdown);
```

### 4. Widget: `SrqEditor` (Editor Only)

If you have dedicated contexts (like a floating chat bar) that only requires raw editing without the preview tabs overlay:

```dart
SrqEditor(
  controller: _controller,
  config: myConfig,
  showToolbar: true, // Auto hooks the bold, tasks, files bar
)
```

### 5. Widget: `SmartRichTextViewer` (Viewer Only)

If you're querying a history API and just need to render the document, omit the controller and inject your target raw markdown text. This renderer inherently fetches secure images & formats UI download cards automatically.

```dart
SmartRichTextViewer(
  content: backendJsonData['text'], 
  config: myConfig,
)
```

### 6. Widget: `SmartReadMore` (Truncated View)

A neat wrapper around the renderer that forcefully restricts viewing lines until the user physically interacts with the "Read More" button. 

```dart
SmartReadMore(
  content: backendJsonData['text'],
  limit: 200, // Character limit truncation
  config: myConfig,
)
```

---

## 🛠 Migrating from `flutter_quill` -> `smart_rich_text_quill`

### 1. Removing Old Dependencies
First, strip out legacy Delta formatting packages:
- Remove `flutter_quill`
- Remove `flutter_quill_extensions`
- Remove `markdown_quill` (if applicable)

### 2. State Controller Overhauls

**Old Method**:
```dart
// Legacy approach
final doc = Document.fromDelta(delta);
QuillController _controller = QuillController(
    document: doc, 
    selection: const TextSelection.collapsed(offset: 0)
);
```

**New Method**:
```dart
// Modern smart_rich_text approach
SrqController _controller = SrqControllerFactory.create(
    initialMarkdown: rawMarkdownPayload
);
```

### 3. Editor UI Swap

**Old Method (`AppQuillEditor`)**:
```dart
AppQuillEditor(
  controller: _controller,
  isPreviewMode: false,
)
```

**New Method (`SrqTabEditor`)**:
```dart
SrqTabEditor(
  controller: _controller,
  config: myAppConfig, // Handles secure tokens securely
)
```

### 4. GitHub-Style Mentions & Custom Interactive Insertions
You can easily port your legacy `HelpDesk` interactive pickers (like `CustomAutoComplete` bottom sheets) or create GitHub-style user mentions (`@user`) and issue linking (`#123`). 

The `SrqTabEditor` and `SrqEditor` optionally accept a `chipTags` list parameter. This cleanly renders action chips right above the keyboard! Using the native `insertAtCursor` capability, you can halt the editor, wait for user input from a custom popup/sheet, and natively insert the resulting Markdown format securely.

#### Step A: Build Your Picker
First, wrap your existing `CustomAutoComplete` or standard `BottomSheet` logic in a Future that returns the literal Markdown string needed:

```dart
Future<String?> _showMentionBottomSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Column(
      children: [
        ListTile(
          title: Text('John Doe'),
          onTap: () {
            // User picked John Doe! Return the exact markdown you want injected.
            Navigator.pop(ctx, '[@John Doe](https://backend.com/users/123) ');
          },
        ),
      ],
    ),
  );
}
```

#### Step B: Hook up the Chip Tag
Pass an `SrqChipTag` to the editor. The editor natively suspends styling when tapped, formats the UI, `awaits` your returning string, and securely runs `_controller.insertAtCursor(text)`.

```dart
SrqTabEditor(
  controller: _controller,
  config: myAppConfig, 
  chipTags: [
    SrqChipTag(
      label: 'Tag User',
      icon: Icons.person,
      onTap: () async {
        // Pauses here! Opens your CustomAutoComplete bottom sheet...
        String? markdownToInsert = await _showMentionBottomSheet(context);
        
        // When the bottom sheet pops, the returned string is seamlessly slotted 
        // into the exact location the blinking cursor was left at!
        return markdownToInsert; 
      }
    )
  ]
)
```
