import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/wrappers/stateful_boilerplate.dart';
import 'package:bluebubbles/app/wrappers/theme_switcher.dart';
import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ConversationListFAB extends CustomStateful<ConversationListController> {
  const ConversationListFAB({Key? key, required super.parentController});

  @override
  State<StatefulWidget> createState() => _ConversationListFABState();
}

class _ConversationListFABState extends CustomState<ConversationListFAB, void, ConversationListController> {
  void _focusBackToList() {
    if (!FocusScope.of(context).focusInDirection(TraversalDirection.left)) {
      FocusScope.of(context).previousFocus();
    }
  }

  Map<ShortcutActivator, VoidCallback> get _newMessageShortcuts => {
    const SingleActivator(LogicalKeyboardKey.arrowLeft): _focusBackToList,
    const SingleActivator(LogicalKeyboardKey.enter): () => controller.openNewChatCreator(context),
    const SingleActivator(LogicalKeyboardKey.select): () => controller.openNewChatCreator(context),
    const SingleActivator(LogicalKeyboardKey.space): () => controller.openNewChatCreator(context),
  };

  @override
  void initState() {
    super.initState();

    controller.materialScrollController.addListener(() {
      if (!material) return;
      if (controller.materialScrollStartPosition - controller.materialScrollController.offset < -75
          && controller.materialScrollController.position.userScrollDirection == ScrollDirection.reverse
          && controller.showMaterialFABText) {
        setState(() {
          controller.showMaterialFABText = false;
        });
      } else if (controller.materialScrollStartPosition - controller.materialScrollController.offset > 75
          && controller.materialScrollController.position.userScrollDirection == ScrollDirection.forward
          && !controller.showMaterialFABText) {
        setState(() {
          controller.showMaterialFABText = true;
        });
      }
    });
    ns.listener.stream.listen((event) {
      if (!mounted) return;
      if (ns.isAvatarOnly(context) && controller.showMaterialFABText) {
        setState(() {
          controller.showMaterialFABText = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final widget = Obx(() {
      final showCamera = ss.settings.cameraFAB.value && iOS && !kIsWeb && !kIsDesktop;
      final accent = context.theme.colorScheme.primary;
      final onAccent = context.theme.colorScheme.onPrimary;

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (chats.chats.isEmpty && chats.loadedChatBatch.value)
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 16),
                  child: Ios27GlassPill(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(
                      "Start a Chat",
                      style: context.textTheme.labelLarge?.copyWith(color: Ios27.primaryText(context)),
                    ),
                  ),
                ),
              // A single merged glass surface holds both actions. The camera
              // and compose buttons melt into one pill instead of rendering
              // two separate floating circles.
              Ios27GlassCluster(
                axis: Axis.vertical,
                spacing: 2,
                padding: const EdgeInsets.all(5),
                borderRadius: 36,
                tint: accent.withOpacity(0.62),
                children: [
                  if (showCamera)
                    Ios27ClusterButton(
                      size: 44,
                      tooltip: "Take a photo",
                      color: onAccent,
                      onTap: () => controller.openCamera(context),
                      onLongPress: () => controller.openCamera(context),
                      child: Icon(iOS ? CupertinoIcons.camera : Icons.photo_camera),
                    ),
                  if (showCamera)
                    Container(
                      width: 26,
                      height: 0.7,
                      color: onAccent.withOpacity(0.22),
                    ),
                  CallbackShortcuts(
                    bindings: _newMessageShortcuts,
                    child: Focus(
                      focusNode: controller.newMessageFocusNode,
                      child: Ios27ClusterButton(
                        size: 54,
                        tooltip: "New message",
                        color: onAccent,
                        onTap: () => controller.openNewChatCreator(context),
                        // The camera button is part of this cluster when the
                        // setting is on; iOS never used a long-press shortcut.
                        onLongPress: null,
                        child: Icon(
                          iOS ? CupertinoIcons.pencil : Icons.message,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    });

    return ThemeSwitcher(
      iOSSkin: widget,
      materialSkin: AnimatedCrossFade(
        crossFadeState: controller.selectedChats.isEmpty
            ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 300),
        secondChild: const SizedBox.shrink(),
        firstChild: SizedBox(
          width: ns.width(context),
          height: 125,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              AnimatedOpacity(
                opacity: !controller.showMaterialFABText ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: FloatingActionButton.small(
                  heroTag: null,
                  onPressed: () async {
                    await controller.materialScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    setState(() {
                      controller.showMaterialFABText = true;
                    });
                  },
                  child: Icon(
                    Icons.arrow_upward,
                    color: context.theme.colorScheme.onSecondary,
                  ),
                  backgroundColor: context.theme.colorScheme.secondary,
                ),
              ),
              Positioned(
                right: material ? 15 : 0,
                child: InkWell(
                  onLongPress: ss.settings.cameraFAB.value && !kIsWeb && !kIsDesktop
                      ? () => controller.openCamera(context) : null,
                  child: Container(
                    height: 65,
                    padding: const EdgeInsets.only(right: 4.5, bottom: 9),
                    child: CallbackShortcuts(
                      bindings: _newMessageShortcuts,
                      child: FloatingActionButton(
                        focusNode: controller.newMessageFocusNode,
                        backgroundColor: context.theme.colorScheme.primaryContainer,
                        shape: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 2),
                          child: Icon(
                            CupertinoIcons.bubble_left,
                            color: context.theme.colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        onPressed: () => controller.openNewChatCreator(context),
                      ),
                    ),
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
