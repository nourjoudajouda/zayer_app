import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Opens a full-screen style dialog with pinch-zoom; tap outside or close to dismiss.
void showNetworkImagePreview(
  BuildContext context, {
  required String imageUrl,
}) {
  if (imageUrl.isEmpty) return;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    barrierDismissible: true,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(color: Colors.white54),
                      ),
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(ctx).top + 8,
                right: 8,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(ctx).pop(),
                  tooltip: MaterialLocalizations.of(ctx).closeButtonTooltip,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Tappable thumbnail that opens [showNetworkImagePreview].
class TappableNetworkImage extends StatelessWidget {
  const TappableNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return SizedBox(width: width, height: height, child: const Icon(Icons.image_outlined));
    }
    Widget img = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
    if (borderRadius != null) {
      img = ClipRRect(borderRadius: borderRadius!, child: img);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showNetworkImagePreview(context, imageUrl: imageUrl),
        child: img,
      ),
    );
  }
}
