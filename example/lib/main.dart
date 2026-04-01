import 'package:flutter/material.dart' hide TextSelection, EditableText;
import 'package:my_basic_textfield/src/widgets/editable_text.dart';
import 'package:my_basic_textfield/src/services/text_editing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Basic TextField Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TextFieldDemoPage(),
    );
  }
}

class TextFieldDemoPage extends StatefulWidget {
  const TextFieldDemoPage({super.key});

  @override
  State<TextFieldDemoPage> createState() => _TextFieldDemoPageState();
}

class _TextFieldDemoPageState extends State<TextFieldDemoPage> {
  late TextEdittingController _controller;
  String _displayText = 'No text entered yet';
  String _selectionInfo = 'No selection';

  @override
  void initState() {
    super.initState();
    _controller = TextEdittingController(null);

    // Listen to text changes
    _controller.addListener(() {
      setState(() {
        _displayText = _controller.text.isEmpty
            ? 'No text entered yet'
            : _controller.text;

        final selection = _controller.selection;
        _selectionInfo =
            'Cursor: ${selection.baseOffset} | '
            'Selection: ${selection.start}-${selection.end}';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearText() {
    _controller.clear();
  }

  void _setTextProgrammatically() {
    _controller.text = 'Hello from Flutter!';
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Basic TextField Demo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'Custom Text Field Example',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Field Features:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('✓ Blinking cursor'),
                    const Text('✓ Text selection with handles'),
                    const Text('✓ Copy/Paste/Cut functionality'),
                    const Text('✓ Long-press to select'),
                    const Text('✓ Tap to position cursor'),
                    const Text('✓ Keyboard integration'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Text Field Label
              Text(
                'Enter Text:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Custom Text Field
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: EditableText(
                  controller: _controller,
                  focusNode: FocusNode(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontFamily: 'Roboto',
                  ),
                  cursorColor: Colors.blue,
                  cursorWidth: 2,
                  obscureText: false,
                  isMultiline: false,
                  onChanged: (value) {
                    // Optional: Handle text changes
                    debugPrint('Text changed: $value');
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Display Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Text:',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayText,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Selection Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selection Info:',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectionInfo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontFamily: 'Courier',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Text(
                'Actions:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Button Row 1
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _setTextProgrammatically,
                      icon: const Icon(Icons.edit),
                      label: const Text('Set Text'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectAll,
                      icon: const Icon(Icons.select_all),
                      label: const Text('Select All'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Button Row 2
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _clearText,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Use:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Tap in the text field to focus'),
                    const Text('2. Type using your keyboard'),
                    const Text('3. Long-press to select text'),
                    const Text('4. Drag handles to adjust selection'),
                    const Text('5. Use toolbar to copy/paste/cut'),
                    const Text(
                      '6. Use buttons below to test programmatic control',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
