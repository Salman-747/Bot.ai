import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

const String _api = "AIzaSyDJSxx3jU2Do9-GZtALVOI8wSXolwXId7Q";

void main() {
  if (_api.isEmpty) {
    print('Api key is empty');
    return;
  }
  runApp(const ChatBot());
}

class ChatBot extends StatelessWidget {
  const ChatBot({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      title: 'My Bot.ai',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(
          title: 'Bot.ai'),

    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.title});

  final String title;

  @override
  State<ChatScreen>createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _api);
    _chat = _model.startChat();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),centerTitle: true,),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // --- Chat History ---
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatMessageWidget(message: message);
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: CircularProgressIndicator(),
              ),

            Padding(
              padding: EdgeInsetsGeometry.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'What can i do for you?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.send_sharp),
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_textController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userInput = text;
    _textController.clear();
    setState(() {
      _isLoading=true;
      _messages.add(Message(text: userInput,isUser:true));
    });
    _scrollToBottom();
    try {
      final response= await _chat.sendMessage(Content.text(userInput));
      final botResponse= response.text;
      if (botResponse!=null){
        setState(() {
          _messages.add(Message(text:botResponse, isUser: false));
        });
      }
    } catch(e){
      print('Error Message:$e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error :${e.toString()}')));
    } finally{
      setState(() {
        _isLoading=false;

      });
      _scrollToBottom();
    }
  }
  void _scrollToBottom(){
    WidgetsBinding.instance.addPostFrameCallback((_){
      if (_scrollController.hasClients){
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
class Message{
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}
class ChatMessageWidget extends StatelessWidget{
  final Message message;
  const ChatMessageWidget({super.key, required this.message});
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Align(
      alignment: message.isUser? Alignment.centerRight: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0,horizontal: 80),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: message.isUser
              ?Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
              ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondary,

          )
        ),
      ),
    );
  }
}
