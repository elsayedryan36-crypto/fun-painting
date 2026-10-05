import 'package:get_it/get_it.dart';

//
// import '../data/dataSource/remoteDataSource.dart';
// import '../data/network/app_api.dart';
// import '../data/network/dio_factory.dart';
// import '../data/network/network_info.dart';
// import '../domain/repository/repository.dart';
// import '../domain/use_case/forgot_password_usecase.dart';
// import '../domain/use_case/login_use_case.dart';
// import '../domain/use_case/register_use_case.dart';
// import '../domain/use_case/store_details_use_case.dart';
// import 'app_pref.dart';
//
final instance = GetIt.instance;
//

Future<void> initAppModule() async {
  // app module, its a module where we put all generic dependencies

  //   // Blocs
  //   instance.registerFactory<HomeCubit>(() => HomeCubit(instance()));

  //   // shared prefs instance
  //   final sharedPrefs = await SharedPreferences.getInstance();

  //   instance.registerLazySingleton<SharedPreferences>(() => sharedPrefs);

  //   // app prefs instance
  //   instance
  //       .registerLazySingleton<AppPreferences>(() => AppPreferences(instance()));

  //   // network info
  //   instance.registerLazySingleton<NetworkInfo>(
  //       () => NetworkInfoImpl(InternetConnectionChecker()));

  //   // dio factory
  //   instance.registerLazySingleton<DioFactory>(() => DioFactory(instance()));

  //   // app  service client
  //   Dio dio = await instance<DioFactory>().getDio();
  //   instance.registerLazySingleton<AppServiceClient>(() => AppServiceClient(dio));

  //   // remote data source
  //   instance.registerLazySingleton<RemoteDataSource>(
  //       () => RemoteDataSourceImpl(instance<AppServiceClient>()));

  //   // local data source
  //   instance.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl());

  //   // repository
  //   instance.registerLazySingleton<Repository>(
  //       () => RepositoryImpl(instance(), instance(), instance()));
  // }

  // instance.registerSingleton<HomeRepositoryImpl>(
  //   HomeRepositoryImpl(
  //     homeLocalDataSource: QuranIndexLocalDataSourceImpl(),
  //     homeRemoteDataSource: HomeRemoteDataSourceImpl(ApiService(Dio())),
  //   ),
  // );
  //-------------------------- Login ---------------------------------------------
  // initLoginModule() {
  //   if (!GetIt.I.isRegistered<LoginUseCase>()) {
  //     instance.registerFactory<LoginUseCase>(() => LoginUseCase(instance()));
  //     instance.registerFactory<LoginViewModel>(() => LoginViewModel(instance()));
  //   }
  // }

  // //-------------------------- Forget Password -----------------------------------
  // initForgetPasswordModule() {
  //   if (!GetIt.I.isRegistered<ForgetPasswordUseCase>()) {
  //     instance.registerFactory<ForgetPasswordUseCase>(
  //         () => ForgetPasswordUseCase(instance()));
  //     instance.registerFactory<ForgetPasswordViewModel>(
  //         () => ForgetPasswordViewModel(instance()));
  //   }
  // }

  // //-------------------------- Register -----------------------------------
  // initRegisterModule() {
  //   if (!GetIt.I.isRegistered<RegisterUseCase>()) {
  //     instance
  //         .registerFactory<RegisterUseCase>(() => RegisterUseCase(instance()));
  //     instance.registerFactory<RegisterViewModel>(
  //       () => RegisterViewModel(instance()),
  //     );

  //     instance.registerFactory<ImagePicker>(() => ImagePicker());
  //   }
  // }

  // //------------------------------ Home ------------------------------------------
  // initHomeModule() {
  //   if (!GetIt.I.isRegistered<HomeUseCase>()) {
  //     instance.registerFactory<HomeUseCase>(() => HomeUseCase(instance()));
  //   }
  // }

  // //------------------------------ StoreDetails ----------------------------------
  // initStoreDetailsModule() {
  //   if (!GetIt.I.isRegistered<StoreDetailsUseCase>()) {
  //     instance.registerFactory<StoreDetailsUseCase>(
  //         () => StoreDetailsUseCase(instance()));
  //     instance.registerFactory<StoreDetailsViewModel>(
  //         () => StoreDetailsViewModel(instance()));
  //   }
}
