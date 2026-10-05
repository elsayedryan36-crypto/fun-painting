import 'package:flutter/material.dart';

import '../../../data/services/rewarded_ad_service.dart';

/// A gallery tile for a single coloring image. If [isUnlocked] is false,
/// shows a dimmed thumbnail with a lock badge; tapping triggers the
/// rewarded-ad unlock flow via [RewardedAdService].
class LockedImageTile extends StatefulWidget {
  const LockedImageTile({
    super.key,
    required this.imageId,
    required this.thumbnail,
    required this.isUnlocked,
    required this.onTapUnlocked,
    required this.onImageUnlocked,
  });

  final String imageId;
  final Widget thumbnail;
  final bool isUnlocked;

  /// Called when an already-unlocked (or free) image is tapped.
  final VoidCallback onTapUnlocked;

  /// Called after a locked image is successfully unlocked via ad.
  final VoidCallback onImageUnlocked;

  @override
  State<LockedImageTile> createState() => _LockedImageTileState();
}

class _LockedImageTileState extends State<LockedImageTile> {
  bool _isShowingAd = false;

  Future<void> _handleTap() async {
    if (widget.isUnlocked) {
      widget.onTapUnlocked();
      return;
    }

    setState(() => _isShowingAd = true);

    final success = await RewardedAdService.instance.showToUnlock(
      imageId: widget.imageId,
      onUnlocked: widget.onImageUnlocked,
    );

    if (mounted) setState(() => _isShowingAd = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not ready yet — try again in a moment.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isShowingAd ? null : _handleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: widget.isUnlocked
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : const ColorFilter.matrix(<double>[
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0.2126,
                    0.7152,
                    0.0722,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]), // grayscale for locked thumbnails
            child: widget.thumbnail,
          ),
          if (!widget.isUnlocked)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: _isShowingAd
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.lock, color: Colors.white, size: 28),
                          SizedBox(height: 4),
                          Text(
                            'Watch to unlock',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
