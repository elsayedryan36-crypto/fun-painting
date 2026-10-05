import 'package:dartz/dartz.dart';

import '../errors/failure.dart';

abstract class UseCase<Type, Parm> {
  Future<Either<Failure, Map<String, Type>>> call([Parm parm]);
}

class NoParm {}
