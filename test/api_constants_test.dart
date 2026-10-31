import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandea/core/constants/api_constants.dart';

void main() {
  const railway = 'https://tandea-back-end-production.up.railway.app/api/v1';

  tearDown(dotenv.clean);

  test('sin .env cargado usa Railway', () {
    expect(ApiConstants.apiBaseUrl, railway);
  });

  test('usa la URL del .env, también con saltos de línea de Windows', () {
    dotenv.loadFromString(
      envString: '# API_BASE_URL=$railway\r\nAPI_BASE_URL=http://192.168.0.22:3000/api/v1\r\n',
    );

    expect(ApiConstants.apiBaseUrl, 'http://192.168.0.22:3000/api/v1');
    expect(ApiConstants.baseUrl, 'http://192.168.0.22:3000/api/v1');
    expect(ApiConstants.healthUrl, 'http://192.168.0.22:3000/health');
  });

  test('si el .env no trae la variable o viene vacía usa Railway', () {
    dotenv.loadFromString(envString: 'OTRA=1');
    expect(ApiConstants.apiBaseUrl, railway);

    dotenv.clean();
    dotenv.loadFromString(envString: 'API_BASE_URL=');
    expect(ApiConstants.apiBaseUrl, railway);
  });
}
