import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// Provider for room list
final roomListProvider = FutureProvider<List<Room>>((ref) async {
  return await client.admin.getAllRooms();
});

class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  ConsumerState<RoomManagementScreen> createState() =>
      _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  String _searchQuery = '';
  Program? _selectedProgram;
  bool? _selectedActiveStatus;
  final TextEditingController _searchController = TextEditingController();

  final Color maroonColor = const Color(0xFF720045);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddRoomModal() {
    showDialog(
      context: context,
      builder: (context) => _AddRoomModal(
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(roomListProvider);
        },
      ),
    );
  }

  void _showEditRoomModal(Room room) {
    showDialog(
      context: context,
      builder: (context) => _EditRoomModal(
        room: room,
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(roomListProvider);
        },
      ),
    );
  }

  void _deleteRoom(Room room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Room',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${room.name}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await client.admin.deleteRoom(room.id!);
        ref.invalidate(roomListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting room: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(roomListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Room Management',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage classroom facilities, capacities, and program assignments',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _showAddRoomModal,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Add Room',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: maroonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search and Filter Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.transparent : Colors.grey[300]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(30, 41, 59, 1)
                              .withOpacity(
                                0.03,
                              ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: maroonColor,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase();
                              });
                            },
                            cursorColor: isDark ? Colors.white : Colors.black87,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Search by room name...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildProgramFilter(isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildStatusFilter(isDark),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Table
            Expanded(
              child: roomsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (rooms) {
                  final filtered = rooms.where((r) {
                    final matchesSearch = r.name.toLowerCase().contains(
                      _searchQuery,
                    );
                    final matchesProgram =
                        _selectedProgram == null ||
                        r.program == _selectedProgram;
                    final matchesStatus =
                        _selectedActiveStatus == null ||
                        r.isActive == _selectedActiveStatus;
                    return matchesSearch && matchesProgram && matchesStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No rooms found'));
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border(
                        left: BorderSide(color: maroonColor, width: 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: maroonColor.withOpacity(0.05),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.meeting_room_rounded,
                                color: maroonColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rooms',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: maroonColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: maroonColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${filtered.length} Total',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                maroonColor,
                              ),
                              headingTextStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                              dataRowMinHeight: 65,
                              dataRowMaxHeight: 85,
                              columnSpacing: 32,
                              horizontalMargin: 24,
                              decoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              columns: const [
                                DataColumn(label: Text('ROOM')),
                                DataColumn(label: Text('CAPACITY')),
                                DataColumn(label: Text('TYPE')),
                                DataColumn(label: Text('PROGRAM')),
                                DataColumn(label: Text('BUILDING')),
                                DataColumn(label: Text('STATUS')),
                                DataColumn(label: Text('ACTIONS')),
                              ],
                              rows: filtered.asMap().entries.map((entry) {
                                final room = entry.value;
                                final index = entry.key;

                                return DataRow(
                                  color:
                                      WidgetStateProperty.resolveWith<Color?>(
                                        (states) {
                                          if (states.contains(
                                            WidgetState.hovered,
                                          )) {
                                            return maroonColor.withOpacity(
                                              0.05,
                                            );
                                          }
                                          return index.isEven
                                              ? (isDark
                                                    ? Colors.white.withOpacity(
                                                        0.02,
                                                      )
                                                    : Colors.grey.withOpacity(
                                                        0.02,
                                                      ))
                                              : null;
                                        },
                                      ),
                                  cells: [
                                    DataCell(
                                      Text(
                                        room.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(room.capacity.toString())),
                                    DataCell(
                                      Text(room.type.name.toUpperCase()),
                                    ),
                                    DataCell(
                                      Text(room.program.name.toUpperCase()),
                                    ),
                                    DataCell(Text(room.building)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: room.isActive
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          room.isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: TextStyle(
                                            color: room.isActive
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _showEditRoomModal(room),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteRoom(room),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
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
        ),
      ),
    );
  }

  Widget _buildProgramFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Program>(
          value: _selectedProgram,
          hint: Row(
            children: [
              Icon(Icons.school_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Program',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All Programs',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            ...Program.values.map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(
                  p.name.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedProgram = v),
        ),
      ),
    );
  }

  Widget _buildStatusFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: _selectedActiveStatus,
          hint: Row(
            children: [
              Icon(Icons.toggle_on_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Status',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All Status',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            DropdownMenuItem(
              value: true,
              child: Text('Active', style: GoogleFonts.poppins(fontSize: 14)),
            ),
            DropdownMenuItem(
              value: false,
              child: Text('Inactive', style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
          onChanged: (v) => setState(() => _selectedActiveStatus = v),
        ),
      ),
    );
  }
}

class _AddRoomModal extends StatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _AddRoomModal({required this.maroonColor, required this.onSuccess});

  @override
  State<_AddRoomModal> createState() => _AddRoomModalState();
}

class _AddRoomModalState extends State<_AddRoomModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController(text: '40');
  final _buildingController = TextEditingController(text: 'CITE');

  RoomType _type = RoomType.lecture;
  Program _program = Program.it;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Room'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Room Name'),
              ),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _buildingController,
                decoration: const InputDecoration(labelText: 'Building'),
              ),
              DropdownButtonFormField<Program>(
                value: _program,
                decoration: const InputDecoration(labelText: 'Program'),
                items: Program.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _program = v!),
              ),
              DropdownButtonFormField<RoomType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Room Type'),
                items: RoomType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: widget.maroonColor),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final room = Room(
        name: _nameController.text,
        capacity: int.parse(_capacityController.text),
        building: _buildingController.text,
        type: _type,
        program: _program,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await client.admin.createRoom(room);
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _EditRoomModal extends StatefulWidget {
  final Room room;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditRoomModal({
    required this.room,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  State<_EditRoomModal> createState() => _EditRoomModalState();
}

class _EditRoomModalState extends State<_EditRoomModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _buildingController;

  late RoomType _type;
  late Program _program;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room.name);
    _capacityController = TextEditingController(
      text: widget.room.capacity.toString(),
    );
    _buildingController = TextEditingController(text: widget.room.building);
    _type = widget.room.type;
    _program = widget.room.program;
    _isActive = widget.room.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Room'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Room Name'),
              ),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Capacity'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _buildingController,
                decoration: const InputDecoration(labelText: 'Building'),
              ),
              DropdownButtonFormField<Program>(
                value: _program,
                decoration: const InputDecoration(labelText: 'Program'),
                items: Program.values
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _program = v!),
              ),
              DropdownButtonFormField<RoomType>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Room Type'),
                items: RoomType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: widget.maroonColor),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = widget.room.copyWith(
        name: _nameController.text,
        capacity: int.parse(_capacityController.text),
        building: _buildingController.text,
        type: _type,
        program: _program,
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );
      await client.admin.updateRoom(updated);
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
