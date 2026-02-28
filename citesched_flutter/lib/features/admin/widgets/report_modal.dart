import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportModal extends StatefulWidget {
  const ReportModal({super.key});

  @override
  State<ReportModal> createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = isDark
        ? const Color(0xFFa21caf)
        : const Color(0xFF720045);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 12 : 40,
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 1000,
        height: isMobile ? screenHeight * 0.9 : 800,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.black.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF720045),
                    const Color(0xFF8e005b),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrative Reports',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 20 : 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMobile
                            ? 'System analysis'
                            : 'System-wide analysis and statistics',
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 11 : 14,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: bgBody,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryPurple, const Color(0xFF8e005b)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: textMuted,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: isMobile ? 'Faculty' : 'Faculty Load'),
                    Tab(text: isMobile ? 'Rooms' : 'Room Utilization'),
                    Tab(text: isMobile ? 'Conflicts' : 'Conflict Summary'),
                    Tab(text: isMobile ? 'Overview' : 'Schedule Overview'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: Container(
                color: bgBody,
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    _FacultyLoadTab(),
                    _RoomUtilizationTab(),
                    _ConflictSummaryTab(),
                    _ScheduleOverviewTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacultyLoadTab extends StatelessWidget {
  const _FacultyLoadTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FacultyLoadReport>>(
      future: client.admin.getFacultyLoadReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final data = snapshot.data ?? [];
        if (data.isEmpty) return const Center(child: Text('No data available'));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                Theme.of(context).primaryColor.withOpacity(0.05),
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    'Faculty Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Program',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Subjects',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Total Units',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: data.map((item) {
                Color statusColor;
                if (item.loadStatus == 'Overloaded')
                  statusColor = Colors.red;
                else if (item.loadStatus == 'Underloaded')
                  statusColor = Colors.orange;
                else
                  statusColor = Colors.green;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(item.facultyName, style: GoogleFonts.poppins()),
                    ),
                    DataCell(
                      Text(item.program ?? '-', style: GoogleFonts.poppins()),
                    ),
                    DataCell(
                      Text(
                        item.totalSubjects.toString(),
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    DataCell(
                      Text(
                        item.totalUnits.toStringAsFixed(1),
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.loadStatus,
                          style: GoogleFonts.poppins(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class _RoomUtilizationTab extends StatelessWidget {
  const _RoomUtilizationTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoomUtilizationReport>>(
      future: client.admin.getRoomUtilizationReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final data = snapshot.data ?? [];
        return ListView.separated(
          padding: const EdgeInsets.all(24),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final item = data[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.meeting_room_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.roomName,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${item.totalBookings} bookings',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.utilizationPercentage.toStringAsFixed(1)}% Usage',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.isActive ? 'Active' : 'Inactive',
                          style: GoogleFonts.poppins(
                            color: item.isActive ? Colors.green : Colors.red,
                            fontSize: 12,
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
}

class _ConflictSummaryTab extends StatelessWidget {
  const _ConflictSummaryTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConflictSummaryReport>(
      future: client.admin.getConflictSummaryReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final data = snapshot.data;
        if (data == null) return const Center(child: Text('No data'));

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Total Conflicts: ${data.totalConflicts}',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'System integrity is ${data.totalConflicts == 0 ? "optimal" : "needs attention"}',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleOverviewTab extends StatelessWidget {
  const _ScheduleOverviewTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ScheduleOverviewReport>(
      future: client.admin.getScheduleOverviewReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text('Error: ${snapshot.error}'));

        final data = snapshot.data;
        if (data == null) return const Center(child: Text('No data'));

        final isMobile = MediaQuery.of(context).size.width < 600;

        return GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: isMobile ? 1 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isMobile ? 2.5 : 1.5,
          children: [
            _buildStatCard(
              context,
              'Total Classes',
              data.totalSchedules.toString(),
              Icons.class_outlined,
              Colors.blue,
            ),
            ...data.schedulesByProgram.entries.map(
              (e) => _buildStatCard(
                context,
                '${e.key} Classes',
                e.value.toString(),
                Icons.bookmark_outline,
                Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }
}
