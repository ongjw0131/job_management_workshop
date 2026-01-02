/// @author [Woo Keng Keong, Chong Jun Xiang]
/// @email [wookk-wm22@student.tarc.edu.my, chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-20 16:34:12
/// @modify date 2025-09-20 16:34:12
/// @desc [ProfileAvatarWidget: A widget for displaying a user's profile picture.]
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double radius;

  const ProfileAvatarWidget({super.key, this.imageUrl, this.radius = 50});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.deepPurple,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.deepPurple,
          child: const CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: Colors.deepPurple,
          child: const Icon(Icons.person, size: 50),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.deepPurple,
      child: const Icon(Icons.person, size: 50),
    );
  }
}
