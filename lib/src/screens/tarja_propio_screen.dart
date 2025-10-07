import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/tarja_propio_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/colaborador_provider.dart';
import '../models/tarja_propio.dart';
import '../theme/app_theme.dart';
import '../theme/dark_theme_colors.dart';

class TarjaPropioScreen extends StatefulWidget {
  const TarjaPropioScreen({super.key});

  @override
  State<TarjaPropioScreen> createState() => _TarjaPropioScreenState();
}

class _TarjaPropioScreenState extends State<TarjaPropioScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;
  bool _mostrarResumen = false;
  String _vistaActiva = 'detalle'; // 'detalle' o 'resumen'
  String? _filtroActivo; // 'todos', 'creadas', 'revisadas', 'aprobadas'
  
  // Variables para agrupación por mes-año
  List<bool> _expansionState = [];
  final GlobalKey _expansionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final tarjaPropioProvider = context.read<TarjaPropioProvider>();
      
      tarjaPropioProvider.cargarTarjasPropios();
    });
  }

  Future<void> _refrescarDatos() async {
    final tarjaPropioProvider = context.read<TarjaPropioProvider>();
    if (_vistaActiva == 'detalle') {
      await tarjaPropioProvider.cargarTarjasPropios();
    } else {
      await tarjaPropioProvider.cargarResumenColaboradores();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  bool _tieneFiltrosActivos(TarjaPropioProvider provider) {
    return provider.idColaborador != null ||
           provider.idLabor != null ||
           provider.filtroMes != null ||
           provider.filtroAno != null;
  }

  void _cambiarVista(String vista) {
    setState(() {
      _vistaActiva = vista;
    });
    
    final tarjaPropioProvider = context.read<TarjaPropioProvider>();
    if (vista == 'resumen') {
      tarjaPropioProvider.cargarResumenColaboradores();
    } else {
      tarjaPropioProvider.cargarTarjasPropios();
    }
  }

  void _aplicarFiltro(String? filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    // NO aplicar filtros al provider - solo cambiar el estado visual
    // Los indicadores deben mostrar números fijos, solo la tabla se filtra
  }

  List<TarjaPropio> _filtrarTarjas(List<TarjaPropio> tarjas) {
    var tarjasFiltradas = tarjas;
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      tarjasFiltradas = tarjasFiltradas.where((tarja) {
        return tarja.colaborador.toLowerCase().contains(_searchQuery) ||
               tarja.labor.toLowerCase().contains(_searchQuery) ||
               tarja.centroDeCosto.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    // Filtrar por indicador seleccionado
    if (_filtroActivo != null) {
      switch (_filtroActivo) {
        case 'creadas':
          tarjasFiltradas = tarjasFiltradas.where((tarja) => tarja.idEstadoActividad == 1).toList();
          break;
        case 'revisadas':
          tarjasFiltradas = tarjasFiltradas.where((tarja) => tarja.idEstadoActividad == 2).toList();
          break;
        case 'aprobadas':
          tarjasFiltradas = tarjasFiltradas.where((tarja) => tarja.idEstadoActividad == 3).toList();
          break;
        case 'todos':
        default:
          // No filtrar por estado
          break;
      }
    }
    
    return tarjasFiltradas;
  }

  List<TarjaPropioResumen> _filtrarResumen(List<TarjaPropioResumen> resumen) {
    if (_searchQuery.isEmpty) {
      return resumen;
    }
    
    return resumen.where((item) {
      return item.colaborador.toLowerCase().contains(_searchQuery);
    }).toList();
  }


  String _formatearHora(String hora) {
    try {
      return hora.substring(0, 5); // HH:MM
    } catch (e) {
      return hora;
    }
  }

  String _formatearMoneda(double valor) {
    return '\$${NumberFormat('#,##0', 'es_CL').format(valor)}';
  }

  // Funciones helper para agrupación por mes-año
  void _resetExpansionState(int length) {
    _expansionState = List.generate(length, (index) => true);
  }

  Map<String, List<TarjaPropio>> _agruparPorMesAno(List<TarjaPropio> tarjas) {
    final Map<String, List<TarjaPropio>> grupos = {};
    
    for (final tarja in tarjas) {
      // Usar el método del modelo para parsear la fecha
      final fecha = TarjaPropio.parseFecha(tarja.fecha);
      if (fecha != null) {
        final mesAno = '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}';
        grupos.putIfAbsent(mesAno, () => []).add(tarja);
      } else {
        // Si no se puede parsear la fecha, agrupar como "Sin fecha"
        grupos.putIfAbsent('sin_fecha', () => []).add(tarja);
      }
    }
    
    return grupos;
  }

  String _formatearMesAno(String mesAno) {
    if (mesAno == 'sin_fecha') return 'Sin fecha';
    
    try {
      final parts = mesAno.split('-');
      if (parts.length == 2) {
        final anio = int.parse(parts[0]);
        final mes = int.parse(parts[1]);
        
        final meses = [
          'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        
        return '${meses[mes - 1]} ${anio}';
      }
    } catch (e) {
      // Error al parsear
    }
    
    return mesAno;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildEstadisticas(),
        Expanded(
          child: Consumer<TarjaPropioProvider>(
            builder: (context, tarjaPropioProvider, child) {
              if (tarjaPropioProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                );
              }

              if (tarjaPropioProvider.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 80,
                        color: Colors.red.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar tarjas propios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tarjaPropioProvider.error!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _refrescarDatos,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              return _vistaActiva == 'detalle' 
                ? _buildTablaDetalle(tarjaPropioProvider)
                : _buildTablaResumen(tarjaPropioProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: 'Buscar por colaborador, labor o centro de costo...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Consumer<TarjaPropioProvider>(
                  builder: (context, provider, child) {
                    final tieneFiltrosActivos = _tieneFiltrosActivos(provider);
                    
                    return Container(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showFiltros = !_showFiltros;
                          });
                        },
                        icon: Icon(_showFiltros ? Icons.filter_list_off : Icons.filter_list),
                        label: Text(_showFiltros ? 'Ocultar filtros' : 'Mostrar filtros'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tieneFiltrosActivos ? Colors.orange : Colors.grey[500],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () => _cambiarVista(_vistaActiva == 'detalle' ? 'resumen' : 'detalle'),
                  icon: Icon(_vistaActiva == 'detalle' ? Icons.bar_chart : Icons.list),
                  label: Text(_vistaActiva == 'detalle' ? 'Resumen' : 'Detalle', style: const TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),
            ],
          ),
          if (_showFiltros) ...[
            const SizedBox(height: 12),
            _buildFiltrosAvanzados(),
          ],
        ],
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Consumer<TarjaPropioProvider>(
      builder: (context, provider, child) {
        // Usar los getters del provider igual que en Colaboradores
        final total = provider.totalTarjas;
        final creadas = provider.tarjasCreadas;
        final revisadas = provider.tarjasRevisadas;
        final aprobadas = provider.tarjasAprobadas;
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Total',
                  total.toString(),
                  Icons.assessment,
                  Colors.purple,
                  'todos',
                  _filtroActivo == null,
                  () => _aplicarFiltro(null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Creadas',
                  creadas.toString(),
                  Icons.create,
                  Colors.orange,
                  'creadas',
                  _filtroActivo == 'creadas',
                  () => _aplicarFiltro('creadas'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Revisadas',
                  revisadas.toString(),
                  Icons.check_circle,
                  Colors.blue,
                  'revisadas',
                  _filtroActivo == 'revisadas',
                  () => _aplicarFiltro('revisadas'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Aprobadas',
                  aprobadas.toString(),
                  Icons.verified,
                  Colors.green,
                  'aprobadas',
                  _filtroActivo == 'aprobadas',
                  () => _aplicarFiltro('aprobadas'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, IconData icono, Color color, String filtro, bool isActivo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActivo ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActivo ? color : Colors.grey.withOpacity(0.3),
            width: isActivo ? 2 : 1,
          ),
          boxShadow: isActivo ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActivo ? color.withOpacity(0.3) : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icono, color: isActivo ? color : color.withOpacity(0.8), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActivo ? color : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isActivo ? color : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFiltrosAvanzados() {
    return Consumer<TarjaPropioProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtros Avanzados',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildColaboradorField(provider),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSupervisorField(provider),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildCecoField(provider),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLaborField(provider),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMesField(provider),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAnoField(provider),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.limpiarFiltros();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Limpiar filtros'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildDateField(String label, DateTime? value, Function(DateTime?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  value != null 
                    ? DateFormat('dd/MM/yyyy').format(value)
                    : 'Seleccionar fecha',
                  style: TextStyle(
                    color: value != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColaboradorField(TarjaPropioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Colaborador',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Consumer<ColaboradorProvider>(
          builder: (context, colaboradorProvider, child) {
            return DropdownButtonFormField<String>(
              value: _getValidColaboradorValue(provider, colaboradorProvider),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Todos los colaboradores'),
                ),
                ...colaboradorProvider.colaboradores.map((colaborador) {
                  return DropdownMenuItem<String>(
                    value: colaborador.id,
                    child: Text(colaborador.nombreCompleto),
                  );
                }),
              ],
              onChanged: (value) {
                provider.setIdColaborador(value);
                // Limpiar supervisor cuando se cambia el colaborador
                if (value != null) {
                  provider.setIdSupervisor(null);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSupervisorField(TarjaPropioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supervisor',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _getValidSupervisorValue(provider),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Todos los supervisores'),
            ),
            ...provider.supervisoresUnicos.map((supervisor) {
              return DropdownMenuItem<String>(
                value: supervisor['id'],
                child: Text(supervisor['nombre']),
              );
            }),
          ],
          onChanged: (value) {
            provider.setIdSupervisor(value);
            // Limpiar colaborador cuando se cambia el supervisor
            if (value != null) {
              provider.setIdColaborador(null);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCecoField(TarjaPropioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CECO',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: provider.idCeco,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Todos los CECOs'),
            ),
            ...provider.cecosUnicos.map((ceco) {
              return DropdownMenuItem<int>(
                value: ceco['id'],
                child: Text(ceco['nombre']),
              );
            }),
          ],
          onChanged: (value) => provider.setIdCeco(value),
        ),
      ],
    );
  }

  Widget _buildLaborField(TarjaPropioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Labor',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: provider.idLabor,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Todas las labores'),
            ),
            ...provider.laboresUnicas.map((labor) {
              return DropdownMenuItem<int>(
                value: labor['id'],
                child: Text(labor['nombre']),
              );
            }),
          ],
          onChanged: (value) => provider.setIdLabor(value),
        ),
      ],
    );
  }


  Widget _buildEstadoField(TarjaPropioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: provider.idEstadoActividad,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem<int>(
              value: null,
              child: Text('Todos los Estados'),
            ),
            DropdownMenuItem<int>(
              value: 1,
              child: Text('Activa'),
            ),
            DropdownMenuItem<int>(
              value: 2,
              child: Text('Finalizada'),
            ),
            DropdownMenuItem<int>(
              value: 3,
              child: Text('Pausada'),
            ),
            DropdownMenuItem<int>(
              value: 4,
              child: Text('Cancelada'),
            ),
          ],
          onChanged: (value) => provider.setIdEstadoActividad(value),
        ),
      ],
    );
  }

  Widget _buildMesField(TarjaPropioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: provider.filtroMes,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Todos los meses'),
            ),
            ...provider.mesesUnicos.map((mes) {
              final nombresMeses = [
                'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
              ];
              return DropdownMenuItem<int>(
                value: mes,
                child: Text(nombresMeses[mes - 1]),
              );
            }),
          ],
          onChanged: (value) => provider.setFiltroMes(value),
        ),
      ],
    );
  }

  Widget _buildAnoField(TarjaPropioProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Año',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: provider.filtroAno,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Todos los años'),
            ),
            ...provider.anosUnicos.map((ano) {
              return DropdownMenuItem<int>(
                value: ano,
                child: Text(ano.toString()),
              );
            }),
          ],
          onChanged: (value) => provider.setFiltroAno(value),
        ),
      ],
    );
  }

  Widget _buildTablaDetalle(TarjaPropioProvider provider) {
    final tarjasFiltradas = _filtrarTarjas(provider.tarjasPropios);

    if (tarjasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tarjas propios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron registros con los filtros aplicados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Agrupar por mes-año
    final grupos = _agruparPorMesAno(tarjasFiltradas);
    final gruposOrdenados = grupos.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key)); // Ordenar por fecha descendente

    // Inicializar estado de expansión si es necesario
    if (_expansionState.length != gruposOrdenados.length) {
      _resetExpansionState(gruposOrdenados.length);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        key: _expansionKey,
        itemCount: gruposOrdenados.length,
        itemBuilder: (context, index) {
          final grupo = gruposOrdenados[index];
          final mesAno = grupo.key;
          final tarjas = grupo.value;
          final isExpanded = _expansionState[index];

          return ExpansionTile(
            initiallyExpanded: true,
            onExpansionChanged: (isExpanded) {
              if (_expansionState.length > index) {
                setState(() {
                  _expansionState[index] = isExpanded;
                });
              }
            },
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: Border(),
            collapsedShape: Border(),
            collapsedIconColor: AppTheme.primaryColor,
            iconColor: AppTheme.primaryColor,
            title: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatearMesAno(mesAno),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tarjas.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 100,
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: const Color(0xFFBDBDBD),
                      dividerTheme: const DividerThemeData(
                        color: Color(0xFFBDBDBD),
                        thickness: 1,
                        space: 0,
                      ),
                    ),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
                      dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.hovered)) {
                            return AppTheme.primaryColor.withOpacity(0.05);
                          }
                          return null;
                        },
                      ),
                      dividerThickness: 1,
                      border: TableBorder(
                        top: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                        bottom: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                        left: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                        right: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                        horizontalInside: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                        verticalInside: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                      ),
                    columnSpacing: 12,
                    horizontalMargin: 8,
                  columns: [
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.person, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Colaborador', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.supervisor_account, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Supervisor', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.work, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Labor', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.business, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('CECO', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.description, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Detalle CECO', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.straighten, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Unidad', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Rendimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.attach_money, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Tarifa', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataColumn(
                      label: Row(
                        children: [
                          Icon(Icons.payments, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          const Text('Líquido', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                  rows: tarjas.map((tarja) {
                    return DataRow(
                      cells: [
                        DataCell(Text(tarja.fechaFormateadaChilena)),
                        DataCell(Text(tarja.colaborador)),
                        DataCell(Text(tarja.usuario)),
                        DataCell(Text(tarja.labor)),
                        DataCell(Text(tarja.centroDeCosto)),
                        DataCell(Text(tarja.detalleCeco)),
                        DataCell(Text(tarja.unidad)),
                        DataCell(Text(tarja.rendimiento.toStringAsFixed(2))),
                        DataCell(Text(_formatearMoneda(tarja.tarifa))),
                        DataCell(Text(_formatearMoneda(tarja.liquidoTratoDia))),
                      ],
                    );
                  }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTablaResumen(TarjaPropioProvider provider) {
    final resumenFiltrado = _filtrarResumen(provider.resumenColaboradores);

    if (resumenFiltrado.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos de resumen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No se encontraron registros con los filtros aplicados',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 100,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: const Color(0xFFBDBDBD),
              dividerTheme: const DividerThemeData(
                color: Color(0xFFBDBDBD),
                thickness: 1,
                space: 0,
              ),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.1)),
              dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
                  if (states.contains(MaterialState.hovered)) {
                    return AppTheme.primaryColor.withOpacity(0.05);
                  }
                  return null;
                },
              ),
              dividerThickness: 1,
              border: TableBorder(
                top: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                bottom: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                left: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                right: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                horizontalInside: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
                verticalInside: const BorderSide(color: Color(0xFFBDBDBD), width: 1),
              ),
            columnSpacing: 12,
            horizontalMargin: 8,
            columns: [
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Colaborador', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.numbers, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Registros', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Total Horas', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.trending_up, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Total Rendimiento', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Total H.E.', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.attach_money, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Total Valor H.E.', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Total Líquido', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.analytics, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    const Text('Promedio Rend.', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          rows: resumenFiltrado.map((resumen) {
            return DataRow(
              cells: [
                DataCell(Text(resumen.colaborador)),
                DataCell(Text(resumen.totalRegistros.toString())),
                DataCell(Text(_formatearHora(resumen.totalHorasTrabajadas))),
                DataCell(Text(resumen.totalRendimiento.toStringAsFixed(2))),
                DataCell(Text(resumen.totalHorasExtras.toStringAsFixed(1))),
                DataCell(Text(_formatearMoneda(resumen.totalValorHe))),
                DataCell(Text(_formatearMoneda(resumen.totalLiquidoTratoDia))),
                DataCell(Text(resumen.promedioRendimiento.toStringAsFixed(2))),
              ],
            );
          }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String? _getValidSupervisorValue(TarjaPropioProvider provider) {
    final currentValue = provider.idSupervisor;
    if (currentValue == null) return null;
    
    // Verificar si el valor actual existe en la lista de opciones
    final supervisores = provider.supervisoresUnicos;
    final exists = supervisores.any((supervisor) => supervisor['id'] == currentValue);
    
    return exists ? currentValue : null;
  }

  String? _getValidColaboradorValue(TarjaPropioProvider provider, ColaboradorProvider colaboradorProvider) {
    final currentValue = provider.idColaborador;
    if (currentValue == null) return null;
    
    // Verificar si el valor actual existe en la lista de opciones
    final colaboradores = colaboradorProvider.colaboradores;
    final exists = colaboradores.any((colaborador) => colaborador.id == currentValue);
    
    return exists ? currentValue : null;
  }

}