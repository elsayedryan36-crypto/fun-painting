import 'package:flutter/material.dart';

import '../resources/routs_manager.dart';
import 'Class.dart';
import 'list.dart';
import 'package:fun_painting/presentation/common/resources/assets_manager.dart';

List<Collections> buildGalleryItems(BuildContext context) {
  return [
    Collections(
      imagePath: VideoAssets.jungle,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 0),
    ),
    Collections(
      imagePath: VideoAssets.sea,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 1),
    ),

    Collections(
      imagePath: VideoAssets.dragons,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 2),
    ),

    Collections(
      imagePath: VideoAssets.fairy,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 3),
    ),
    Collections(
      imagePath: VideoAssets.space,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 4),
    ),

    Collections(
      imagePath: VideoAssets.cars,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 5),
    ),
    Collections(
      imagePath: VideoAssets.cirks,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 6),
    ),
    Collections(
      imagePath: VideoAssets.food,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 7),
    ),
    Collections(
      imagePath: VideoAssets.flowers,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 8),
    ),
    Collections(
      imagePath: VideoAssets.letters,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 9),
    ),
    Collections(
      imagePath: VideoAssets.numbers,
      onTap: () => Navigator.pushNamed(context, Routes.gallery, arguments: 10),
    ),
    Collections(
      imagePath: VideoAssets.whiteboard,
      onTap: () => Navigator.pushNamed(
        context,
        Routes.painting,
        arguments: ImageAssets.zero,
      ),
    ),
  ];
}

List<Collections> jungle(BuildContext context) {
  return List.generate(junglePhotos.length, (index) {
    return Collections(
      imagePath: junglePhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: junglePhotos[index],
        );
      },
    );
  });
}

List<Collections> sea(BuildContext context) {
  return List.generate(seaPhotos.length, (index) {
    return Collections(
      imagePath: seaPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: seaPhotos[index],
        );
      },
    );
  });
}

List<Collections> dragons(BuildContext context) {
  return List.generate(dragonsPhotos.length, (index) {
    return Collections(
      imagePath: dragonsPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: dragonsPhotos[index],
        );
      },
    );
  });
}

List<Collections> fairy(BuildContext context) {
  return List.generate(fairyPhotos.length, (index) {
    return Collections(
      imagePath: fairyPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: fairyPhotos[index],
        );
      },
    );
  });
}

List<Collections> space(BuildContext context) {
  return List.generate(spacePhotos.length, (index) {
    return Collections(
      imagePath: spacePhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: spacePhotos[index],
        );
      },
    );
  });
}

List<Collections> transportation(BuildContext context) {
  return List.generate(transportationPhotos.length, (index) {
    return Collections(
      imagePath: transportationPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: transportationPhotos[index],
        );
      },
    );
  });
}

List<Collections> circis(BuildContext context) {
  return List.generate(circisPhotos.length, (index) {
    return Collections(
      imagePath: circisPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: circisPhotos[index],
        );
      },
    );
  });
}

List<Collections> food(BuildContext context) {
  return List.generate(foodPhotos.length, (index) {
    return Collections(
      imagePath: foodPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: foodPhotos[index],
        );
      },
    );
  });
}

List<Collections> flowers(BuildContext context) {
  return List.generate(flowersPhotos.length, (index) {
    return Collections(
      imagePath: flowersPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: flowersPhotos[index],
        );
      },
    );
  });
}

List<Collections> letters(BuildContext context) {
  return List.generate(lettersPhotos.length, (index) {
    return Collections(
      imagePath: lettersPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: lettersPhotos[index],
        );
      },
    );
  });
}

List<Collections> nummbers(BuildContext context) {
  return List.generate(nummbersPhotos.length, (index) {
    return Collections(
      imagePath: nummbersPhotos[index],
      onTap: () async {
        await Navigator.pushNamed(
          context,
          Routes.painting,
          arguments: nummbersPhotos[index],
        );
      },
    );
  });
}
