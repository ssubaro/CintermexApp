import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class MapaCintermexScreen extends StatefulWidget {
  const MapaCintermexScreen({super.key});

  @override
  State<MapaCintermexScreen> createState() => _MapaCintermexScreenState();
}

class _MapaCintermexScreenState extends State<MapaCintermexScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _hasZoomed = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _hasZoomed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text(
          'Mapa de Cintermex',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        actions: [
          if (_hasZoomed)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              tooltip: 'Restablecer zoom',
              onPressed: _resetZoom,
            ),
        ],
      ),
      body: Column(
        children: [
          // Hint banner
          Container(
            width: double.infinity,
            color: Colors.white.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pinch, size: 16, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 8),
                Text(
                  'Usa dos dedos para hacer zoom · Arrastra para moverte',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Map
          Expanded(
            child: InteractiveViewer(
              transformationController: _transformationController,
              boundaryMargin: const EdgeInsets.all(40),
              minScale: 0.5,
              maxScale: 5.0,
              onInteractionUpdate: (_) {
                if (!_hasZoomed &&
                    _transformationController.value != Matrix4.identity()) {
                  setState(() => _hasZoomed = true);
                }
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'images/mapa_cintermex.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom legend
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white.withOpacity(0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Icons.accessible, 'Accesible'),
                _buildLegendItem(Icons.wc, 'Sanitarios'),
                _buildLegendItem(Icons.local_parking, 'Estacionamiento'),
                _buildLegendItem(Icons.elevator, 'Elevador'),
              ],
            ),
          ),
        ],
      ),
      // FAB to reset zoom
      floatingActionButton: _hasZoomed
          ? FloatingActionButton.small(
              onPressed: _resetZoom,
              backgroundColor: AppColors.primaryRed,
              child: const Icon(Icons.zoom_out_map, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildLegendItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}
