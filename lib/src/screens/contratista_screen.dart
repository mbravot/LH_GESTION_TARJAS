import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contratista_provider.dart';
import '../providers/auth_provider.dart';
import '../models/contratista.dart';
import '../theme/app_theme.dart';
import 'contratista_crear_screen.dart';
import 'contratista_editar_screen.dart';

class ContratistaScreen extends StatefulWidget {
  const ContratistaScreen({Key? key}) : super(key: key);

  @override
  State<ContratistaScreen> createState() => _ContratistaScreenState();
}

class _ContratistaScreenState extends State<ContratistaScreen> {
  String _searchQuery = '';
  bool _showFiltros = false;
  String _filtroActivo = 'todos'; // 'todos', 'activos', 'inactivos', 'suspendidos'

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  bool _tieneFiltrosActivos(ContratistaProvider provider) {
    // Los indicadores no son filtros avanzados, solo considerar filtros de búsqueda
    return provider.filtroBusqueda.isNotEmpty;
  }

  void _aplicarFiltro(String filtro) {
    setState(() {
      _filtroActivo = filtro;
    });
    
    final provider = Provider.of<ContratistaProvider>(context, listen: false);
    switch (filtro) {
      case 'activos':
        provider.setFiltroEstado('ACTIVO');
        break;
      case 'inactivos':
        provider.setFiltroEstado('INACTIVO');
        break;
      default: // 'todos'
        provider.setFiltroEstado('');
        break;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    final provider = Provider.of<ContratistaProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    provider.setAuthProvider(authProvider);

    // Usar Future.delayed para evitar el error de setState durante build
    Future.delayed(Duration.zero, () async {
      await provider.cargarContratistas();
      await provider.cargarOpciones();
    });
  }

  Future<void> _refrescarDatos() async {
    final provider = Provider.of<ContratistaProvider>(context, listen: false);
    await provider.cargarContratistas();
    await provider.cargarOpciones();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildEstadisticas(),
        Expanded(
          child: _buildListaContratistas(),
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
              final provider = Provider.of<ContratistaProvider>(context, listen: false);
              provider.setFiltroBusqueda(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, RUT, email o teléfono...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        final provider = Provider.of<ContratistaProvider>(context, listen: false);
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
                child: Consumer<ContratistaProvider>(
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ContratistaCrearScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo', style: TextStyle(fontSize: 14)),
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
    return Consumer<ContratistaProvider>(
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
                      value: provider.filtroEstado.isEmpty ? null : provider.filtroEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos los estados'),
                        ),
                        ...provider.estadosUnicos.map((estado) {
                          return DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        provider.setFiltroEstado(value ?? '');
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
                        provider.cargarContratistas();
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

  Widget _buildEstadisticas() {
    return Consumer<ContratistaProvider>(
      builder: (context, provider, child) {
        final stats = provider.estadisticas;

        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildTarjetaEstadistica(
                  titulo: 'Total',
                  valor: stats['total'].toString(),
                  color: Colors.purple,
                  icono: Icons.people,
                  filtro: 'todos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  titulo: 'Activos',
                  valor: stats['activos'].toString(),
                  color: Colors.green,
                  icono: Icons.check_circle,
                  filtro: 'activos',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTarjetaEstadistica(
                  titulo: 'Inactivos',
                  valor: stats['inactivos'].toString(),
                  color: Colors.red,
                  icono: Icons.cancel,
                  filtro: 'inactivos',
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

  Widget _buildListaContratistas() {
    return Consumer<ContratistaProvider>(
      builder: (context, provider, child) {
        final contratistas = provider.contratistasFiltradas;

        if (contratistas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay contratistas registrados',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los contratistas aparecerán aquí cuando se carguen datos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contratistas.length,
          itemBuilder: (context, index) {
            final contratista = contratistas[index];
            return _buildContratistaCard(contratista);
          },
        );
      },
    );
  }

  Widget _buildContratistaCard(Contratista contratista) {
    final cardColor = Theme.of(context).colorScheme.surface;
    // Color del borde según el estado del contratista
    final borderColor = contratista.esActivo ? Colors.green[300]! : Colors.red[300]!;
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _mostrarDetallesContratista(contratista),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título del contratista
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: contratista.esActivo ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      contratista.esActivo ? Icons.groups : Icons.group_off,
                      color: contratista.esActivo ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      contratista.nombreCompleto,
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
              // Contenido en 3 columnas
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
                                'RUT: ${contratista.rutCompleto}',
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
                  // Columna 2: Cantidad de trabajadores activos
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.purple, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contratista.cantidadTrabajadoresTexto,
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
                  // Columna 3: Estado, Desactivar/Activar, Editar
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: contratista.esActivo ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: contratista.esActivo ? Colors.green : Colors.red,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            contratista.estadoTexto,
                            style: TextStyle(
                              color: contratista.esActivo ? Colors.green[800] : Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (contratista.esActivo) ...[
                          IconButton(
                            onPressed: () => _confirmarDesactivarContratista(contratista),
                            icon: Icon(Icons.person_off, color: Colors.orange, size: 20),
                            tooltip: 'Desactivar contratista',
                          ),
                        ] else ...[
                          IconButton(
                            onPressed: () => _confirmarActivarContratista(contratista),
                            icon: Icon(Icons.person_add, color: Colors.green, size: 20),
                            tooltip: 'Activar contratista',
                          ),
                        ],
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContratistaEditarScreen(contratista: contratista),
                              ),
                            );
                          },
                          icon: Icon(Icons.edit, color: AppTheme.primaryColor, size: 20),
                          tooltip: 'Editar contratista',
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

  void _mostrarDetallesContratista(Contratista contratista) {
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
                        Icons.business,
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
                            contratista.nombreCompleto,
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
                              color: contratista.esActivo 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: contratista.esActivo 
                                  ? Colors.green 
                                  : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              contratista.estadoTexto,
                              style: TextStyle(
                                color: contratista.esActivo 
                                  ? Colors.green[700] 
                                  : Colors.red[700],
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
                      // Información básica
                      _buildInfoSection(
                        'Información Básica',
                        Icons.business_outlined,
                        [
                          _buildModernInfoRow('RUT', contratista.rutCompleto, Icons.badge, color: Colors.blue),
                          _buildModernInfoRow('Trabajadores Activos', contratista.cantidadTrabajadoresTexto, Icons.people, color: Colors.purple),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Información de contacto
                      if (contratista.tieneEmail || contratista.tieneTelefono || contratista.tieneDireccion)
                        _buildInfoSection(
                          'Información de Contacto',
                          Icons.contact_phone,
                          [
                            if (contratista.tieneEmail) _buildModernInfoRow('Email', contratista.email!, Icons.email),
                            if (contratista.tieneTelefono) _buildModernInfoRow('Teléfono', contratista.telefono!, Icons.phone),
                            if (contratista.tieneDireccion) _buildModernInfoRow('Dirección', contratista.direccion!, Icons.location_on),
                          ],
                        ),
                      
                      if (contratista.tieneEmail || contratista.tieneTelefono || contratista.tieneDireccion)
                        const SizedBox(height: 20),
                      
                      // Fechas
                      if (contratista.tieneFechaNacimiento || contratista.tieneFechaIncorporacion)
                        _buildInfoSection(
                          'Fechas',
                          Icons.calendar_today,
                          [
                            if (contratista.tieneFechaNacimiento) _buildModernInfoRow('Fecha de Nacimiento', contratista.fechaNacimientoFormateadaEspanol, Icons.cake),
                            if (contratista.tieneFechaIncorporacion) _buildModernInfoRow('Fecha de Incorporación', contratista.fechaIncorporacionFormateadaEspanol, Icons.work),
                          ],
                        ),
                      
                      if (contratista.tieneFechaNacimiento || contratista.tieneFechaIncorporacion)
                        const SizedBox(height: 20),
                      
                      // Observaciones
                      if (contratista.observaciones != null && contratista.observaciones!.isNotEmpty)
                        _buildInfoSection(
                          'Observaciones',
                          Icons.note,
                          [
                            _buildModernInfoRow('Observaciones', contratista.observaciones!, Icons.note),
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
                        icon: const Icon(Icons.close),
                        label: const Text('Cerrar'),
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
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (_) => ContratistaEditarScreen(contratista: contratista),
                             ),
                           );
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

  Widget _buildModernInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color?.withOpacity(0.1) ?? Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color ?? Colors.grey[600],
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

   void _confirmarDesactivarContratista(Contratista contratista) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Confirmar Desactivación'),
         content: Text(
           '¿Estás seguro de que quieres desactivar a ${contratista.nombreCompleto}?',
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancelar'),
           ),
           ElevatedButton(
             onPressed: () async {
               Navigator.pop(context);
               final provider = Provider.of<ContratistaProvider>(context, listen: false);
               final success = await provider.desactivarContratista(contratista.id);
               if (success) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('Contratista desactivado correctamente'),
                     backgroundColor: Colors.orange,
                   ),
                 );
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Error al desactivar: ${provider.error}'),
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

   void _confirmarActivarContratista(Contratista contratista) {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Confirmar Activación'),
         content: Text(
           '¿Estás seguro de que quieres activar a ${contratista.nombreCompleto}?',
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancelar'),
           ),
           ElevatedButton(
             onPressed: () async {
               Navigator.pop(context);
               final provider = Provider.of<ContratistaProvider>(context, listen: false);
               final success = await provider.activarContratista(contratista.id);
               if (success) {
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                     content: Text('Contratista activado correctamente'),
                     backgroundColor: Colors.green,
                   ),
                 );
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(
                     content: Text('Error al activar: ${provider.error}'),
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

 }
