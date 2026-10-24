import 'package:bluebubbles/helpers/helpers.dart';
import 'package:bluebubbles/app/layouts/conversation_list/pages/conversation_list.dart';
import 'package:bluebubbles/app/layouts/conversation_list/widgets/header/header_widgets.dart';
import 'package:bluebubbles/app/layouts/conversation_list/pages/search/search_view.dart';
import 'package:bluebubbles/app/wrappers/fade_on_scroll.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CupertinoHeader extends StatelessWidget {
  const CupertinoHeader({Key? key, required this.controller});

  final ConversationListController controller;

  @override
  Widget build(BuildContext context) {
    final double topMargin = context.orientation == Orientation.landscape && context.isPhone
        ? 20
        : kIsDesktop || kIsWeb
            ? 40
            : kToolbarHeight + 30;

    return SliverToBoxAdapter(
      child: FadeOnScroll(
        scrollController: controller.iosScrollController,
        zeroOpacityOffset: topMargin + 15,
        child: Container(
          margin: EdgeInsets.only(
            top: topMargin,
            left: 16,
            right: 16,
            bottom: 6,
          ),
          child: Obx(() {
            ns.listener.value;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: ns.isAvatarOnly(context) ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: <Widget>[
                if (!ns.isAvatarOnly(context))
                  Expanded(
                    child: HeaderText(controller: controller, fontSize: 34),
                  ),
                if (ns.isAvatarOnly(context))
                  OverflowMenu(extraItems: true, controller: controller),
                if (!ns.isAvatarOnly(context))
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SyncIndicator(size: 16),
                      const SizedBox(width: 8.0),
                      Ios27GlassButton(
                        size: 38,
                        tooltip: "Search",
                        onTap: () => ns.pushLeft(context, SearchView()),
                        child: Icon(CupertinoIcons.search, color: Ios27.primaryText(context), size: 18),
                      ),
                      const SizedBox(width: 8.0),
                      if (ss.settings.moveChatCreatorToHeader.value)
                        CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
                              if (!FocusScope.of(context).focusInDirection(TraversalDirection.left)) {
                                FocusScope.of(context).previousFocus();
                              }
                            },
                            const SingleActivator(LogicalKeyboardKey.enter): () => controller.openNewChatCreator(context),
                            const SingleActivator(LogicalKeyboardKey.select): () => controller.openNewChatCreator(context),
                            const SingleActivator(LogicalKeyboardKey.space): () => controller.openNewChatCreator(context),
                          },
                          child: Ios27GlassButton(
                            size: 38,
                            tooltip: "New Message",
                            focusNode: controller.newMessageFocusNode,
                            onTap: () => controller.openNewChatCreator(context),
                            child: Icon(
                              CupertinoIcons.pencil,
                              color: Ios27.primaryText(context),
                              size: 19,
                            ),
                          ),
                        ),
                      if (ss.settings.moveChatCreatorToHeader.value) const SizedBox(width: 8.0),
                      if (ss.settings.moveChatCreatorToHeader.value && ss.settings.cameraFAB.value && !kIsWeb && !kIsDesktop)
                        Ios27GlassButton(
                          size: 38,
                          tooltip: "Camera",
                          onTap: () => controller.openCamera(context),
                          child: Icon(CupertinoIcons.camera, color: Ios27.primaryText(context), size: 19),
                        ),
                      if (ss.settings.moveChatCreatorToHeader.value && ss.settings.cameraFAB.value && !kIsWeb && !kIsDesktop)
                        const SizedBox(width: 8.0),
                      OverflowMenu(),
                    ],
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class CupertinoMiniHeader extends StatelessWidget {
  const CupertinoMiniHeader({Key? key, required this.controller});

  final ConversationListController controller;

  @override
  Widget build(BuildContext context) {
    final double topMargin = context.orientation == Orientation.landscape && context.isPhone
        ? 20
        : kIsDesktop || kIsWeb
            ? 60
            : kToolbarHeight + 30;

    return IgnorePointer(
      child: FadeOnScroll(
        scrollController: controller.iosScrollController,
        fullOpacityOffset: topMargin + 15,
        child: Obx(() {
          ns.listener.value;
          return Container(
            width: ns.width(context),
            height: (topMargin - 20).clamp(kIsDesktop ? 65 : 40, double.infinity),
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: kIsDesktop ? 10 : 5),
              child: Ios27GlassPill(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                child: Text(
                  controller.showArchivedChats
                      ? "Archive"
                      : controller.showUnknownSenders
                      ? "Unknown Senders"
                      : "Messages",
                  style: context.textTheme.titleSmall!.copyWith(
                    color: Ios27.primaryText(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
