// inventario.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Para poder regresar al Login al cerrar sesión

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
        const SnackBar(
          content: Text('Producto guardado con éxito'),
          backgroundColor: Color(0xFF556B2F),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el producto'),
          backgroundColor: Color(0xFFC97A7A),
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
      backgroundColor: const Color(0xFFFAF8F5),
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
        foregroundColor: const Color(0xFF8C6239),
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
                      // Título en NEGRIATAS
                      const Text(
                        'Nueva Creación',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold, // <-- Negritas aplicadas
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Registra un nuevo producto en el catálogo de la tienda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8E8E8E),
                        ),
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
                          color: Color(0xFF2D2D2D),
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
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _agregarProducto,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8C6239),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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
                                    fontWeight: FontWeight.w500,
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
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título en NEGRIATAS
                  const Text(
                    'Inventario en la Nube',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold, // <-- Negritas aplicadas
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sincronizado directamente con la base de datos de Firebase.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8E8E8E)),
                  ),
                  const SizedBox(height: 24),

                  // Tabla dinámica conectada a Cloud Firestore
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFECE6DF)),
                      ),
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('productos') // Conecta a tu colección
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
                                color: Color(0xFF8C6239),
                              ),
                            );
                          }
                          if (snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No hay productos registrados aún.',
                                style: TextStyle(
                                  color: Color(0xFF8E8E8E),
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs;

                          return ListView.separated(
                            itemCount: docs.length,
                            separatorBuilder: (context, index) => const Divider(
                              color: Color(0xFFFAF8F5),
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final data =
                                  docs[index].data() as Map<String, dynamic>;

                              String nombre = data['nombre'] ?? 'Sin nombre';
                              String categoria =
                                  data['categoria'] ?? 'Sin categoría';
                              double precio = (data['precio'] ?? 0.0)
                                  .toDouble();
                              int stock = data['stock'] ?? 0;

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                title: Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D2D2D),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 4.0,
                                  ), // <-- Corregido aquí
                                  child: Text(
                                    categoria.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                      color: Color(0xFF8C6239),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF8F5),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '\$${precio.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF8C6239),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    SizedBox(
                                      width: 70,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$stock u.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: stock < 5
                                                  ? const Color(0xFFC97A7A)
                                                  : const Color(0xFF556B2F),
                                            ),
                                          ),
                                          const Text(
                                            'Stock',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF8E8E8E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
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

  // Auxiliares de diseño visual
  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8C6239),
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF8E8E8E).withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFFAF8F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFAF8F5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2B28B), width: 1.5),
      ),
    );
  }
}
