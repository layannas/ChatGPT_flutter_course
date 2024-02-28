import 'dart:developer';

import 'package:chatgpt_course/constants/constants.dart';
import 'package:chatgpt_course/providers/chats_provider.dart';
import 'package:chatgpt_course/services/services.dart';
import 'package:chatgpt_course/widgets/chat_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../providers/models_provider.dart';
import '../services/assets_manager.dart';
import '../widgets/text_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isTyping = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;
  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // List<ChatModel> chatList = [];
  @override
  Widget build(BuildContext context) {
    final modelsProvider = Provider.of<ModelsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Handle the button press or navigate back
          },
        ),
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            "معلم البايثون",
            style: TextStyle(fontSize: 30), // Set the desired font size
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Transform.scale(
              scale: 3, // Set the desired scale value
            ),
          ),
          /* IconButton(
        onPressed: () async {
          await Services.showModalSheet(context: context);
        },
        icon: Icon(Icons.more_vert_rounded, color: Colors.white),
      ), */
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                  controller: _listScrollController,
                  itemCount: chatProvider.getChatList.length, //chatList.length,
                  itemBuilder: (context, index) {
                    return ChatWidget(
                      msg: chatProvider
                          .getChatList[index].msg, // chatList[index].msg,
                      chatIndex: chatProvider.getChatList[index]
                          .chatIndex, //chatList[index].chatIndex,
                      shouldAnimate:
                          chatProvider.getChatList.length - 1 == index,
                    );
                  }),
            ),
            if (_isTyping) ...[
              const SpinKitThreeBounce(
                color: Color.fromARGB(255, 6, 6, 6),
                size: 30,
              ),
            ],
            const SizedBox(
              height: 40,
            ),
            Material(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () async {
                          await sendMessageFCT(
                            modelsProvider: modelsProvider,
                            chatProvider: chatProvider,
                          );
                        },
                        icon: const FaIcon(
                          FontAwesomeIcons.paperPlane,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            focusNode: focusNode,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 30,
                            ),
                            controller: textEditingController,
                            onSubmitted: (value) async {
                              await sendMessageFCT(
                                modelsProvider: modelsProvider,
                                chatProvider: chatProvider,
                              );
                            },
                            decoration: const InputDecoration.collapsed(
                              hintText: "كيف يمكنني مساعدتك؟",
                              hintStyle: TextStyle(
                                  color: Color.fromARGB(255, 97, 97, 97)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut);
  }

  Future<void> sendMessageFCT(
      {required ModelsProvider modelsProvider,
      required ChatProvider chatProvider}) async {
    if (_isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "You cant send multiple messages at a time",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "كيف يمكنني مساعدتك ؟",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that the message contains Arabic keywords related to Python
    final pythonKeywords = ['بايثون', 'برمجة_بايثون', 'بايثوني', 'بايثونية'];
    final message = textEditingController.text.toLowerCase();
    final containsPythonKeyword =
        pythonKeywords.any((keyword) => message.contains(keyword));
    if (!containsPythonKeyword) {
      // Show error message if the message does not contain Arabic Python-related keywords
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              TextWidget(label: "يرجى طرح سؤال متعلق بلغة البرمجة بايثون."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      String msg = textEditingController.text;
      setState(() {
        _isTyping = true;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatProvider.sendMessageAndGetAnswers(
          msg: msg, chosenModelId: modelsProvider.getCurrentModel);
      // chatList.addAll(await ApiService.sendMessage(
      //   message: textEditingController.text,
      //   modelId: modelsProvider.getCurrentModel,
      // ));
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEND();
        _isTyping = false;
      });
    }
  }
}
