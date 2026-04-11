import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color borderColor;
  final Color iconColor;
  final Color valueColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.borderColor,
    required this.iconColor,
    required this.valueColor,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHovered ? -5 : 0, 0),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          constraints: BoxConstraints(minHeight: isMobile ? 120 : 160),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: _isHovered ? Colors.black : Colors.black.withValues(alpha: 0.15),
              width: _isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _isHovered ? 0.1 : 0.04),
                blurRadius: _isHovered ? 25 : 12,
                offset: Offset(0, _isHovered ? 12 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF555555),
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      size: isMobile ? 16 : 20,
                      color: widget.iconColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.value,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.0,
                ),
              ),
              if (widget.onTap != null) ...[
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isVeryNarrow = constraints.maxWidth < 120;
                    return Row(
                      children: [
                        Flexible(
                          child: Text(
                            isVeryNarrow ? 'Details' : 'View Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 10 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: isMobile ? 12 : 14,
                          color: Colors.black87,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
