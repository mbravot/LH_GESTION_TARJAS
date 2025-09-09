import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/horas_extras_otroscecos_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/horas_trabajadas_provider.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/tarja_provider.dart';
import 'horas_extras_otroscecos_crear_screen.dart';
import 'horas_extras_otroscecos_editar_screen.dart';
import '../models/horas_extras_otroscecos.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/dark_theme_colors.dart';

class HorasExtrasOtrosCecosScreen extends StatefulWidget {
  const HorasExtrasOtrosCecosScreen({Key? key}) : super(key: key);

  @override
  State<HorasExtrasOtrosCecosScreen> createState() => _HorasExtrasOtrosCecosScreenState();
}

class _HorasExtrasOtrosCecosScreenState extends State<HorasExtrasOtrosCecosScreen> {
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'futuras', 'hoy', 'pasadas'
  
  // Variables para agrupación
  List<bool> _expansionState = [];
  final GlobalKey _expansionKey = GlobalKey();
  
  // Variables para agrupación por mes-año
  Map<String, List<HorasExtrasOtrosCecos>> _horasExtrasAgrupadas = {};
  List<String> _mesesAnos = [];
  

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final provider = Provider.of<HorasExtrasOtrosCecosProvider>(context, listen: false);
    provider.setFiltroEstado(filtro);
  }

  // Función para formatear mes-año
  String _formatearMesAno(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  // Función para agrupar por mes-año
  void _agruparPorMesAno(List<HorasExtrasOtrosCecos> horasExtras) {
    _horasExtrasAgrupadas.clear();
    _mesesAnos.clear();
    
    for (final hora in horasExtras) {
      final mesAno = _formatearMesAno(hora.fecha);
      if (!_horasExtrasAgrupadas.containsKey(mesAno)) {
        _horasExtrasAgrupadas[mesAno] = [];
        _mesesAnos.add(mesAno);
      }
      _horasExtrasAgrupadas[mesAno]!.add(hora);
    }
    
    // Ordenar meses de más reciente a más antiguo
    _mesesAnos.sort((a, b) {
      final fechaA = _horasExtrasAgrupadas[a]!.first.fecha;
      final fechaB = _horasExtrasAgrupadas[b]!.first.fecha;
      return fechaB.compareTo(fechaA);
    });
  }

  // Función para resetear estado de expansión
  void _resetExpansionState() {
    _expansionState = List.filled(_mesesAnos.length, false);
  }


  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final provider = context.read<HorasExtrasOtrosCecosProvider>();
      
      // Configurar el provider para escuchar cambios de sucursal
      provider.setAuthProvider(authProvider);
      
      // Cargar datos
      provider.cargarHorasExtras();
      provider.cargarOpciones();
    });
  }

  Future<void> _refrescarDatos() async {
    // Actualizar todos los providers relevantes
    final horasExtrasOtrosCecosProvider = Provider.of<HorasExtrasOtrosCecosProvider>(context, listen: false);
    final horasTrabajadasProvider = Provider.of<HorasTrabajadasProvider>(context, listen: false);
    final horasExtrasProvider = Provider.of<HorasExtrasProvider>(context, listen: false);
    final tarjaProvider = Provider.of<TarjaProvider>(context, listen: false);
    
    // Cargar datos en paralelo para mejor rendimiento
    await Future.wait([
      horasExtrasOtrosCecosProvider.cargarHorasExtras(),
      horasExtrasOtrosCecosProvider.cargarOpciones(),
      horasTrabajadasProvider.cargarHorasTrabajadas(),
      horasExtrasProvider.cargarRendimientos(),
      tarjaProvider.cargarTarjas(),
    ]);
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_showFiltros) ...[
          const SizedBox(height: 12),
          _buildFiltrosAvanzados(),
        ],
        _buildEstadisticas(),
        Expanded(
          child: Consumer<HorasExtrasOtrosCecosProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (provider.error != null && provider.error!.isNotEmpty) {
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
                        'Error al cargar horas extras otros CECOs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => provider.cargarHorasExtras(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              return _buildListaHorasExtrasOtrosCecos(provider);
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
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              final provider = Provider.of<HorasExtrasOtrosCecosProvider>(context, listen: false);
              provider.setFiltroBusqueda(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar por colaborador, tipo CECO, CECO o fecha...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        final provider = Provider.of<HorasExtrasOtrosCecosProvider>(context, listen: false);
                        provider.setFiltroBusqueda('');
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFiltros = !_showFiltros;
                    });
                  },
                  icon: Icon(_showFiltros ? Icons.filter_list_off : Icons.filter_list),
                  label: Text(_showFiltros ? 'Ocultar filtros' : 'Mostrar filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HorasExtrasOtrosCecosCrearScreen(),
                      ),
                    );
                    if (result == true) {
                      await _refrescarDatos();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

      Widget _buildFiltrosAvanzados() {
    return Consumer<HorasExtrasOtrosCecosProvider>(
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
                    child: DropdownButtonFormField<String>(
                      value: provider.filtroColaborador.isEmpty ? null : provider.filtroColaborador,
                      decoration: const InputDecoration(
                        labelText: 'Colaborador',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los colaboradores'),
                        ),
                        ...provider.colaboradoresUnicos.map((colaborador) {
                          return DropdownMenuItem<String>(
                            value: colaborador,
                            child: Text(colaborador),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroColaborador(value ?? '');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.filtroCecoTipo.isEmpty ? null : provider.filtroCecoTipo,
                      decoration: const InputDecoration(
                        labelText: 'Tipo CECO',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los tipos'),
                        ),
                        ...provider.tiposCecoUnicos.map((tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroCecoTipo(value ?? '');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.filtroCeco.isEmpty ? null : provider.filtroCeco,
                      decoration: const InputDecoration(
                        labelText: 'CECO',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los CECOs'),
                        ),
                        ...provider.cecosUnicos.map((ceco) {
                          return DropdownMenuItem<String>(
                            value: ceco,
                            child: Text(ceco),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroCeco(value ?? '');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Fecha Inicio',
                      value: provider.fechaInicio,
                      onChanged: (date) {
                        provider.setFechaInicio(date);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Fecha Fin',
                      value: provider.fechaFin,
                      onChanged: (date) {
                        provider.setFechaFin(date);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        provider.limpiarFiltros();
                        setState(() {
                          _searchQuery = '';
                        });
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.cargarHorasExtras();
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Aplicar filtros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
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

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          locale: const Locale('es', 'ES'),
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}'
              : 'Seleccionar fecha',
          style: TextStyle(
            color: value != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticas() {
    return Consumer<HorasExtrasOtrosCecosProvider>(
      builder: (context, provider, child) {
        final stats = provider.estadisticas;
        
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  titulo: 'Total',
                  valor: stats['total']?.toString() ?? '0',
                  color: Colors.purple,
                  icono: Icons.list,
                  filtro: 'todos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  titulo: 'Futuras',
                  valor: stats['futuras']?.toString() ?? '0',
                  color: Colors.blue,
                  icono: Icons.schedule,
                  filtro: 'futuras',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  titulo: 'Hoy',
                  valor: stats['hoy']?.toString() ?? '0',
                  color: Colors.green,
                  icono: Icons.today,
                  filtro: 'hoy',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  titulo: 'Pasadas',
                  valor: stats['pasadas']?.toString() ?? '0',
                  color: Colors.orange,
                  icono: Icons.history,
                  filtro: 'pasadas',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaEstadistica({
    required String titulo,
    required String valor,
    required Color color,
    required IconData icono,
    required String filtro,
  }) {
    final isActivo = _filtroActivo == filtro;
    
    return GestureDetector(
      onTap: () => _aplicarFiltro(filtro),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActivo ? color.withOpacity(0.2) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActivo ? color : color.withOpacity(0.3),
            width: isActivo ? 2 : 1,
          ),
          boxShadow: isActivo ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
                fontWeight: isActivo ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (isActivo) ...[
              const SizedBox(height: 4),
              Container(
                width: 20,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  Widget _buildListaHorasExtrasOtrosCecos(HorasExtrasOtrosCecosProvider provider) {
    final horasExtras = provider.horasExtrasFiltradas;
    
    if (horasExtras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.work_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No se encontraron resultados para "$_searchQuery"'
                  : 'No hay horas extras otros CECOs disponibles',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                  });
                  provider.setFiltroBusqueda('');
                },
                child: const Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      );
    }

    // Agrupar por mes-año
    _agruparPorMesAno(horasExtras);
    _resetExpansionState();

    return _buildListaHorasExtrasOtrosCecosAgrupados();
  }

  Widget _buildListaHorasExtrasOtrosCecosAgrupados() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mesesAnos.length,
      itemBuilder: (context, index) {
        final mesAno = _mesesAnos[index];
        final horasExtras = _horasExtrasAgrupadas[mesAno]!;
        
        return ExpansionTile(
          key: ValueKey(mesAno),
          initiallyExpanded: true,
          onExpansionChanged: (expanded) {
            setState(() {
              if (index < _expansionState.length) {
                _expansionState[index] = expanded;
              }
            });
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
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                mesAno,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${horasExtras.length}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          children: horasExtras.map((horasExtra) {
            return _buildHorasExtraCard(horasExtra);
          }).toList(),
        );
      },
    );
  }

  Widget _buildHorasExtraCard(HorasExtrasOtrosCecos horasExtra) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    final borderColor = Colors.green[300]!;
    final textColor = theme.colorScheme.onSurface;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetallesHorasExtra(horasExtra),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono y nombre del colaborador
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: horasExtra.estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      horasExtra.estadoIcono,
                      color: horasExtra.estadoColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      horasExtra.nombreColaborador,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Contenido en 5 columnas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1: Fecha
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fecha: ${horasExtra.fechaFormateadaEspanolCompleta}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 2: Cantidad
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Cantidad: ${horasExtra.cantidadFormateada}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 3: Tipo CECO
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.category, color: Colors.purple, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tipo: ${horasExtra.nombreCecoTipo}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 4: CECO
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.business, color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'CECO: ${horasExtra.nombreCeco}',
                                style: TextStyle(
                                  color: textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 5: Acciones
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HorasExtrasOtrosCecosEditarScreen(
                                      horasExtrasOtrosCecos: horasExtra,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  await _refrescarDatos();
                                }
                              },
                              icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                              tooltip: 'Editar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _confirmarEliminar(horasExtra),
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              tooltip: 'Eliminar',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDetallesHorasExtra(HorasExtrasOtrosCecos horasExtra) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con avatar y nombre
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
                        ),
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horas Extras Otros CECOS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            horasExtra.nombreColaborador,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido con información
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Información de las horas extras
                      _buildInfoSection(
                        'Información de Horas Extras',
                        Icons.schedule,
                        [
                          _buildModernInfoRow('Fecha', horasExtra.fechaFormateadaEspanolCompleta, Icons.calendar_today),
                          _buildModernInfoRow('Cantidad', horasExtra.cantidadFormateada, Icons.access_time),
                          _buildModernInfoRow('Tipo CECO', horasExtra.nombreCecoTipo, Icons.category),
                          _buildModernInfoRow('CECO', horasExtra.nombreCeco, Icons.business),
                          _buildModernInfoRow('Estado', horasExtra.estadoTexto, Icons.info),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Botones de acción
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Cerrar', style: TextStyle(color: Colors.red)),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(String label, String value, IconData icon) {
    // Definir colores para diferentes tipos de iconos
    Color iconColor;
    Color backgroundColor;
    
    // Comparar directamente con los iconos
    if (icon == Icons.calendar_today) {
      iconColor = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (icon == Icons.access_time) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (icon == Icons.info) {
      iconColor = Colors.purple;
      backgroundColor = Colors.purple.withOpacity(0.1);
    } else if (icon == Icons.category) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.business) {
      iconColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else {
      iconColor = AppTheme.primaryColor;
      backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminar(HorasExtrasOtrosCecos horasExtra) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Está seguro de que desea eliminar las horas extras de ${horasExtra.nombreColaborador} del ${horasExtra.fechaFormateadaCorta}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.eliminarHorasExtrasOtrosCecos(horasExtra.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Horas extras otros CECOs eliminadas exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          await _refrescarDatos();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar horas extras otros CECOs: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}


