import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // Para poder regresar al Login al cerrar sesión
import 'reportes.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();

  String _searchQuery = '';
  bool _showAddPanel = false;
  bool _isSaving = false;
  bool _activo = true;
  String _rolSeleccionado = 'Administrador';

  final List<String> _roles = [
    'Administrador',
    'Supervisor',
    'Vendedor',
    'Operador',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot> _filtrarUsuarios(
    List<QueryDocumentSnapshot> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
      final email = (data['email'] ?? '').toString().toLowerCase();
      final rol = (data['rol'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return query.isEmpty ||
          nombre.contains(query) ||
          email.contains(query) ||
          rol.contains(query);
    }).toList();
  }

  Future<void> _agregarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('usuarios').add({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': _rolSeleccionado,
        'activo': _activo,
        'creadoEn': Timestamp.now(),
      });

      if (!mounted) return;

      _nombreController.clear();
      _emailController.clear();
      setState(() {
        _rolSeleccionado = 'Administrador';
        _activo = true;
        _showAddPanel = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Usuario agregado correctamente'),
          backgroundColor: _Colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No se pudo guardar el usuario'),
          backgroundColor: _Colors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildListaUsuarios(
    List<QueryDocumentSnapshot> docs,
    List<QueryDocumentSnapshot> filtrados,
  ) {
    final totalActivos = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['activo'] ?? false) == true;
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.people_alt_rounded,
                label: 'Usuarios',
                value: '${docs.length}',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _KpiCard(
                icon: Icons.check_circle_rounded,
                label: 'Activos',
                value: '$totalActivos',
                accent: _Colors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Colors.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuarios por nombre, email o rol',
                    hintStyle: TextStyle(
                      color: _Colors.textGray.withValues(alpha: 0.8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _Colors.textGray,
                    ),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showAddPanel = !_showAddPanel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _showAddPanel
                    ? _Colors.textDark
                    : _Colors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                _showAddPanel
                    ? Icons.close_rounded
                    : Icons.person_add_alt_rounded,
                size: 18,
              ),
              label: Text(
                _showAddPanel ? 'Cerrar formulario' : 'Agregar Usuario',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: docs.isEmpty
              ? const Center(child: Text('Aún no hay usuarios registrados.'))
              : filtrados.isEmpty
              ? const Center(
                  child: Text('No hay usuarios que coincidan con la búsqueda.'),
                )
              : ListView.separated(
                  itemCount: filtrados.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = filtrados[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final nombre = (data['nombre'] ?? 'Sin nombre').toString();
                    final email = (data['email'] ?? 'Sin email').toString();
                    final rol = (data['rol'] ?? 'Sin rol').toString();
                    final activo = (data['activo'] ?? false) == true;

                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _Colors.border),
                        boxShadow: [
                          BoxShadow(
                            color: _Colors.brand.withValues(alpha: 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: _Colors.brandLight,
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: _Colors.textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: _Colors.textGray,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rol: $rol',
                                  style: const TextStyle(
                                    color: _Colors.brand,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: activo
                                  ? _Colors.success.withValues(alpha: 0.12)
                                  : _Colors.danger.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              activo ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                color: activo
                                    ? _Colors.success
                                    : _Colors.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAddUserForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Usuario',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _Colors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completa los datos para registrar un nuevo acceso.',
                style: TextStyle(fontSize: 12, color: _Colors.textGray),
              ),
              const SizedBox(height: 22),
              const Text(
                'Nombre completo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej. Sofia López',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _Colors.bg,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa un nombre válido'
                    : null,
              ),
              const SizedBox(height: 18),
              const Text(
                'Correo electrónico',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'usuario@lumiere.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _Colors.bg,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un correo';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  return emailRegex.hasMatch(value.trim())
                      ? null
                      : 'Correo inválido';
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'Rol',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _rolSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: _Colors.bg,
                ),
                items: _roles.map((rol) {
                  return DropdownMenuItem<String>(value: rol, child: Text(rol));
                }).toList(),
                onChanged: (value) {
                  setState(() => _rolSeleccionado = value ?? 'Administrador');
                },
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _Colors.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Colors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estado del usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _activo ? 'Activo y con acceso' : 'Inactivo',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _Colors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _activo,
                      onChanged: (value) => setState(() => _activo = value),
                      activeColor: _Colors.brand,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _agregarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Colors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar usuario',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar usuarios.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _Colors.brand),
              );
            }

            final docs = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];
            final filtrados = _filtrarUsuarios(docs);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildListaUsuarios(docs, filtrados)),
                if (_showAddPanel)
                  const VerticalDivider(width: 1, color: _Colors.border),
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    child: _showAddPanel
                        ? SizedBox(width: 380, child: _buildAddUserForm())
                        : const SizedBox(width: 0),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

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

  // Paleta oscura y cálida para el sidebar (estética de tienda de velas)
  static const sidebarBg = Color(0xFF332619);
  static const sidebarSelected = Color(0xFF4A3826);
  static const sidebarText = Color(0xFFF3E9DC);
  static const sidebarTextMuted = Color(0xFFB7A48D);

  // Gradientes decorativos para los placeholders de imagen, rotan por índice
  static const List<List<Color>> imageGradients = [
    [Color(0xFFF3E7DA), Color(0xFFE9D3B8)],
    [Color(0xFFE7ECD9), Color(0xFFD3E0BE)],
    [Color(0xFFF0E1E1), Color(0xFFE6C6C6)],
    [Color(0xFFE6E9F0), Color(0xFFCFD8E6)],
  ];
}

// Secciones disponibles en el sidebar
enum _NavSection { catalogo, usuarios, reportes }

// Filtro de disponibilidad usado en el panel de filtros
enum _StockFilter { todos, disponible, bajo }

// Ícono representativo para cada categoría de la tienda
IconData _iconoCategoria(String categoria) {
  switch (categoria) {
    case 'Velas de Molde':
      return Icons.local_fire_department_rounded;
    case 'Velas en Vaso':
      return Icons.emoji_food_beverage_rounded;
    case 'Wax Melts':
      return Icons.grain_rounded;
    case 'Accesorios':
      return Icons.auto_awesome_rounded;
    default:
      return Icons.category_rounded;
  }
}

class InventarioPage extends StatefulWidget {
  const InventarioPage({super.key});

  @override
  State<InventarioPage> createState() => _InventarioPageState();
}

class _InventarioPageState extends State<InventarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Controladores para los campos del formulario
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();
  final _searchController = TextEditingController();

  String _categoriaSeleccionada = 'Velas de Molde';
  bool _isSaving = false;

  // ---- Navegación y estado de la UI ----
  _NavSection _section = _NavSection.catalogo;
  bool _showAddPanel = false;
  String _searchQuery = '';
  String _filtroCategoria = 'Todas';
  _StockFilter _filtroStock = _StockFilter.todos;

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
    _searchController.dispose();
    super.dispose();
  }

  // Función para guardar el producto en Firebase
  Future<void> _agregarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance.collection('productos').add({
        'nombre': _nombreController.text.trim(),
        'precio': double.parse(_precioController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'categoria': _categoriaSeleccionada,
        'creadoEn': Timestamp.now(),
      });

      if (!mounted) return;

      _nombreController.clear();
      _precioController.clear();
      _stockController.clear();
      setState(() {
        _categoriaSeleccionada = 'Velas de Molde';
        _showAddPanel = false; // Opcional: cierra el panel tras guardar
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

  bool get _hayFiltrosActivos =>
      _filtroCategoria != 'Todas' || _filtroStock != _StockFilter.todos;

  List<QueryDocumentSnapshot> _aplicarFiltros(
    List<QueryDocumentSnapshot> docs,
  ) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final nombre = (data['nombre'] ?? '').toString().toLowerCase();
      final categoria = (data['categoria'] ?? '').toString();
      final stock = (data['stock'] ?? 0) as int;

      final coincideBusqueda =
          _searchQuery.isEmpty || nombre.contains(_searchQuery.toLowerCase());
      final coincideCategoria =
          _filtroCategoria == 'Todas' || categoria == _filtroCategoria;
      final coincideStock =
          _filtroStock == _StockFilter.todos ||
          (_filtroStock == _StockFilter.bajo && stock < 5) ||
          (_filtroStock == _StockFilter.disponible && stock >= 5);

      return coincideBusqueda && coincideCategoria && coincideStock;
    }).toList();
  }

  String get _tituloSeccion {
    switch (_section) {
      case _NavSection.catalogo:
        return 'Catálogo';
      case _NavSection.usuarios:
        return 'Usuarios';
      case _NavSection.reportes:
        return 'Reportes';
    }
  }

  String get _subtituloSeccion {
    switch (_section) {
      case _NavSection.catalogo:
        return 'Todos los productos de la tienda';
      case _NavSection.usuarios:
        return 'Gestiona tus usuarios y permisos';
      case _NavSection.reportes:
        return 'Estadísticas generales del inventario';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _Colors.bg,
      drawer: _buildSidebar(),
      appBar: _buildTopBar(),
      body: SafeArea(
        child: switch (_section) {
          _NavSection.catalogo => _buildCatalogoSection(),
          _NavSection.usuarios =>
            const UsuariosPage(), // <--- Apunta a tu clase externa de usuarios.dart
          _NavSection.reportes =>
            const ReportesPage(), // <--- Apunta a tu clase externa de reportes.dart
        },
      ),
    );
  }

  // ==================== SIDEBAR (MENÚ HAMBURGUESA) ====================
  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: _Colors.sidebarBg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _Colors.brandLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: _Colors.brandLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LUMIÈRE & CO.',
                          style: TextStyle(
                            color: _Colors.sidebarText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Panel de Control',
                          style: TextStyle(
                            color: _Colors.sidebarTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'MENÚ PRINCIPAL',
                style: TextStyle(
                  color: _Colors.sidebarTextMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _NavTile(
              icon: Icons.grid_view_rounded,
              label: 'Catálogo',
              subtitle: 'Todos los productos',
              selected: _section == _NavSection.catalogo,
              onTap: () {
                setState(() => _section = _NavSection.catalogo);
                Navigator.pop(context);
              },
            ),
            _NavTile(
              icon: Icons.person_rounded,
              label: 'Usuarios',
              subtitle: 'Gestiona tus usuarios',
              selected: _section == _NavSection.usuarios,
              onTap: () {
                setState(() => _section = _NavSection.usuarios);
                Navigator.pop(context);
              },
            ),
            _NavTile(
              icon: Icons.bar_chart_rounded,
              label: 'Reportes',
              subtitle: 'Estadísticas e insights',
              selected: _section == _NavSection.reportes,
              onTap: () {
                setState(() => _section = _NavSection.reportes);
                Navigator.pop(context); // Cierra el sidebar
              },
            ),
            const Spacer(),
            Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
            _NavTile(
              icon: Icons.logout_rounded,
              label: 'Cerrar sesión',
              subtitle: null,
              selected: false,
              danger: true,
              onTap: _cerrarSesion,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ==================== TOPBAR ====================
  PreferredSizeWidget _buildTopBar() {
    final esCatalogo = _section == _NavSection.catalogo;
    return AppBar(
      toolbarHeight: 78,
      backgroundColor: Colors.white,
      foregroundColor: _Colors.brand,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.white,
      titleSpacing: 4,
      title: Row(
        children: [
          SizedBox(
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tituloSeccion,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _Colors.textDark,
                  ),
                ),
                Text(
                  _subtituloSeccion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: _Colors.textGray),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (esCatalogo)
            Expanded(child: _buildSearchField())
          else
            const Spacer(),
          if (esCatalogo) const SizedBox(width: 10),
          if (esCatalogo) _buildFilterButton(),
          if (esCatalogo) const SizedBox(width: 10),
          if (esCatalogo) _buildAddProductButton(),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined, size: 20),
          onPressed: _cerrarSesion,
          tooltip: 'Cerrar Sesión',
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 42,
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: _Colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Colors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          hintStyle: TextStyle(color: _Colors.textGray.withValues(alpha: 0.7)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: _Colors.textGray,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: _Colors.textGray,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: _abrirPanelFiltros,
          style: OutlinedButton.styleFrom(
            foregroundColor: _Colors.textDark,
            side: const BorderSide(color: _Colors.border),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text(
            'Filtrar',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        if (_hayFiltrosActivos)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _Colors.brand,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddProductButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _showAddPanel = !_showAddPanel),
      style: ElevatedButton.styleFrom(
        backgroundColor: _showAddPanel ? _Colors.textDark : _Colors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(
        _showAddPanel ? Icons.close_rounded : Icons.add_rounded,
        size: 18,
      ),
      label: Text(
        _showAddPanel ? 'Cerrar formulario' : 'Agregar Producto',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _abrirPanelFiltros() {
    String categoriaTemp = _filtroCategoria;
    _StockFilter stockTemp = _filtroStock;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _Colors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Filtrar productos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Categoría',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Todas', ..._categorias].map((cat) {
                      final selected = categoriaTemp == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        onSelected: (_) =>
                            setModalState(() => categoriaTemp = cat),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _Colors.textDark,
                        ),
                        selectedColor: _Colors.brand,
                        backgroundColor: _Colors.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected ? _Colors.brand : _Colors.border,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Disponibilidad',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          _StockFilter.todos,
                          _StockFilter.disponible,
                          _StockFilter.bajo,
                        ].map((f) {
                          final label = switch (f) {
                            _StockFilter.todos => 'Todos',
                            _StockFilter.disponible => 'Disponible',
                            _StockFilter.bajo => 'Stock bajo',
                          };
                          final selected = stockTemp == f;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) =>
                                setModalState(() => stockTemp = f),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : _Colors.textDark,
                            ),
                            selectedColor: _Colors.brand,
                            backgroundColor: _Colors.bg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: selected
                                    ? _Colors.brand
                                    : _Colors.border,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              categoriaTemp = 'Todas';
                              stockTemp = _StockFilter.todos;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: _Colors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Limpiar',
                            style: TextStyle(
                              color: _Colors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filtroCategoria = categoriaTemp;
                              _filtroStock = stockTemp;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _Colors.brand,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Aplicar filtros',
                            style: TextStyle(fontWeight: FontWeight.w600),
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
      },
    );
  }

  // ==================== SECCIÓN: CATÁLOGO ====================
  Widget _buildCatalogoSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('productos')
          .orderBy('creadoEn', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar datos.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _Colors.brand),
          );
        }

        final todos = snapshot.data!.docs;
        final filtrados = _aplicarFiltros(todos);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. El catálogo va al principio (Lado izquierdo)
            Expanded(child: _buildCatalogoGrid(todos, filtrados)),

            // 2. Divisor decorativo intermedio
            if (_showAddPanel)
              const VerticalDivider(width: 1, color: _Colors.border),

            // 3. El formulario animado va al final (Lado derecho)
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: _showAddPanel
                    ? SizedBox(width: 380, child: _buildAddForm())
                    : const SizedBox(width: 0),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCatalogoGrid(
    List<QueryDocumentSnapshot> todos,
    List<QueryDocumentSnapshot> filtrados,
  ) {
    final totalUnidades = todos.fold<int>(
      0,
      (sum, d) =>
          sum + ((d.data() as Map<String, dynamic>)['stock'] ?? 0) as int,
    );
    final stockBajo = todos.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return (data['stock'] ?? 0) < 5;
    }).length;

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Productos',
                  value: '${todos.length}',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _KpiCard(
                  icon: Icons.widgets_outlined,
                  label: 'Unidades en stock',
                  value: '$totalUnidades',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _KpiCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Stock bajo',
                  value: '$stockBajo',
                  accent: stockBajo > 0 ? _Colors.danger : _Colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_hayFiltrosActivos || _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Mostrando ${filtrados.length} de ${todos.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Colors.textGray,
                    ),
                  ),
                  if (_filtroCategoria != 'Todas')
                    _FilterChipTag(
                      label: _filtroCategoria,
                      onRemove: () =>
                          setState(() => _filtroCategoria = 'Todas'),
                    ),
                  if (_filtroStock != _StockFilter.todos)
                    _FilterChipTag(
                      label: _filtroStock == _StockFilter.bajo
                          ? 'Stock bajo'
                          : 'Disponible',
                      onRemove: () =>
                          setState(() => _filtroStock = _StockFilter.todos),
                    ),
                  if (_searchQuery.isNotEmpty)
                    _FilterChipTag(
                      label: '"$_searchQuery"',
                      onRemove: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          Expanded(
            child: todos.isEmpty
                ? _buildEmptyState()
                : filtrados.isEmpty
                ? _buildEmptyFilterState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 2;
                      if (constraints.maxWidth > 1300) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth > 950) {
                        crossAxisCount = 3;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: filtrados.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (context, index) {
                          final doc = filtrados[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final String nombre = data['nombre'] ?? 'Sin nombre';
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
                  ),
          ),
        ],
      ),
    );
  }

  // Formulario de creación completo y corregido
  Widget _buildAddForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Producto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _Colors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ingresa los datos para registrarlo',
                style: TextStyle(fontSize: 12, color: _Colors.textGray),
              ),
              const SizedBox(height: 24),

              // Nombre
              const Text(
                'Nombre del Producto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  hintText: 'Ej. Velas Cilíndricas',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Ingresa un nombre válido' : null,
              ),
              const SizedBox(height: 16),

              // Precio y Stock
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precio (\$)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _precioController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) => double.tryParse(v ?? '') == null
                              ? 'Inválido'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) =>
                              int.tryParse(v ?? '') == null ? 'Inválido' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categoría
              const Text(
                'Categoría',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _categoriaSeleccionada,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: _categorias.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (v) {
                  setState(() {
                    _categoriaSeleccionada = v!;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Botón Guardar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _agregarProducto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _Colors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                          'Guardar Producto',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Estado vacío del catálogo (Sin items en la DB)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: _Colors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no hay productos registrados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Comienza agregando uno en el botón superior.',
            style: TextStyle(fontSize: 13, color: _Colors.textGray),
          ),
        ],
      ),
    );
  }

  // Estado vacío por filtros aplicados
  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: _Colors.textGray.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin coincidencias',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _Colors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Intenta modificando o limpiando tus filtros.',
            style: TextStyle(fontSize: 13, color: _Colors.textGray),
          ),
        ],
      ),
    );
  }

  // Vista vacía temporal de fallback para usuarios si no hay widget externo mapeado
  Widget _buildUsuariosSection() {
    return const Center(child: Text('Usuarios Page Fallback'));
  }
}

// ==================== WIDGETS DE SOPORTE COMPARTIDOS ====================

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (accent ?? _Colors.brand).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent ?? _Colors.brand, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _Colors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accent ?? _Colors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final gradient =
        _Colors.imageGradients[colorIndex % _Colors.imageGradients.length];
    final esBajoStock = stock < 5;

    return Container(
      decoration: BoxDecoration(
        color: _Colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagen decorativa / Categoría
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _iconoCategoria(categoria),
                      size: 40,
                      color: _Colors.brand.withValues(alpha: 0.6),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        onPressed: onDelete,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _Colors.brandLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _Colors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _Colors.brand,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: esBajoStock
                            ? _Colors.danger.withValues(alpha: 0.1)
                            : _Colors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Stock: $stock',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: esBajoStock ? _Colors.danger : _Colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipTag extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChipTag({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _Colors.brandLight.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Colors.brandLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _Colors.brand,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: _Colors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final bool danger;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? _Colors.danger
        : selected
        ? _Colors.sidebarText
        : _Colors.sidebarTextMuted;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _Colors.sidebarSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? _Colors.sidebarText.withValues(alpha: 0.7)
                            : _Colors.sidebarTextMuted,
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
}
