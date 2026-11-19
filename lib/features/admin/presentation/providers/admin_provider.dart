import 'package:flutter/foundation.dart';
import 'package:tandea/features/admin/domain/entities/admin_disputa_detalle_entity.dart';
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

  AdminDisputaDetalleEntity? _detalleDisputaActual;
  bool _isLoadingDetalleDisputa = false;
  bool _isResolviendoDisputa = false;
  String? _errorDetalleDisputa;
  String? _accionSeleccionada;
  String _notasResolucion = '';

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

  AdminDisputaDetalleEntity? get detalleDisputaActual => _detalleDisputaActual;
  bool get isLoadingDetalleDisputa => _isLoadingDetalleDisputa;
  bool get isResolviendoDisputa => _isResolviendoDisputa;
  String? get errorDetalleDisputa => _errorDetalleDisputa;
  String? get accionSeleccionada => _accionSeleccionada;
  String get notasResolucion => _notasResolucion;

  /// Opciones válidas para resolver una disputa en el backend.
  static const List<String> accionesResolucionValidas = [
    'mantener',
    'revertir',
    'suspender',
  ];

  /// El botón de resolver solo se habilita si hay una opción válida seleccionada
  /// (`mantener`, `revertir` o `suspender`) Y el comentario no está vacío.
  bool get puedeConfirmarResolucion {
    final accion = _accionSeleccionada?.trim().toLowerCase();
    return accion != null &&
        accionesResolucionValidas.contains(accion) &&
        _notasResolucion.trim().isNotEmpty &&
        !_isResolviendoDisputa;
  }

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

  /// Carga el detalle de una disputa con su línea de tiempo (`GET /admin/disputas/:id`).
  Future<void> cargarDetalleDisputa(
    int idDispute, {
    bool reiniciarFormulario = true,
  }) async {
    _isLoadingDetalleDisputa = true;
    _errorDetalleDisputa = null;
    if (reiniciarFormulario) {
      _accionSeleccionada = null;
      _notasResolucion = '';
    }
    notifyListeners();

    final result = await adminRepository.obtenerDetalleDisputa(idDispute);
    result.when(
      success: (detalle) {
        _detalleDisputaActual = detalle;
        _errorDetalleDisputa = null;
      },
      failure: (failure) {
        _errorDetalleDisputa = failure.message;
      },
    );

    _isLoadingDetalleDisputa = false;
    notifyListeners();
  }

  void seleccionarAccionResolucion(String? accion) {
    _accionSeleccionada = accion;
    notifyListeners();
  }

  void actualizarNotasResolucion(String notas) {
    _notasResolucion = notas;
    notifyListeners();
  }

  /// Ejecuta la resolución del caso (`PATCH /admin/disputas/:id/resolver`).
  Future<bool> resolverDisputa(
    int idDispute, {
    String? accion,
    String? notas,
  }) async {
    final accionFinal = (accion ?? _accionSeleccionada ?? '').trim().toLowerCase();
    final notasFinal = (notas ?? _notasResolucion).trim();

    if (!accionesResolucionValidas.contains(accionFinal) || notasFinal.isEmpty) {
      return false;
    }

    _isResolviendoDisputa = true;
    _errorDetalleDisputa = null;
    notifyListeners();

    final result = await adminRepository.resolverDisputa(
      idDispute: idDispute,
      accion: accionFinal,
      notas: notasFinal,
    );

    final exito = result.when(
      success: (disputaResuelta) {
        final actualizada = disputaResuelta.copyWith(
          status: 'RESUELTA',
          resolutionNotes: notasFinal,
          resolvedAt: disputaResuelta.resolvedAt ?? DateTime.now(),
        );

        _disputas = _disputas.map((d) {
          if (d.idDispute == idDispute) {
            return actualizada;
          }
          return d;
        }).toList();

        if (_detalleDisputaActual != null &&
            _detalleDisputaActual!.disputa.idDispute == idDispute) {
          _detalleDisputaActual = _detalleDisputaActual!.copyWith(
            disputa: actualizada,
          );
        }

        if (_metricas != null && _metricas!.disputasPendientes > 0) {
          _metricas = AdminMetricasEntity(
            usuarios: _metricas!.usuarios,
            tandas: _metricas!.tandas,
            montoGestionado: _metricas!.montoGestionado,
            disputasPendientes: _metricas!.disputasPendientes - 1,
            montoPorMes: _metricas!.montoPorMes,
          );
        }
        return true;
      },
      failure: (failure) {
        _errorDetalleDisputa = failure.message;
        return false;
      },
    );

    _isResolviendoDisputa = false;
    notifyListeners();
    return exito;
  }
}
