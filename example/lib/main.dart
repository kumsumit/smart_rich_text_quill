import 'package:flutter/material.dart';
import 'package:smart_rich_text_quill/smart_rich_text_quill.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Rich Text Editor Gallery',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      home: const GalleryScreen(),
    );
  }
}

const String dummyBackendData = '''**its abold text**
## Its a heading
*its a italic*
~~dfdf its a strike~~

***
a line

> a blockqoute 1
> a blockqoute 2
* its unorderd list 1
* ul 2
* ul3

Normal text
1. Orderd list
2. ol1
3. ol2

Now tasks 
* [ ] Clean bathroom
* [ ] off fan
* [ ] on light

Image
![23.Team Configuration Page.png](https://devapi.smarttadbeer.ae/help-desk/request/media/assets/69da5781b9a669937a5519e2)

xls
 
📝<a href="https://devapi.smarttadbeer.ae/help-desk/request/media/assets/69da5893b9a669937a551adf?ext=xlsx" target="_blank" download="dw list ( not exist )-.xlsx" rel="noopener noreferrer"><strong>dw list ( not exist )-.xlsx</strong></a>

📕<a href="https://devapi.smarttadbeer.ae/help-desk/request/media/assets/69da58a4b9a669937a551ae0?ext=pdf" target="_blank" download="Runaway report-form (1).pdf" rel="noopener noreferrer"><strong>Runaway report-form (1).pdf</strong></a>

[test.zip](url)[test.zip](url)
                
📃<a href="https://devapi.smarttadbeer.ae/help-desk/request/media/assets/69da596eb9a669937a551b13?ext=docx" target="_blank" download="Contract No.docx" rel="noopener noreferrer"><strong>Contract No.docx</strong></a>
''';

// Provide mock headers if using a protected API
final SmartContentConfig mockConfig = SmartContentConfig(
  headers: {
    "mobile-uuid": "mock",
    "mobile-token": "mock",
    "ess-app-key": "mock",
    "Accept": "application/json",
  },
  onImageUpload: (localPath) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/mock-inserted-img.png';
  },
  onFileUpload: (localPath) async {
    await Future.delayed(const Duration(seconds: 1));
    return 'https://example.com/mock-file.pdf?ext=pdf';
  },
);

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _GalleryItem(
        title: 'Tabbed Editor & Preview',
        subtitle: 'Edit + Preview tabs with a save action',
        icon: Icons.tab,
        page: const TabbedEditorScreen(),
      ),
      _GalleryItem(
        title: 'Pure Viewer (Read-only)',
        subtitle: 'Only renders the markdown output',
        icon: Icons.chrome_reader_mode,
        page: const ViewerOnlyScreen(),
      ),
      _GalleryItem(
        title: 'Pure Editor (No tabs)',
        subtitle: 'Standalone text entry without preview',
        icon: Icons.edit_document,
        page: const EditorOnlyScreen(),
      ),
      _GalleryItem(
        title: 'Read More Truncation',
        subtitle: 'Limits view size for heavy text',
        icon: Icons.read_more,
        page: const ReadMoreScreen(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Package Gallery'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item.page),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 36,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GalleryItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;

  _GalleryItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
  });
}

// =======================================================================
// 1. Tabbed Editor Screen
// =======================================================================
class TabbedEditorScreen extends StatefulWidget {
  const TabbedEditorScreen({super.key});

  @override
  State<TabbedEditorScreen> createState() => _TabbedEditorScreenState();
}

class _TabbedEditorScreenState extends State<TabbedEditorScreen> {
  late final SrqController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SrqControllerFactory.create(
      initialMarkdown: dummyBackendData,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveContent() {
    final text = _controller.markdown;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saved Markdown'),
        content: SingleChildScrollView(
          child: Text(text, style: const TextStyle(fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showMentionBottomSheet(BuildContext context, String title) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (c, i) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text('\${i + 1}'),
                  ),
                  title: Text('John Doe \${i + 1}'),
                  subtitle: Text('Developer'),
                  onTap: () {
                    // Returns the formatted markdown string directly to the chip handler
                    Navigator.pop(ctx, '[@John Doe \${i + 1}](https://example.com/user/\${i + 1}) ');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabbed Editor'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveContent),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SrqTabEditor(
            controller: _controller,
            config: mockConfig,
            minHeight: 200,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            chipTags: [
              SrqChipTag(
                label: 'Tag Users',
                icon: Icons.person,
                onTap: () async {
                  // Opens bottom sheet, waits for user selection, then inserts it automatically
                  return await _showMentionBottomSheet(context, 'User');
                },
              ),
              SrqChipTag(
                label: 'Insert Task',
                icon: Icons.check_box_outlined,
                onTap: () async {
                  return "\n* [ ] New task...\n";
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// 2. Viewer Only Screen
// =======================================================================
class ViewerOnlyScreen extends StatelessWidget {
  const ViewerOnlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Read Only Viewer')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SmartRichTextViewer(
              content: dummyBackendData,
              config: mockConfig,
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// 3. Editor Only Screen
// =======================================================================
class EditorOnlyScreen extends StatefulWidget {
  const EditorOnlyScreen({super.key});

  @override
  State<EditorOnlyScreen> createState() => _EditorOnlyScreenState();
}

class _EditorOnlyScreenState extends State<EditorOnlyScreen> {
  late final SrqController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SrqControllerFactory.create(
      initialMarkdown: dummyBackendData,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _showMentionBottomSheet(BuildContext context, String title) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.6,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (c, i) => ListTile(
                  leading: const Icon(Icons.bug_report, color: Colors.red),
                  title: Text('Layout Overflow #\${100 + i}'),
                  onTap: () {
                    Navigator.pop(ctx, '[#\${100 + i}](https://example.com/issues/\${100 + i})');
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pure Editor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: SrqEditor(
                    controller: _controller,
                    config: mockConfig,
                    chipTags: [
                      SrqChipTag(
                        label: 'Mention Issue',
                        icon: Icons.bug_report,
                        onTap: () async {
                          // Opens bottom sheet, waits for selection, then inserts it automatically
                          return await _showMentionBottomSheet(context, 'Issue');
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// 4. Read More Screen
// =======================================================================
class ReadMoreScreen extends StatelessWidget {
  const ReadMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Read More Wrapper')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Limited to 150 characters:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SmartReadMore(
                content: dummyBackendData,
                limit: 150,
                config: mockConfig,
              ),
              const SizedBox(height: 32),
              const Text(
                'Limited to 400 characters:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SmartReadMore(
                content: dummyBackendData,
                limit: 400,
                config: mockConfig,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
