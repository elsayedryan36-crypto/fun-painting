import 'package:flutter/material.dart';

import '../../common/local_data/Class.dart';
import '../../common/local_data/collection_list.dart';

class GalleryCollectionHelper {
  static List<Collections> getItems(BuildContext context, int category) {
    switch (category) {
      case 0:
        return jungle(context); // Zoo
      case 1:
        return sea(context); // Sea
      case 2:
        return dragons(context); // Dragons

      case 3:
        return fairy(context); // Fairy

      case 4:
        return space(context); // Space

      case 5:
        return transportation(context); // Transportation

      case 6:
        return circis(context); // Circis

      case 7:
        return food(context); // Food

      case 8:
        return flowers(context); // Fairy

      case 9:
        return letters(context); // Letters

      case 10:
        return nummbers(context); // Numbers

      default:
        return jungle(context);
    }
  }
}
