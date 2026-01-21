import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/home_view_model.dart';
import '../service/ai_service.dart';
import '../model/attraction.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AIService _aiService = AIService();

  void _downloadModel() {
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    viewModel.setModelStatus(ModelStatus.downloading);
    _aiService.downloadModel().then((success) {
      viewModel.setModelStatus(success ? ModelStatus.local : ModelStatus.notDownloaded);
    });
  }

  void _filterAttractions(String category) {
    final viewModel = Provider.of<HomeViewModel>(context, listen: false);
    viewModel.setLoading(true);

    _aiService.filterAttractions(viewModel.allAttractions, category).then((jsonString) {
      final cleanJson = _cleanJson(jsonString);
      final List<dynamic> jsonList = json.decode(cleanJson);
      final attractions = jsonList.map((json) => Attraction.fromJson(json)).toList();
      viewModel.setFilteredAttractions(attractions);
    }).catchError((error) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error filtering attractions: $error')),
      );
    }).whenComplete(() {
      viewModel.setLoading(false);
    });
  }

  String _cleanJson(String rawJson) {
    // Basic regex to remove conversational text and markdown backticks
    return rawJson.replaceAll(RegExp(r'```json\n|\n```'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paris Attractions'),
      ),
      body: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              _buildStatusChip(viewModel.modelStatus),
              _buildControlPanel(viewModel.modelStatus),
              if (viewModel.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.filteredAttractions.length,
                  itemBuilder: (context, index) {
                    final attraction = viewModel.filteredAttractions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(attraction.name),
                        subtitle: Text(attraction.description),
                        leading: CircleAvatar(
                          child: Text(attraction.category[0].toUpperCase()),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(ModelStatus status) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Chip(
        label: Text(
          status == ModelStatus.local
              ? 'AI Model: Local'
              : 'AI Model: Not Downloaded',
        ),
        backgroundColor: status == ModelStatus.local ? Colors.green : Colors.red,
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildControlPanel(ModelStatus status) {
    if (status != ModelStatus.local) {
      return ElevatedButton(
        onPressed: _downloadModel,
        child: const Text('Download AI Model'),
      );
    } else {
      return Wrap(
        spacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          ElevatedButton(onPressed: () => _filterAttractions('Museum'), child: const Text('Museums')),
          ElevatedButton(onPressed: () => _filterAttractions('Cafe'), child: const Text('Cafes')),
          ElevatedButton(onPressed: () => _filterAttractions('Park'), child: const Text('Parks')),
          ElevatedButton(onPressed: () => _filterAttractions('Church'), child: const Text('Churches')),
        ],
      );
    }
  }
}
