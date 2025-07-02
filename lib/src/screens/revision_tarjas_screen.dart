import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../models/tarja.dart';
import '../providers/auth_provider.dart';
import '../providers/tarja_provider.dart';

class RevisionTarjasScreen extends StatefulWidget {
  const RevisionTarjasScreen({super.key});

  @override
  State<RevisionTarjasScreen> createState() => _RevisionTarjasScreenState();
}

class _RevisionTarjasScreenState extends State<RevisionTarjasScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroPersonal = 'todos'; // 'todos', 'propio', 'contratista'
  String _filtroEstado = 'todos'; // 'todos', 'creada', 'revisada'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final tarjaProvider = context.read<TarjaProvider>();
      
      if (authProvider.userData != null && authProvider.userData!['id_sucursal'] != null) {
        final idSucursal = authProvider.userData!['id_sucursal'].toString();
        tarjaProvider.setIdSucursal(idSucursal);
      }
      
      tarjaProvider.cargarTarjas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    switch (_tabController.index) {
      case 0: // Todas
        setState(() {
          _filtroPersonal = 'todos';
          _filtroEstado = 'todos';
        });
        break;
      case 1: // Personal Propio - Creadas
        setState(() {
          _filtroPersonal = 'propio';
          _filtroEstado = 'creada';
        });
        break;
      case 2: // Personal Propio - Revisadas
        setState(() {
          _filtroPersonal = 'propio';
          _filtroEstado = 'revisada';
        });
        break;
      case 3: // Contratistas - Creadas
        setState(() {
          _filtroPersonal = 'contratista';
          _filtroEstado = 'creada';
        });
        break;
    }
  }

  List<Tarja> _filtrarTarjas(List<Tarja> tarjas) {
    return tarjas.where((tarja) {
      // Filtrar por tipo de personal
      bool cumplePersonal = true;
      if (_filtroPersonal != 'todos') {
        // Determinar si es personal propio o contratista basado en el campo 'tipo'
        bool esPersonalPropio = tarja.tipo.toLowerCase().contains('propio') || 
                               tarja.tipo.toLowerCase().contains('interno');
        if (_filtroPersonal == 'propio') {
          cumplePersonal = esPersonalPropio;
        } else if (_filtroPersonal == 'contratista') {
          cumplePersonal = !esPersonalPropio;
        }
      }

      // Filtrar por estado
      bool cumpleEstado = true;
      if (_filtroEstado != 'todos') {
        cumpleEstado = tarja.estado.toLowerCase() == _filtroEstado.toLowerCase();
      }

      return cumplePersonal && cumpleEstado;
    }).toList();
  }

  Map<String, List<Tarja>> _agruparPorFecha(List<Tarja> tarjas) {
    final grupos = <String, List<Tarja>>{};
    for (var tarja in tarjas) {
      final fecha = tarja.fecha;
      if (!grupos.containsKey(fecha)) {
        grupos[fecha] = [];
      }
      grupos[fecha]!.add(tarja);
    }
    return grupos;
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return fecha;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'creada':
        return Colors.orange;
      case 'revisada':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getTipoPersonalColor(String tipo) {
    if (tipo.toLowerCase().contains('propio') || tipo.toLowerCase().contains('interno')) {
      return Colors.blue;
    } else {
      return Colors.purple;
    }
  }

  String _getTipoPersonalText(String tipo) {
    if (tipo.toLowerCase().contains('propio') || tipo.toLowerCase().contains('interno')) {
      return 'Personal Propio';
    } else {
      return 'Contratista';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisión de Tarjas'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Todas'),
            Tab(text: 'Propio - Creadas'),
            Tab(text: 'Propio - Revisadas'),
            Tab(text: 'Contratistas - Creadas'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TarjaProvider>().cargarTarjas(),
          ),
        ],
      ),
      body: Consumer<TarjaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.cargarTarjas(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          
          final tarjasFiltradas = _filtrarTarjas(provider.tarjas);
          
          if (tarjasFiltradas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay actividades que coincidan con los filtros',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta cambiar los filtros o refrescar los datos',
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

          final gruposPorFecha = _agruparPorFecha(tarjasFiltradas);
          final fechasOrdenadas = gruposPorFecha.keys.toList()..sort((a, b) => b.compareTo(a));
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: fechasOrdenadas.length,
            itemBuilder: (context, index) {
              final fecha = fechasOrdenadas[index];
              final tarjas = gruposPorFecha[fecha]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _formatearFecha(fecha),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...tarjas.map((tarja) => Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () {}, // Para efecto de ripple
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    tarja.actividad,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // Badge de tipo de personal
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTipoPersonalColor(tarja.tipo),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _getTipoPersonalText(tarja.tipo),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    // Badge de rendimiento
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tarja.tieneRendimiento ? Colors.blue : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            tarja.tieneRendimiento ? Icons.check_circle : Icons.pending_outlined,
                                            size: 16,
                                            color: tarja.tieneRendimiento ? Colors.white : Colors.grey[700],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            tarja.tieneRendimiento ? 'Con rendimiento' : 'Sin rendimiento',
                                            style: TextStyle(
                                              color: tarja.tieneRendimiento ? Colors.white : Colors.grey[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Badge de estado
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getEstadoColor(tarja.estado),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        tarja.estado,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.person,
                              label: 'Trabajador:',
                              value: tarja.trabajador,
                              iconColor: Colors.blue[700],
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.location_on,
                              label: 'CECO:',
                              value: tarja.lugar,
                              iconColor: Colors.green[700],
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.assessment,
                              label: 'Tipo:',
                              value: tarja.tipo,
                              iconColor: Colors.orange[700],
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.access_time,
                              label: 'Horario:',
                              value: '${tarja.horaInicio} - ${tarja.horaFin}',
                              iconColor: Colors.purple[700],
                            ),
                            const SizedBox(height: 16),
                            if (tarja.tieneRendimiento) Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final nuevoEstado = tarja.estado.toLowerCase() == 'creada' ? 'revisada' : 'creada';
                                    provider.actualizarTarja(tarja.id, {
                                      'estado': nuevoEstado,
                                    });
                                  },
                                  icon: Icon(
                                    tarja.estado.toLowerCase() == 'creada' 
                                      ? Icons.check_circle 
                                      : Icons.restore,
                                  ),
                                  label: Text(
                                    tarja.estado.toLowerCase() == 'creada'
                                      ? 'Marcar como revisada'
                                      : 'Volver a creada'
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: tarja.estado.toLowerCase() == 'creada'
                                      ? Colors.green
                                      : Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  )).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
} 