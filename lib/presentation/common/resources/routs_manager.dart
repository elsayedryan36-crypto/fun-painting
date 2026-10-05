import 'package:flutter/material.dart';
import 'package:fun_painting/presentation/galary/galary_page.dart';
import 'package:fun_painting/presentation/home/home_screen.dart';

import '../../painting/painting_page.dart';
import '../../splash/splash_view.dart';
import 'strings_manager.dart';

class Routes {
  static const String splashRoute = "/";
  static const String homeRoute = "/home";
  static const String gallery = "/gallery";
  static const String painting = "/painting";

  // static const String loginRoute = "/login";
  // static const String registerRoute = "/register";
  // static const String forgotPasswordRoute = "/forgotPassword";
  // static const String storeDetailsRoute = "/storeDetails";
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      // case Routes.quranIndexRoute:
      //   return MaterialPageRoute(builder: (_) => QuranIndex());
      //
      // case Routes.quranPageRoute:
      //   final index = routeSettings.arguments as int;
      //   return MaterialPageRoute(builder: (_) => QuranPage(index: index));
      // case Routes.khatmaPageRoute:
      //   return MaterialPageRoute(builder: (_) => const CreatKhatma());
      case Routes.homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case Routes.gallery:
        final index = routeSettings.arguments as int;
        return MaterialPageRoute(builder: (_) => GalleryPage(listName: index));
      case Routes.painting:
        final image = routeSettings.arguments as String;
        return MaterialPageRoute(builder: (_) => PaintingPage(image: image));
      // case Routes.readKhatmaPageRoute:
      //   final startIndex = routeSettings.arguments as List;
      //   return MaterialPageRoute(
      //     builder:
      //         (_) => ReadWerdPage(
      //           startndex: startIndex[0],
      //           endndex: startIndex[1],
      //         ),
      //   );
      // case Routes.azkarReadingPageRoute:
      //   final data = routeSettings.arguments as List;
      //   return MaterialPageRoute(
      //     builder: (_) => AzkarReadingPage(title: data[0], index: data[1]),
      //   );
      // case Routes.azkarPageRoute:
      //   return MaterialPageRoute(builder: (_) => const AzkarPage());
      // case Routes.doaaPageRoute:
      //   return MaterialPageRoute(builder: (_) => const DoaaPage());
      // case Routes.doaaReadingPageRoute:
      //   final data = routeSettings.arguments as List;
      //   return MaterialPageRoute(
      //     builder: (_) => DoaaReadingPage(title: data[0], index: data[1]),
      //   );
      // case Routes.sephaWidgetPageRoute:
      //   return MaterialPageRoute(builder: (_) => const SephaPage());
      // case Routes.compassWidgetPageRoute:
      //   return MaterialPageRoute(builder: (_) => const CompassWidget());
      // case Routes.preyTimeWidgetPageRoute:
      //   return MaterialPageRoute(builder: (_) => const PrayerTimes());
      // case Routes.calenderPageRoute:
      //   return MaterialPageRoute(builder: (_) => const CalenderPage());
      // case Routes.settingPageRoute:
      //   return MaterialPageRoute(builder: (_) => const SettingPage());
      //
      // case Routes.settingPageSubRoute:
      //   final dataPage = routeSettings.arguments as List;
      //   return MaterialPageRoute(
      //     builder:
      //         (_) => SettingPageSub(title: dataPage[0], index: dataPage[1]),
      //   );
      default:
        return unDefinedRoute();
    }
  }

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text(AppStrings.noRouteFound)),
        body: const Center(child: Text(AppStrings.noRouteFound)),
      ),
    );
  }
}
