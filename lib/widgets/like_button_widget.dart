import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/like_service.dart';

class LikeButtonWidget extends StatelessWidget {
  final String productId;
  final double? iconSize;
  final Color? likedColor;
  final Color? unlikedColor;

  const LikeButtonWidget({
    super.key,
    required this.productId,
    this.iconSize = 24.0,
    this.likedColor = Colors.red,
    this.unlikedColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    final LikeService likeService = Get.find<LikeService>();

    return Obx(() {
      final isLiked = likeService.isLiked(productId);

      return GestureDetector(
        onTap: () async {
          debugPrint(
              'LikeButtonWidget: Tapping like for product $productId, current state: $isLiked');
          final result = await likeService.toggleLike(productId);
          debugPrint(
              'LikeButtonWidget: Toggle result: $result, new state should be: ${!isLiked}');
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(isLiked),
            color: isLiked ? likedColor : unlikedColor,
            size: iconSize,
          ),
        ),
      );
    });
  }
}

class LikeIconButton extends StatelessWidget {
  final String productId;
  final double? iconSize;
  final Color? likedColor;
  final Color? unlikedColor;
  final EdgeInsets? padding;

  const LikeIconButton({
    super.key,
    required this.productId,
    this.iconSize = 24.0,
    this.likedColor = Colors.red,
    this.unlikedColor = Colors.grey,
    this.padding,
  });

  @override 
  Widget build(BuildContext context) {
    final LikeService likeService = Get.find<LikeService>();

    return Obx(() {
      final isLiked = likeService.isLiked(productId);

      return IconButton(
        padding: padding ?? const EdgeInsets.all(8.0),
        onPressed: () async {
          debugPrint(
              'LikeIconButton: Tapping like for product $productId, current state: $isLiked');
          final result = await likeService.toggleLike(productId);
          debugPrint(
              'LikeIconButton: Toggle result: $result, new state should be: ${!isLiked}');
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(isLiked),
            color: isLiked ? likedColor : unlikedColor,
            size: iconSize,
          ),
        ),
      );
    });
  }
}
