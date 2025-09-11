import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/horas_trabajadas_provider.dart';
import '../providers/horas_extras_provider.dart';
import '../providers/colaborador_provider.dart';
import '../providers/tarja_provider.dart';
import '../theme/app_theme.dart';
// import '../widgets/main_scaffold.dart'; // No usar MainScaffold para evitar duplicación de AppBar

class IndicadoresScreen extends StatefulWidget {
  const IndicadoresScreen({super.key});

  @override
  State<IndicadoresScreen> createState() => _IndicadoresScreenState();
}

class _IndicadoresScreenState extends State<IndicadoresScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _indicadores = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No cargar datos automáticamente para evitar setState durante build
    // Los datos se cargarán cuando el usuario navegue a esta pantalla
  }

  Future<void> _cargarIndicadores() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final horasTrabajadasProvider = context.read<HorasTrabajadasProvider>();
      final horasExtrasProvider = context.read<HorasExtrasProvider>();
      final colaboradorProvider = context.read<ColaboradorProvider>();
      final tarjaProvider = context.read<TarjaProvider>();

      // Cargar datos de todos los providers
      await Future.wait([
        horasTrabajadasProvider.cargarHorasTrabajadas(),
        horasExtrasProvider.cargarRendimientos(),
        colaboradorProvider.cargarColaboradores(),
        tarjaProvider.cargarTarjas(),
      ]);

      // Calcular indicadores
      _calcularIndicadores(
        horasTrabajadasProvider,
        horasExtrasProvider,
        colaboradorProvider,
        tarjaProvider,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar indicadores: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calcularIndicadores(
    HorasTrabajadasProvider horasTrabajadasProvider,
    HorasExtrasProvider horasExtrasProvider,
    ColaboradorProvider colaboradorProvider,
    TarjaProvider tarjaProvider,
  ) {
    // 1. Horas trabajadas sobre lo esperado
    final horasTrabajadas = horasTrabajadasProvider.horasTrabajadas;
    final totalHorasTrabajadas = horasTrabajadas.fold<double>(
      0, (sum, ht) => sum + ht.totalHoras,
    );
    final totalHorasEsperadas = horasTrabajadas.length * 8.0; // 8 horas por día
    final porcentajeHorasTrabajadas = totalHorasEsperadas > 0 
        ? (totalHorasTrabajadas / totalHorasEsperadas) * 100 
        : 0.0;

    // 2. Horas extras sobre lo legal (más de 2 horas por día)
    final horasExtras = horasExtrasProvider.rendimientos;
    final actividadesConHorasExtrasExcesivas = horasExtras.where(
      (he) => he.totalHorasExtras > 2.0,
    ).length;
    final porcentajeHorasExtrasExcesivas = horasExtras.isNotEmpty
        ? (actividadesConHorasExtrasExcesivas / horasExtras.length) * 100
        : 0.0;

    // 3. Colaboradores activos vs inactivos
    final colaboradores = colaboradorProvider.colaboradores;
    final colaboradoresActivos = colaboradores.where(
      (c) => c.idEstado == '1',
    ).length;
    final colaboradoresInactivos = colaboradores.where(
      (c) => c.idEstado == '2',
    ).length;
    final porcentajeActivos = colaboradores.isNotEmpty
        ? (colaboradoresActivos / colaboradores.length) * 100
        : 0.0;

    // 4. Tarjas pendientes vs aprobadas
    final tarjas = tarjaProvider.tarjas;
    final tarjasPendientes = tarjas.where(
      (t) => t.idEstadoactividad == '1',
    ).length;
    final tarjasAprobadas = tarjas.where(
      (t) => t.idEstadoactividad == '2',
    ).length;
    final porcentajeAprobadas = tarjas.isNotEmpty
        ? (tarjasAprobadas / tarjas.length) * 100
        : 0.0;

    // 5. Promedio de rendimiento (basado en tarjas con rendimiento)
    final tarjasConRendimiento = tarjas.where((t) => t.tieneRendimiento).length;
    final promedioRendimiento = tarjas.isNotEmpty
        ? (tarjasConRendimiento / tarjas.length) * 100
        : 0.0;

    // 6. Colaboradores con sueldo base
    final colaboradoresConSueldoBase = colaboradores.where(
      (c) => c.sueldobase != null && c.sueldobase! > 0,
    ).length;
    final porcentajeConSueldoBase = colaboradores.isNotEmpty
        ? (colaboradoresConSueldoBase / colaboradores.length) * 100
        : 0.0;

    _indicadores = {
      'horasTrabajadas': {
        'total': totalHorasTrabajadas,
        'esperadas': totalHorasEsperadas,
        'porcentaje': porcentajeHorasTrabajadas,
        'sobreEsperado': porcentajeHorasTrabajadas > 100,
      },
      'horasExtras': {
        'total': horasExtras.length,
        'excesivas': actividadesConHorasExtrasExcesivas,
        'porcentaje': porcentajeHorasExtrasExcesivas,
        'critico': porcentajeHorasExtrasExcesivas > 20,
      },
      'colaboradores': {
        'total': colaboradores.length,
        'activos': colaboradoresActivos,
        'inactivos': colaboradoresInactivos,
        'porcentajeActivos': porcentajeActivos,
        'conSueldoBase': colaboradoresConSueldoBase,
        'porcentajeConSueldoBase': porcentajeConSueldoBase,
      },
      'tarjas': {
        'total': tarjas.length,
        'pendientes': tarjasPendientes,
        'aprobadas': tarjasAprobadas,
        'porcentajeAprobadas': porcentajeAprobadas,
      },
      'rendimiento': {
        'promedio': promedioRendimiento,
        'totalRendimientos': tarjasConRendimiento,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    // Cargar datos solo si no se han cargado aún
    if (_isLoading && _indicadores.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarIndicadores();
      });
    }

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _cargarIndicadores,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildIndicadoresGrid(),
                    const SizedBox(height: 24),
                    _buildDetallesIndicadores(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard de Indicadores',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.headlineSmall?.color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Métricas clave para la gestión de tarjas y colaboradores',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadoresGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildIndicadorCard(
          'Horas Trabajadas',
          '${_indicadores['horasTrabajadas']['porcentaje'].toStringAsFixed(1)}%',
          '${_indicadores['horasTrabajadas']['total'].toStringAsFixed(1)}h / ${_indicadores['horasTrabajadas']['esperadas'].toStringAsFixed(1)}h',
          Icons.access_time,
          _indicadores['horasTrabajadas']['sobreEsperado'] ? Colors.orange : Colors.green,
          _indicadores['horasTrabajadas']['sobreEsperado'] ? 'Sobre lo esperado' : 'Dentro del rango',
        ),
        _buildIndicadorCard(
          'Horas Extras Excesivas',
          '${_indicadores['horasExtras']['porcentaje'].toStringAsFixed(1)}%',
          '${_indicadores['horasExtras']['excesivas']} de ${_indicadores['horasExtras']['total']} actividades',
          Icons.warning,
          _indicadores['horasExtras']['critico'] ? Colors.red : Colors.orange,
          _indicadores['horasExtras']['critico'] ? 'Crítico (>20%)' : 'Atención requerida',
        ),
        _buildIndicadorCard(
          'Colaboradores Activos',
          '${_indicadores['colaboradores']['porcentajeActivos'].toStringAsFixed(1)}%',
          '${_indicadores['colaboradores']['activos']} de ${_indicadores['colaboradores']['total']} colaboradores',
          Icons.people,
          Colors.blue,
          'Estado de colaboradores',
        ),
        _buildIndicadorCard(
          'Tarjas Aprobadas',
          '${_indicadores['tarjas']['porcentajeAprobadas'].toStringAsFixed(1)}%',
          '${_indicadores['tarjas']['aprobadas']} de ${_indicadores['tarjas']['total']} tarjas',
          Icons.check_circle,
          Colors.green,
          'Estado de aprobación',
        ),
        _buildIndicadorCard(
          'Tarjas con Rendimiento',
          '${_indicadores['rendimiento']['promedio'].toStringAsFixed(1)}%',
          '${_indicadores['rendimiento']['totalRendimientos']} de ${_indicadores['tarjas']['total']} tarjas',
          Icons.trending_up,
          Colors.purple,
          'Productividad general',
        ),
        _buildIndicadorCard(
          'Sueldos Base Asignados',
          '${_indicadores['colaboradores']['porcentajeConSueldoBase'].toStringAsFixed(1)}%',
          '${_indicadores['colaboradores']['conSueldoBase']} de ${_indicadores['colaboradores']['total']} colaboradores',
          Icons.attach_money,
          Colors.teal,
          'Configuración salarial',
        ),
      ],
    );
  }

  Widget _buildIndicadorCard(
    String titulo,
    String valor,
    String subtitulo,
    IconData icono,
    Color color,
    String descripcion,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
          const Spacer(),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesIndicadores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles por Categoría',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.headlineSmall?.color,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetalleCategoria(
          'Horas Trabajadas',
          Icons.access_time,
          Colors.blue,
          [
            'Total de horas trabajadas: ${_indicadores['horasTrabajadas']['total'].toStringAsFixed(1)} horas',
            'Horas esperadas: ${_indicadores['horasTrabajadas']['esperadas'].toStringAsFixed(1)} horas',
            'Diferencia: ${(_indicadores['horasTrabajadas']['total'] - _indicadores['horasTrabajadas']['esperadas']).toStringAsFixed(1)} horas',
            'Estado: ${_indicadores['horasTrabajadas']['sobreEsperado'] ? 'Sobre lo esperado' : 'Dentro del rango normal'}',
          ],
        ),
        const SizedBox(height: 16),
        _buildDetalleCategoria(
          'Horas Extras',
          Icons.warning,
          Colors.orange,
          [
            'Total de actividades: ${_indicadores['horasExtras']['total']}',
            'Actividades con horas extras excesivas: ${_indicadores['horasExtras']['excesivas']}',
            'Porcentaje de actividades problemáticas: ${_indicadores['horasExtras']['porcentaje'].toStringAsFixed(1)}%',
            'Recomendación: ${_indicadores['horasExtras']['critico'] ? 'Revisar políticas de horas extras' : 'Monitorear actividades problemáticas'}',
          ],
        ),
        const SizedBox(height: 16),
        _buildDetalleCategoria(
          'Gestión de Colaboradores',
          Icons.people,
          Colors.green,
          [
            'Total de colaboradores: ${_indicadores['colaboradores']['total']}',
            'Colaboradores activos: ${_indicadores['colaboradores']['activos']} (${_indicadores['colaboradores']['porcentajeActivos'].toStringAsFixed(1)}%)',
            'Colaboradores inactivos: ${_indicadores['colaboradores']['inactivos']}',
            'Con sueldo base asignado: ${_indicadores['colaboradores']['conSueldoBase']} (${_indicadores['colaboradores']['porcentajeConSueldoBase'].toStringAsFixed(1)}%)',
          ],
        ),
        const SizedBox(height: 16),
        _buildDetalleCategoria(
          'Estado de Tarjas',
          Icons.description,
          Colors.purple,
          [
            'Total de tarjas: ${_indicadores['tarjas']['total']}',
            'Tarjas aprobadas: ${_indicadores['tarjas']['aprobadas']} (${_indicadores['tarjas']['porcentajeAprobadas'].toStringAsFixed(1)}%)',
            'Tarjas pendientes: ${_indicadores['tarjas']['pendientes']}',
            'Tarjas con rendimiento: ${_indicadores['rendimiento']['promedio'].toStringAsFixed(1)}%',
          ],
        ),
      ],
    );
  }

  Widget _buildDetalleCategoria(
    String titulo,
    IconData icono,
    Color color,
    List<String> detalles,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...detalles.map((detalle) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    detalle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
