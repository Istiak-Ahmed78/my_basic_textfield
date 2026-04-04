import 'package:flutter/material.dart';

void main() {
  debugPrint('\n========================================');
  debugPrint('TESTING: Flutter\'s built-in EditableText');
  debugPrint('========================================\n');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Official Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late TextEditingController controller;
  final FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    controller.addListener(() {
      debugPrint(
        '📝 Text changed to: "${controller.text}" (length: ${controller.text.length})',
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Official EditableText'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.yellow.shade100,
              child: const Text(
                'This uses Flutter\'s BUILT-IN EditableText\n'
                'Type "hello" then backspace - does it work?\n\n'
                'If backspace works here, our custom code has an issue.\n'
                'If backspace does NOT work, the issue is the keyboard/native side.',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'FLUTTER\'S OFFICIAL TextField:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type here...',
              ),
            ),
            const SizedBox(height: 16),
            Text('Current text: "${controller.text}"'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.clear();
                debugPrint('🧹 Cleared');
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}
