// inventario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Para poder regresar al Login al cerrar sesión

// ==================== PALETA DE COLORES ====================
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

  // Gradientes decorativos para los placeholders de imagen, rotan por índice
  static const List<List<Color>> imageGradients = [
    [Color(0xFFF3E7DA), Color(0xFFE9D3B8)],
    [Color(0xFFE7ECD9), Color(0xFFD3E0BE)],
    [Color(0xFFF0E1E1), Color(0xFFE6C6C6)],
    [Color(0xFFE6E9F0), Color(0xFFCFD8E6)],
  ];
}

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  String _categoriaSeleccionada = 'Velas de Molde';
  bool _isSaving = false;

  final List<String> _categorias = [
    'Velas de Molde',
    'Velas en Vaso',
    'Wax Melts',
    'Accesorios',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // Función para guardar el producto en Firebase
  Future<void> _agregarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Apunta a la colección 'productos' que tienes en tu Firestore
      await FirebaseFirestore.instance.collection('productos').add({
        'nombre': _nombreController.text.trim(),
        'precio': double.parse(_precioController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'categoria': _categoriaSeleccionada,
        'creadoEn': Timestamp.now(),
      });

      if (!mounted) return;

      // Limpiar formulario y avisar que se guardó
      _nombreController.clear();
      _precioController.clear();
      _stockController.clear();
      setState(() {
        _categoriaSeleccionada = 'Velas de Molde';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Producto guardado con éxito'),
          backgroundColor: _Colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al guardar el producto'),
          backgroundColor: _Colors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Función para eliminar un producto
  Future<void> _eliminarProducto(String id) async {
    try {
      await FirebaseFirestore.instance.collection('productos').doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Producto eliminado'),
          backgroundColor: _Colors.brand,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo eliminar el producto'),
          backgroundColor: _Colors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Función para cerrar sesión
  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      appBar: AppBar(
        title: const Text(
          'LUMIÈRE & CO. — Panel de Control',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _Colors.brand,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ================= COLUMNA IZQUIERDA: FORMULARIO =================
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      const Text(
                        'Nueva Creación',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _Colors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Registra un nuevo producto en el catálogo de la tienda.',
                        style: TextStyle(fontSize: 12, color: _Colors.textGray),
                      ),
                      const SizedBox(height: 32),

                      // Campo Nombre
                      _buildInputLabel('Nombre del Producto'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nombreController,
                        style: const TextStyle(fontSize: 13),
                        decoration: _buildInputDecoration(
                          'Ej. Vela Cherry Blossom',
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Ingresa un nombre' : null,
                      ),
                      const SizedBox(height: 20),

                      // Fila de Precio y Stock
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Precio (\$)'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _precioController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration('0.00'),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Requerido' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('Stock Inicial'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: _buildInputDecoration('0'),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Requerido' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Selector de Categoría
                      _buildInputLabel('Categoría'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _categoriaSeleccionada,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _Colors.textDark,
                        ),
                        decoration: _buildInputDecoration(''),
                        items: _categorias.map((String cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (String? nuevoValor) {
                          if (nuevoValor != null) {
                            setState(() {
                              _categoriaSeleccionada = nuevoValor;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 36),

                      // Botón Guardar
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _agregarProducto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Colors.brand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Guardar en Catálogo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ================= COLUMNA DERECHA: VISTA EN TIEMPO REAL =================
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Inventario en la Nube',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _Colors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sincronizado directamente con la base de datos de Firebase.',
                              style: TextStyle(
                                fontSize: 12,
                                color: _Colors.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Grilla dinámica conectada a Cloud Firestore
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('productos')
                          .orderBy('creadoEn', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error al cargar datos.'),
                          );
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: _Colors.brand,
                            ),
                          );
                        }
                        if (snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final docs = snapshot.data!.docs;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            // Columnas responsivas según el ancho disponible
                            int crossAxisCount = 2;
                            if (constraints.maxWidth > 1300) {
                              crossAxisCount = 4;
                            } else if (constraints.maxWidth > 950) {
                              crossAxisCount = 3;
                            }

                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: docs.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                    childAspectRatio: 0.72,
                                  ),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data = doc.data() as Map<String, dynamic>;

                                final String nombre =
                                    data['nombre'] ?? 'Sin nombre';
                                final String categoria =
                                    data['categoria'] ?? 'Sin categoría';
                                final double precio = (data['precio'] ?? 0.0)
                                    .toDouble();
                                final int stock = data['stock'] ?? 0;

                                return _ProductCard(
                                  nombre: nombre,
                                  categoria: categoria,
                                  precio: precio,
                                  stock: stock,
                                  colorIndex: index,
                                  onDelete: () => _eliminarProducto(doc.id),
                                );
                              },
                            );
                          },
                        );
                      },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _Colors.brandLight.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: _Colors.brand,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay productos registrados aún',
            style: TextStyle(
              color: _Colors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Agrega tu primera creación desde el formulario',
            style: TextStyle(color: _Colors.textGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Auxiliares de diseño visual
  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _Colors.brand,
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _Colors.textGray.withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: _Colors.bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Colors.bg),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _Colors.brandLight, width: 1.5),
      ),
    );
  }
}

// ==================== TARJETA DE PRODUCTO ====================
// Tarjeta estilo catálogo (inspirada en el diseño de referencia).
// El bloque superior es un placeholder: aquí se colocará la imagen real
// del producto más adelante (basta con reemplazar el Container por
// Image.network(url) / Image.asset(...) dentro de _ImagePlaceholder).
class _ProductCard extends StatelessWidget {
  final String nombre;
  final String categoria;
  final double precio;
  final int stock;
  final int colorIndex;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stock,
    required this.colorIndex,
    required this.onDelete,
  });

  bool get _stockBajo => stock < 5;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Placeholder de imagen ----
          Expanded(
            flex: 5,
            child: _ImagePlaceholder(
              colorIndex: colorIndex,
              stock: stock,
              stockBajo: _stockBajo,
              onDelete: onDelete,
            ),
          ),

          // ---- Contenido de texto ----
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _Colors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        categoria.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w600,
                          color: _Colors.textGray,
                        ),
                      ),
                    ],
                  ),

                  // Precio / Stock en formato de mini columnas (como la referencia)
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          label: 'Precio',
                          value: '\$${precio.toStringAsFixed(2)}',
                          valueColor: _Colors.textDark,
                        ),
                      ),
                      Expanded(
                        child: _StatBlock(
                          label: 'Stock',
                          value: '$stock u.',
                          valueColor: _stockBajo
                              ? _Colors.danger
                              : _Colors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Pill inferior estilo "Navigate to location" de la referencia
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _stockBajo
                          ? _Colors.danger.withOpacity(0.12)
                          : _Colors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _stockBajo ? 'Stock bajo' : 'Disponible',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _stockBajo ? _Colors.danger : _Colors.success,
                        ),
                      ),
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
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: _Colors.textGray),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// Placeholder visual del área de imagen. Reemplaza el `Icon` por
// `Image.network(url, fit: BoxFit.cover)` cuando tengas las fotos reales.
class _ImagePlaceholder extends StatelessWidget {
  final int colorIndex;
  final int stock;
  final bool stockBajo;
  final VoidCallback onDelete;

  const _ImagePlaceholder({
    required this.colorIndex,
    required this.stock,
    required this.stockBajo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final gradient =
        _Colors.imageGradients[colorIndex % _Colors.imageGradients.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo degradado (sustituir por la imagen real del producto)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 34, color: Colors.white70),
          ),
        ),

        // Badge de stock (esquina superior izquierda)
        Positioned(
          top: 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$stock u.',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: stockBajo ? _Colors.danger : _Colors.success,
              ),
            ),
          ),
        ),

        // Botón de eliminar (esquina superior derecha)
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white.withOpacity(0.9),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.all(6.0),
                child: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: _Colors.danger,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
