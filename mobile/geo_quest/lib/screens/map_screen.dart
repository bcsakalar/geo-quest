import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/quest_provider.dart';
import '../services/location_service.dart';
import '../models/quest.dart';
import 'quest_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng? _userLocation;
  bool _locationLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _locationLoading = false;
      });
    } catch (e) {
      setState(() => _locationLoading = false);
    }

    // Always load all quests (no location filter)
    if (mounted) {
      context.read<QuestProvider>().loadQuests();
    }
  }

  Future<void> _generateAIQuests() async {
    if (_userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum alınamadı'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = context.read<QuestProvider>();
    final result = await provider.generateQuests(
      _userLocation!.latitude,
      _userLocation!.longitude,
    );

    if (!mounted) return;

    final error = result['error'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? result['message'] ?? 'Görevler oluşturuldu!'),
      backgroundColor: error != null ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final questProvider = context.watch<QuestProvider>();
    final quests = questProvider.quests;

    if (_locationLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Konum alınıyor...'),
          ],
        ),
      );
    }

    // Default center: Istanbul or user location
    final center = _userLocation ?? const LatLng(41.0082, 28.9784);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.geo_quest',
            ),
            MarkerLayer(
              markers: [
                // User location marker
                if (_userLocation != null)
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                  ),
                // Quest markers
                ...quests.map((quest) => Marker(
                  point: LatLng(quest.latitude, quest.longitude),
                  width: 50,
                  height: 50,
                  child: GestureDetector(
                    onTap: () => _showQuestDetail(quest),
                    child: _questMarkerIcon(quest),
                  ),
                )),
              ],
            ),
          ],
        ),

        // AI Generate button
        Positioned(
          bottom: 16,
          left: 16,
          child: questProvider.isGenerating
              ? const FloatingActionButton.extended(
                  heroTag: 'generating',
                  onPressed: null,
                  icon: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                  label: Text('Üretiliyor...'),
                  backgroundColor: Colors.deepPurple,
                )
              : FloatingActionButton.extended(
                  heroTag: 'ai_generate',
                  onPressed: _generateAIQuests,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AI Görev Üret'),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
        ),

        // Action buttons
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'locate',
                onPressed: () {
                  if (_userLocation != null) {
                    _mapController.move(_userLocation!, 14);
                  }
                },
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'refresh',
                onPressed: _loadLocation,
                child: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),

        // Quest count badge
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              '${quests.length} görev',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _questMarkerIcon(Quest quest) {
    final completed = context.read<QuestProvider>().isQuestCompleted(quest.id);

    IconData icon;
    Color color;
    switch (quest.type) {
      case 'photo':
        icon = Icons.camera_alt;
        color = completed ? Colors.grey : Colors.orange;
        break;
      case 'question':
        icon = Icons.quiz;
        color = completed ? Colors.grey : Colors.blue;
        break;
      case 'qr_code':
        icon = Icons.qr_code;
        color = completed ? Colors.grey : Colors.purple;
        break;
      default:
        icon = Icons.flag;
        color = Colors.green;
    }

    // AI quests get a special border
    final borderColor = quest.isAI ? Colors.deepPurple : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: quest.isAI ? 3 : 2),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  void _showQuestDetail(Quest quest) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuestDetailScreen(quest: quest),
      ),
    );
  }
}
