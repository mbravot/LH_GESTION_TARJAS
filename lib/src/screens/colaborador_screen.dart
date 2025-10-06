import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/auth_provider.dart';
import '../models/colaborador.dart';
import '../theme/app_theme.dart';
import '../theme/dark_theme_colors.dart';
import '../services/api_service.dart';
import 'colaborador_crear_screen.dart';
import 'colaborador_editar_screen.dart';

class ColaboradorScreen extends StatefulWidget {
  const ColaboradorScreen({super.key});

  @override
  State<ColaboradorScreen> createState() => _ColaboradorScreenState();
}

class _ColaboradorScreenState extends State<ColaboradorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'activos', 'inactivos', 'finiquitados', 'preenrolados'

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  bool _tieneFiltrosActivos(ColaboradorProvider provider) {
    return provider.filtroBusqueda.isNotEmpty;
  }

  void _cargarDatosIniciales() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final colaboradorProvider = context.read<ColaboradorProvider>();
      
      // Configurar el ColaboradorProvider para escuchar cambios de sucursal
      colaboradorProvider.setAuthProvider(authProvider);
      colaboradorProvider.cargarColaboradores();
    });
  }

  // Método para refrescar datos desde el AppBar
  Future<void> _refrescarDatos() async {
    final colaboradorProvider = context.read<ColaboradorProvider>();
    await colaboradorProvider.cargarColaboradores();
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
    final colaboradorProvider = context.read<ColaboradorProvider>();
    colaboradorProvider.setFiltroBusqueda(query);
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final colaboradorProvider = context.read<ColaboradorProvider>();
    switch (filtro) {
      case 'activos':
        colaboradorProvider.setFiltroEstado('1');
        break;
      case 'inactivos':
        colaboradorProvider.setFiltroEstado('2');
        break;
      case 'finiquitados':
        colaboradorProvider.setFiltroEstado('finiquitados');
        break;
      case 'preenrolados':
        colaboradorProvider.setFiltroEstado('preenrolados');
        break;
      default: // 'todos'
        colaboradorProvider.setFiltroEstado('todos');
        break;
    }
  }

  List<Colaborador> _filtrarColaboradores(List<Colaborador> colaboradores) {
    if (_searchQuery.isEmpty) {
      return colaboradores;
    }
    
    return colaboradores.where((colaborador) {
      return colaborador.nombreCompleto.toLowerCase().contains(_searchQuery) ||
             colaborador.rutCompleto.toLowerCase().contains(_searchQuery);
    }).toList();
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
              hintText: 'Buscar por nombre o RUT',
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
                child: Consumer<ColaboradorProvider>(
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
                  onPressed: () => _mostrarDialogoCrearColaborador(),
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Nuevo Colaborador', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
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

  Widget _buildFiltrosAvanzados() {
    return Consumer<ColaboradorProvider>(
      builder: (context, colaboradorProvider, child) {
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
                      value: colaboradorProvider.filtroEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'todos',
                          child: Text('Todos'),
                        ),
                        DropdownMenuItem<String>(
                          value: '1',
                          child: Text('Activo'),
                        ),
                        DropdownMenuItem<String>(
                          value: '2',
                          child: Text('Inactivo'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'finiquitados',
                          child: Text('Finiquitados'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'preenrolados',
                          child: Text('Pre-enrolados'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          colaboradorProvider.setFiltroEstado(value);
                        }
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
                        colaboradorProvider.limpiarFiltros();
                        _searchController.clear();
                        _onSearchChanged('');
                        setState(() {
                          _filtroActivo = 'todos';
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticas() {
    return Consumer<ColaboradorProvider>(
      builder: (context, colaboradorProvider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Total',
                  colaboradorProvider.totalColaboradores.toString(),
                  Icons.people,
                  Colors.purple,
                  'todos',
                  colaboradorProvider.totalColaboradores > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Activos',
                  colaboradorProvider.colaboradoresActivos.toString(),
                  Icons.check_circle,
                  Colors.green,
                  'activos',
                  colaboradorProvider.colaboradoresActivos > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Inactivos',
                  colaboradorProvider.colaboradoresInactivos.toString(),
                  Icons.cancel,
                  Colors.red,
                  'inactivos',
                  colaboradorProvider.colaboradoresInactivos > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Finiquitados',
                  colaboradorProvider.colaboradoresFiniquitados.toString(),
                  Icons.exit_to_app,
                  Colors.orange,
                  'finiquitados',
                  colaboradorProvider.colaboradoresFiniquitados > 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTarjetaEstadistica(
                  'Pre-enrolados',
                  colaboradorProvider.colaboradoresPreenrolados.toString(),
                  Icons.person_add_alt_1,
                  Colors.blue,
                  'preenrolados',
                  colaboradorProvider.colaboradoresPreenrolados > 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTarjetaEstadistica(String titulo, String valor, IconData icono, Color color, String filtro, bool tieneDatos) {
    final isActivo = _filtroActivo == filtro;
    
    return GestureDetector(
      onTap: () => _aplicarFiltro(filtro),
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

  Widget _buildColaboradorCard(Colaborador colaborador) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.colorScheme.surface;
    // Color del borde según el indicador activo (filtro seleccionado)
    final borderColor = _getIndicadorColor(_filtroActivo).withOpacity(0.6);
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
        onTap: () => _mostrarDetallesColaborador(colaborador),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la actividad
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colaborador.idEstado == '1' ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      colaborador.idEstado == '1' ? Icons.person : Icons.person_off,
                      color: colaborador.idEstado == '1' ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      colaborador.nombreCompleto,
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
              // Contenido en 8 columnas (agregando sueldo base)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna 1: RUT
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge, color: Colors.blue, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'RUT: ${colaborador.rutCompleto}',
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
                  // Columna 2: Cargo
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (colaborador.cargoText != 'Sin cargo') ...[
                          Row(
                            children: [
                              Icon(Icons.work, color: Colors.purple, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cargo: ${colaborador.cargoText}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(Icons.work, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cargo: Sin cargo',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 3: Fecha incorporación
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (colaborador.fechaIncorporacion != null) ...[
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Incorporación: ${colaborador.fechaIncorporacionFormateadaEspanol}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Incorporación: Sin fecha',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 4: Fecha finiquito
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.event_busy, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Finiquito: ${colaborador.fechaFiniquitoFormateadaEspanol}',
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
                  // Columna 5: Sueldo Base
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (colaborador.sueldobase != null) ...[
                          Row(
                            children: [
                              Icon(Icons.attach_money, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sueldo Base: ${colaborador.sueldobaseFormateado}',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(Icons.attach_money, color: Colors.grey, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sueldo Base: Sin información',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Columna 6: Estado, Desactivar/Activar, Editar
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colaborador.idEstado == '1' ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colaborador.idEstado == '1' ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            colaborador.estadoText,
                            style: TextStyle(
                              color: colaborador.idEstado == '1' ? Colors.green[800] : Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (colaborador.idEstado == '1') ...[
                          IconButton(
                            onPressed: () => _confirmarDesactivarColaborador(colaborador),
                            icon: Icon(Icons.person_off, color: Colors.orange, size: 20),
                            tooltip: 'Desactivar colaborador',
                          ),
                        ] else ...[
                          IconButton(
                            onPressed: () => _confirmarActivarColaborador(colaborador),
                            icon: Icon(Icons.person_add, color: Colors.green, size: 20),
                            tooltip: 'Activar colaborador',
                          ),
                        ],
                        IconButton(
                          onPressed: () => _mostrarDialogoEditarColaborador(colaborador),
                          icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                          tooltip: 'Editar colaborador',
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

  void _mostrarDetallesColaborador(Colaborador colaborador) {
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
                      child: Icon(
                        Icons.person,
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
                            colaborador.nombreCompleto,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: colaborador.estadoText == 'ACTIVO' 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colaborador.estadoText == 'ACTIVO' 
                                  ? Colors.green 
                                  : Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              colaborador.estadoText,
                              style: TextStyle(
                                color: colaborador.estadoText == 'ACTIVO' 
                                  ? Colors.green[700] 
                                  : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
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
                      // Información personal
                      _buildInfoSection(
                        'Información Personal',
                        Icons.person_outline,
                        [
                          _buildModernInfoRow('RUT', colaborador.rutCompleto, Icons.badge),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Información laboral
                      _buildInfoSection(
                        'Información Laboral',
                        Icons.work_outline,
                        [
                          if (colaborador.sucursalText != 'Sin sucursal')
                            _buildModernInfoRow('Sucursal', colaborador.sucursalText, Icons.business),
                          if (colaborador.cargoText != 'Sin cargo')
                            _buildModernInfoRow('Cargo', colaborador.cargoText, Icons.work),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Información de sueldo base
                      if (colaborador.sueldobase != null || colaborador.baseDia != null || colaborador.horaDia != null)
                        _buildInfoSection(
                          'Información de Sueldo Base',
                          Icons.attach_money,
                          [
                            if (colaborador.sueldobase != null)
                              _buildModernInfoRow('Sueldo Base', colaborador.sueldobaseFormateado, Icons.attach_money),
                            if (colaborador.baseDia != null)
                              _buildModernInfoRow('Base Día', colaborador.baseDiaFormateada, Icons.calendar_view_day),
                            if (colaborador.horaDia != null)
                              _buildModernInfoRow('Hora Día', colaborador.horaDiaFormateada, Icons.access_time),
                            if (colaborador.fechaSueldobase != null)
                              _buildModernInfoRow('Fecha Sueldo Base', colaborador.fechaSueldobaseFormateadaEspanol, Icons.calendar_today),
                          ],
                        ),
                      
                      if (colaborador.sueldobase != null || colaborador.baseDia != null || colaborador.horaDia != null)
                        const SizedBox(height: 20),
                      
                      // Fechas
                      _buildInfoSection(
                        'Fechas',
                        Icons.calendar_today,
                        [
                          if (colaborador.fechaNacimiento != null)
                            _buildModernInfoRow('Fecha Nacimiento', colaborador.fechaNacimientoFormateadaEspanol, Icons.cake),
                          if (colaborador.fechaIncorporacion != null)
                            _buildModernInfoRow('Fecha Incorporación', colaborador.fechaIncorporacionFormateadaEspanol, Icons.event_available),
                          _buildModernInfoRow('Fecha Finiquito', colaborador.fechaFiniquitoFormateadaEspanol, Icons.event_busy),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Información de previsión
                      _buildInfoSection(
                        'Previsión',
                        Icons.health_and_safety,
                        [
                          if (colaborador.previsionText != 'Sin previsión')
                            _buildModernInfoRow('Previsión', colaborador.previsionText, Icons.local_hospital),
                          if (colaborador.afpText != 'Sin AFP')
                            _buildModernInfoRow('AFP', colaborador.afpText, Icons.account_balance),
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarDialogoEditarColaborador(colaborador);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
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
    Color iconColor;
    Color backgroundColor;
    
    if (icon == Icons.badge) {
      iconColor = Colors.blue;
      backgroundColor = Colors.blue.withOpacity(0.1);
    } else if (icon == Icons.business) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.work) {
      iconColor = Colors.orange;
      backgroundColor = Colors.orange.withOpacity(0.1);
    } else if (icon == Icons.cake) {
      iconColor = Colors.pink;
      backgroundColor = Colors.pink.withOpacity(0.1);
    } else if (icon == Icons.event_available) {
      iconColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
    } else if (icon == Icons.event_busy) {
      iconColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
    } else if (icon == Icons.local_hospital) {
      iconColor = Colors.teal;
      backgroundColor = Colors.teal.withOpacity(0.1);
    } else if (icon == Icons.account_balance) {
      iconColor = Colors.indigo;
      backgroundColor = Colors.indigo.withOpacity(0.1);
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

  void _confirmarDesactivarColaborador(Colaborador colaborador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Desactivación'),
        content: Text(
          '¿Estás seguro de que quieres desactivar a ${colaborador.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final colaboradorProvider = context.read<ColaboradorProvider>();
              final success = await colaboradorProvider.desactivarColaborador(colaborador.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Colaborador desactivado correctamente'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al desactivar: ${colaboradorProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  void _confirmarActivarColaborador(Colaborador colaborador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Activación'),
        content: Text(
          '¿Estás seguro de que quieres activar a ${colaborador.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final colaboradorProvider = context.read<ColaboradorProvider>();
              final success = await colaboradorProvider.activarColaborador(colaborador.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Colaborador activado correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al activar: ${colaboradorProvider.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }



  void _mostrarDialogoEditarColaborador(Colaborador colaborador) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColaboradorEditarScreen(colaborador: colaborador),
      ),
    );
    
    // Si se editó exitosamente un colaborador, refrescar la lista
    if (result == true) {
      final colaboradorProvider = context.read<ColaboradorProvider>();
      await colaboradorProvider.cargarColaboradores();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildEstadisticas(),
        Expanded(
          child: Consumer<ColaboradorProvider>(
            builder: (context, colaboradorProvider, child) {
              if (colaboradorProvider.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (colaboradorProvider.error != null) {
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
                        'Error al cargar colaboradores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        colaboradorProvider.error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.red.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => colaboradorProvider.cargarColaboradores(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }

              final colaboradoresFiltrados = colaboradorProvider.colaboradoresFiltrados;

              if (colaboradoresFiltrados.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay colaboradores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primer colaborador para comenzar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _mostrarDialogoCrearColaborador(),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Colaborador'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: colaboradoresFiltrados.length,
                itemBuilder: (context, index) {
                  return _buildColaboradorCard(colaboradoresFiltrados[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _mostrarDialogoCrearColaborador() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ColaboradorCrearScreen(),
      ),
    );
    
    // Si se creó exitosamente un colaborador, refrescar la lista
    if (result == true) {
      final colaboradorProvider = context.read<ColaboradorProvider>();
      await colaboradorProvider.cargarColaboradores();
    }
  }

  // Método para obtener el color del indicador activo
  Color _getIndicadorColor(String filtro) {
    switch (filtro) {
      case 'todos':
        return Colors.green; // Las tarjetas serán verdes cuando "Total" esté activo
      case 'activos':
        return Colors.green;
      case 'inactivos':
        return Colors.red;
      case 'finiquitados':
        return Colors.orange;
      case 'preenrolados':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
