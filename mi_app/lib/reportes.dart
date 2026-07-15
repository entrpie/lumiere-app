import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ==================== PALETA DE COLORES (COHERENTE CON INVENTARIO) ====================
class _Colors {
  static const bg = Color(0xFFFAF8F5);
  static const card = Colors.white;
  static const border = Color(0xFFECE6DF);
  static const brand = Color(0xFF8C6239);
  static const brandLight = Color(0xFFE2B28B);
  static const textDark = Color(0xFF2D2D2D);
  static const textGray = Color(0xFF8E8E8E);
  static const success = Color(0xFF556B2F);
  static const danger = Color(0xFFC97A7A);
}

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  String _filtroTemporal = 'Este Mes';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera interna de Reportes
            _buildHeader(),
            const SizedBox(height: 24),

            // Fila de KPIs Principales
            _buildKpiCardsRow(),
            const SizedBox(height: 24),

            // Contenedor principal: Gráfica de Ventas + Historial de Movimientos
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 950) {
                  // Vista de Escritorio / Pantalla Ancha (Lado a Lado)
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildGraficaVentasCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: _buildMovimientosCard()),
                    ],
                  );
                } else {
                  // Vista Móvil (Uno debajo del otro)
                  return Column(
                    children: [
                      _buildGraficaVentasCard(),
                      const SizedBox(height: 24),
                      _buildMovimientosCard(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Header con filtro temporal estético
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rendimiento del Negocio',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _Colors.textDark,
              ),
            ),
            Text(
              'Visualiza ingresos, tendencias y rotación de producto.',
              style: TextStyle(fontSize: 12, color: _Colors.textGray),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _Colors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filtroTemporal,
              items: <String>['Esta Semana', 'Este Mes', 'Este Año'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      color: _Colors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (v) {
                setState(() => _filtroTemporal = v!);
              },
            ),
          ),
        ),
      ],
    );
  }

  // Tarjetas KPI (Ingresos, Ventas, Stock Crítico)
  Widget _buildKpiCardsRow() {
    return Row(
      children: [
        const Expanded(
          child: _KpiReportCard(
            title: 'Ingresos Totales',
            value: '\$4,820.50',
            trend: '+12.4%',
            trendIsPositive: true,
            icon: Icons.payments_outlined,
            accentColor: _Colors.success,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: _KpiReportCard(
            title: 'Pedidos Completados',
            value: '142',
            trend: '+8.1%',
            trendIsPositive: true,
            icon: Icons.shopping_bag_outlined,
            accentColor: _Colors.brand,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('productos')
                .snapshots(),
            builder: (context, snapshot) {
              int stockBajoCount = 0;
              if (snapshot.hasData) {
                stockBajoCount = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['stock'] ?? 0) < 5;
                }).length;
              }
              return _KpiReportCard(
                title: 'Alertas de Stock',
                value: '$stockBajoCount',
                trend: stockBajoCount > 0 ? 'Requiere atención' : 'Todo al día',
                trendIsPositive: stockBajoCount == 0,
                icon: Icons.warning_amber_rounded,
                accentColor: stockBajoCount > 0
                    ? _Colors.danger
                    : _Colors.success,
              );
            },
          ),
        ),
      ],
    );
  }

  // Gráfico de Ventas estilizado con FL Chart
  Widget _buildGraficaVentasCard() {
    return Container(
      height: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Ventas (\$)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ingresos diarios calculados este mes',
                    style: TextStyle(fontSize: 11, color: _Colors.textGray),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,

                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: _Colors.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: _Colors.textGray,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        );
                        switch (value.toInt()) {
                          case 1:
                            return const Text('Sem 1', style: style);
                          case 3:
                            return const Text('Sem 2', style: style);
                          case 5:
                            return const Text('Sem 3', style: style);
                          case 7:
                            return const Text('Sem 4', style: style);
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${value.toInt()}',
                          style: const TextStyle(
                            color: _Colors.textGray,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: 7,
                minY: 0,
                maxY: 800,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(1, 150),
                      FlSpot(2, 280),
                      FlSpot(3, 210),
                      FlSpot(4, 450),
                      FlSpot(5, 390),
                      FlSpot(6, 620),
                      FlSpot(7, 580),
                    ],
                    isCurved: true,
                    color: _Colors.brand,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _Colors.brandLight.withOpacity(0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lista de movimientos recientes (Logs de Stock y Ventas)
  Widget _buildMovimientosCard() {
    // Datos simulados locales para logs estéticos de inventario
    final List<Map<String, dynamic>> movimientos = [
      {
        'tipo': 'Salida',
        'item': 'Vela Molde Rosas',
        'cant': 5,
        'fecha': 'Hace 10 min',
        'venta': true,
      },
      {
        'tipo': 'Abasto',
        'item': 'Vaso Cera Vainilla',
        'cant': 20,
        'fecha': 'Hace 2 horas',
        'venta': false,
      },
      {
        'tipo': 'Salida',
        'item': 'Wax Melts Canela',
        'cant': 2,
        'fecha': 'Hace 3 horas',
        'venta': true,
      },
      {
        'tipo': 'Ajuste',
        'item': 'Portavela Madera',
        'cant': -1,
        'fecha': 'Ayer',
        'venta': false,
      },
    ];

    return Container(
      height: 420,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Movimientos Recientes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Flujo de entrada y salida físico de inventario',
            style: TextStyle(fontSize: 11, color: _Colors.textGray),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: movimientos.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: _Colors.border, height: 16),
              itemBuilder: (context, index) {
                final mov = movimientos[index];
                final esVenta = mov['venta'] as bool;
                final esAbasto = mov['tipo'] == 'Abasto';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: esVenta
                          ? _Colors.success.withOpacity(0.1)
                          : esAbasto
                          ? _Colors.brandLight.withOpacity(0.15)
                          : _Colors.danger.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      esVenta
                          ? Icons.trending_up_rounded
                          : esAbasto
                          ? Icons.unarchive_rounded
                          : Icons.swap_horiz_rounded,
                      color: esVenta
                          ? _Colors.success
                          : esAbasto
                          ? _Colors.brand
                          : _Colors.danger,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    mov['item'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _Colors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    mov['fecha'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: _Colors.textGray,
                    ),
                  ),
                  trailing: Text(
                    '${esVenta || (mov['cant'] as int) < 0 ? "-" : "+"}${(mov['cant'] as int).abs()}',
                    style: TextStyle(

                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: esVenta || mov['cant'] < 0
                          ? _Colors.danger
                          : _Colors.success,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Componente para las tarjetas superiores KPI de Reportes
class _KpiReportCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendIsPositive;
  final IconData icon;
  final Color accentColor;

  const _KpiReportCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.trendIsPositive,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: _Colors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: _Colors.brand, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                trendIsPositive ? Icons.north_rounded : Icons.south_rounded,
                size: 12,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}