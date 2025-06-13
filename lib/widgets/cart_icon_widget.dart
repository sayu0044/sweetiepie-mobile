import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sweetipie/services/cart_service.dart';

class CartIconWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? iconSize;

  const CartIconWidget({
    Key? key,
    this.onTap,
    this.iconColor,
    this.iconSize = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartService>(
      builder: (cartService) {
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: iconSize,
              ),
              if (cartService.cartItemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      cartService.cartItemCount > 99
                          ? '99+'
                          : cartService.cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
