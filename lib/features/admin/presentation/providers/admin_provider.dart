import 'package:flutter/foundation.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_metricas_entity.dart';
import 'package:tandea/features/admin/domain/entities/admin_usuario_entity.dart';
import 'package:tandea/features/admin/domain/repositories/admin_repository.dart';
import 'package:tandea/features/tandas/domain/entities/tanda_entity.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository adminRepository;

  AdminProvider({required this.adminRepository});

  AdminMetricasEntity? _metricas;
  bool _isLoadingMetricas = false;
  String? _errorMetricas;

  List<AdminUsuarioEntity> _usuarios = const [];
  bool _isLoadingUsuarios = false;
  String? _errorUsuarios;

  List<TandaEntity> _tandas = const [];
  bool _isLoadingTandas = false;
  String? _errorTandas;

  List<AdminDisputaEntity> _disputas = const [];
  bool _isLoadingDisputas = false;
  String? _errorDisputas;

  String _searchQuery = '';
  int _activeTabIndex = 0;

  AdminMetricasEntity? get metricas => _metricas;
  bool get isLoadingMetricas => _isLoadingMetricas;
  bool get isLoading =>
      _isLoadingMetricas ||
      _isLoadingUsuarios ||
      _isLoadingTandas ||
      _isLoadingDisputas;
  String? get errorMetricas => _errorMetricas;
  String? get errorMessage =>
      _errorMetricas ?? _errorUsuarios ?? _errorTandas ?? _errorDisputas;

  List<AdminUsuarioEntity> get usuarios => _usuarios;
  bool get isLoadingUsuarios => _isLoadingUsuarios;
  String? get errorUsuarios => _errorUsuarios;

  List<TandaEntity> get tandas => _tandas;
  bool get isLoadingTandas => _isLoadingTandas;
  String? get errorTandas => _errorTandas;

  List<AdminDisputaEntity> get disputas => _disputas;
  bool get isLoadingDisputas => _isLoadingDisputas;
  String? get errorDisputas => _errorDisputas;

  String get searchQuery => _searchQuery;
  int get activeTabIndex => _activeTabIndex;

  /// Lista de usuarios filtrada por [_searchQuery] (nombre, apellido, correo o rol).
  List<AdminUsuarioEntity> get usuariosFiltrados {
    final termino = _searchQuery.trim().toLowerCase();
    if (termino.isEmpty) return _usuarios;
    return _usuarios.where((u) {
      return u.nombreCompleto.toLowerCase().contains(termino) ||
          u.email.toLowerCase().contains(termino) ||
          u.role.toLowerCase().contains(termino);
    }).toList();
  }

  /// Lista de tandas filtrada por [_searchQuery] (nombre, código o estado).
  List<TandaEntity> get tandasFiltradas {
    final termino = _searchQuery.trim().toLowerCase();
    if (termino.isEmpty) return _tandas;
    return _tandas.where((t) {
      return t.nombre.toLowerCase().contains(termino) ||
          (t.inviteCode?.toLowerCase().contains(termino) ?? false) ||
          t.estado.toLowerCase().contains(termino);
    }).toList();
  }

  /// Lista de disputas/casos filtrada por [_searchQuery] (motivo, tanda, reportante o estado).
  List<AdminDisputaEntity> get disputasFiltradas {
    final termino = _searchQuery.trim().toLowerCase();
    if (termino.isEmpty) return _disputas;
    return _disputas.where((d) {
      return d.reason.toLowerCase().contains(termino) ||
          d.nombreTanda.toLowerCase().contains(termino) ||
          d.nombreReporter.toLowerCase().contains(termino) ||
          d.emailReporter.toLowerCase().contains(termino) ||
          d.status.toLowerCase().contains(termino) ||
          d.idDispute.toString().contains(termino);
    }).toList();
  }

  void setActiveTabIndex(int index) {
    if (_activeTabIndex == index) return;
    _activeTabIndex = index;
    notifyListeners();
  }

  /// Carga todo el panel administrativo (métricas, usuarios, tandas y disputas).
  Future<void> cargarTodo() async {
    await Future.wait([
      cargarMetricas(),
      cargarUsuarios(q: _searchQuery.isEmpty ? null : _searchQuery),
      cargarTandas(search: _searchQuery.isEmpty ? null : _searchQuery),
      cargarDisputas(),
    ]);
  }

  /// Carga o refresca las métricas globales del administrador (`GET /admin/metricas`).
  Future<void> cargarMetricas() async {
    _isLoadingMetricas = true;
    _errorMetricas = null;
    notifyListeners();

    final result = await adminRepository.obtenerMetricas();
    result.when(
      success: (data) {
        _metricas = data;
        _errorMetricas = null;
      },
      failure: (failure) {
        _errorMetricas = failure.message;
      },
    );

    _isLoadingMetricas = false;
    notifyListeners();
  }

  /// Consulta la lista de usuarios (`GET /admin/usuarios`).
  Future<void> cargarUsuarios({String? q, bool? active}) async {
    _isLoadingUsuarios = true;
    _errorUsuarios = null;
    notifyListeners();

    final result = await adminRepository.buscarUsuarios(q: q, active: active);
    result.when(
      success: (data) {
        _usuarios = data;
        _errorUsuarios = null;
      },
      failure: (failure) {
        _errorUsuarios = failure.message;
      },
    );

    _isLoadingUsuarios = false;
    notifyListeners();
  }

  /// Consulta la lista de tandas de la plataforma (`GET /tandas`).
  Future<void> cargarTandas({String? search, String? status}) async {
    _isLoadingTandas = true;
    _errorTandas = null;
    notifyListeners();

    final result = await adminRepository.listarTandasAdmin(
      search: search,
      status: status,
    );
    result.when(
      success: (data) {
        _tandas = data;
        _errorTandas = null;
      },
      failure: (failure) {
        _errorTandas = failure.message;
      },
    );

    _isLoadingTandas = false;
    notifyListeners();
  }

  /// Consulta la lista de disputas reportadas (`GET /admin/disputas`).
  Future<void> cargarDisputas({String? status, int? idTanda}) async {
    _isLoadingDisputas = true;
    _errorDisputas = null;
    notifyListeners();

    final result = await adminRepository.listarDisputas(
      status: status,
      idTanda: idTanda,
    );
    result.when(
      success: (data) {
        _disputas = data;
        _errorDisputas = null;
      },
      failure: (failure) {
        _errorDisputas = failure.message;
      },
    );

    _isLoadingDisputas = false;
    notifyListeners();
  }

  /// Aplica el término de búsqueda tras el debounce de 400 ms y consulta la pestaña activa.
  Future<void> aplicarBusqueda(String query) async {
    _searchQuery = query.trim();
    notifyListeners();

    final termino = _searchQuery.isEmpty ? null : _searchQuery;
    if (_activeTabIndex == 0) {
      await cargarUsuarios(q: termino);
    } else if (_activeTabIndex == 1) {
      await cargarTandas(search: termino);
    } else {
      await cargarDisputas();
    }
  }

  /// Suspende un usuario (`PATCH /admin/usuarios/:id/suspender`) y actualiza su estado en la lista.
  Future<bool> suspenderUsuario(int idUser, {String? motivo}) async {
    final result = await adminRepository.suspenderUsuario(
      idUser,
      motivo: motivo,
    );

    return result.when(
      success: (usuarioActualizado) {
        _usuarios = _usuarios.map((u) {
          if (u.idUser == idUser) {
            return usuarioActualizado.copyWith(active: false);
          }
          return u;
        }).toList();

        if (_metricas != null) {
          final conteo = _metricas!.usuarios;
          _metricas = AdminMetricasEntity(
            usuarios: ConteoUsuarios(
              total: conteo.total,
              activos: conteo.activos > 0 ? conteo.activos - 1 : 0,
              suspendidos: conteo.suspendidos + 1,
            ),
            tandas: _metricas!.tandas,
            montoGestionado: _metricas!.montoGestionado,
            disputasPendientes: _metricas!.disputasPendientes,
            montoPorMes: _metricas!.montoPorMes,
          );
        }

        notifyListeners();
        return true;
      },
      failure: (failure) {
        _errorUsuarios = failure.message;
        notifyListeners();
        return false;
      },
    );
  }
}
