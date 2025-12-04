import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env.dev')
abstract class EnvDev {
  @EnviedField(varName: 'apiUrl')
  static const String apiUrl = _EnvDev.apiUrl;

  @EnviedField(varName: 'firebaseApiKey')
  static const String firebaseApiKey = _EnvDev.firebaseApiKey;
}

@Envied(path: '.env.staging')
abstract class EnvStaging {
  @EnviedField(varName: 'apiUrl')
  static const String apiUrl = _EnvStaging.apiUrl;

  @EnviedField(varName: 'firebaseApiKey')
  static const String firebaseApiKey = _EnvStaging.firebaseApiKey;
}

@Envied(path: '.env.prod')
abstract class EnvProd {
  @EnviedField(varName: 'apiUrl')
  static const String apiUrl = _EnvProd.apiUrl;

  @EnviedField(varName: 'firebaseApiKey')
  static const String firebaseApiKey = _EnvProd.firebaseApiKey;
}
