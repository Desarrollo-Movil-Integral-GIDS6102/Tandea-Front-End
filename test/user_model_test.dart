import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/features/auth/data/models/user_model.dart';
import 'package:tandea/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel', () {
    test('fromJson maneja respuesta de Login de NestJS con token y objeto user anidado', () {
      final json = <String, dynamic>{
        'access_token': 'jwt_token_sample_12345',
        'user': {
          'idUser': 42,
          'email': 'carlos@tandea.app',
          'name': 'Carlos',
          'lastName': 'Ramírez',
          'role': 'usuario',
        },
      };

      final model = UserModel.fromJson(json);

      expect(model.id, '42');
      expect(model.nombre, 'Carlos');
      expect(model.apellido, 'Ramírez');
      expect(model.email, 'carlos@tandea.app');
      expect(model.rol, 'usuario');
      expect(model.token, 'jwt_token_sample_12345');
      expect(model.nombreCompleto, 'Carlos Ramírez');
    });

    test('fromJson maneja respuesta de Registro de NestJS plana', () {
      final json = <String, dynamic>{
        'idUser': 7,
        'email': 'lucia@tandea.app',
        'name': 'Lucía',
        'lastName': 'Gómez',
        'role': 'usuario',
        'active': true,
        'age': 25,
        'gender': 'Femenino',
      };

      final model = UserModel.fromJson(json);

      expect(model.id, '7');
      expect(model.nombre, 'Lucía');
      expect(model.apellido, 'Gómez');
      expect(model.email, 'lucia@tandea.app');
      expect(model.rol, 'usuario');
      expect(model.edad, 25);
      expect(model.genero, 'Femenino');
      expect(model.token, isNull);
    });

    test('toEntity convierte UserModel a UserEntity correctamente', () {
      const model = UserModel(
        id: '10',
        nombre: 'Mario',
        apellido: 'López',
        email: 'mario@tandea.app',
        rol: 'admin_global',
        token: 'sample_token',
      );

      final entity = model.toEntity();

      expect(entity, isA<UserEntity>());
      expect(entity.id, '10');
      expect(entity.nombre, 'Mario');
      expect(entity.apellido, 'López');
      expect(entity.email, 'mario@tandea.app');
      expect(entity.rol, 'admin_global');
      expect(entity.token, 'sample_token');
    });

    test('toJson serializa los campos correctamente', () {
      const model = UserModel(
        id: '15',
        nombre: 'Ana',
        apellido: 'Soto',
        email: 'ana@tandea.app',
        rol: 'usuario',
        token: 'token_abc',
        edad: 30,
      );

      final json = model.toJson();

      expect(json['id'], '15');
      expect(json['nombre'], 'Ana');
      expect(json['apellido'], 'Soto');
      expect(json['email'], 'ana@tandea.app');
      expect(json['rol'], 'usuario');
      expect(json['token'], 'token_abc');
      expect(json['edad'], 30);
    });
  });
}
