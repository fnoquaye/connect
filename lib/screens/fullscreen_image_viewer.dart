import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? senderName;
  final String? timestamp;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrl,
    this.senderName,
    this.timestamp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: senderName != null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName!,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (timestamp != null)
              Text(
                timestamp!,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        )
            : null,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showImageOptions(context);
            },
          ),
        ],
      ),
      body: InteractiveViewer(
        panEnabled: true,
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.white, size: 60),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.save_alt, color: Colors.white),
              title: Text('Save Image', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _saveImage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: Colors.white),
              title: Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareImage(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: Colors.white),
              title: Text('Copy Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _copyImageUrl(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveImage(BuildContext context) {
    // TODO: Implement image saving to gallery
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Save functionality coming soon'),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  void _shareImage(BuildContext context) {
    // TODO: Implement image sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Colors.grey[800],
      ),
    );
  }

  void _copyImageUrl(BuildContext context) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copy functionality coming soon'),
        backgroundColor: Colors.grey[800],
      ),
    );
  }
}