import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class GeminiTestScreen extends StatefulWidget {
  @override
  _GeminiTestScreenState createState() => _GeminiTestScreenState();
}

class _GeminiTestScreenState extends State<GeminiTestScreen> {
  bool _isTestingModels = false;
  Map<String, dynamic>? _testResults;
  String? _selectedModel;
  String _testWord = 'مرحبا';
  String? _quickTestResult;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gemini Model Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini 2.5 Model Testleri',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Farklı Gemini 2.5 model varyasyonlarını test edin',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isTestingModels ? null : _testAllModels,
                      child: _isTestingModels
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Test ediliyor...'),
                              ],
                            )
                          : Text('Tüm Modelleri Test Et'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_testResults != null) ...[
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Sonuçları',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      ..._testResults!.entries.map((entry) {
                        final success = entry.value['success'] ?? false;
                        return ListTile(
                          leading: Icon(
                            success ? Icons.check_circle : Icons.error,
                            color: success ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            entry.key,
                            style: TextStyle(
                              fontWeight: success ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(entry.value['message'] ?? ''),
                          onTap: success ? () {
                            setState(() {
                              _selectedModel = entry.key;
                            });
                            _applyModel(entry.key);
                          } : null,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
            
            if (_selectedModel != null) ...[
              SizedBox(height: 16),
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Seçilen Model',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedModel!,
                        style: TextStyle(fontSize: 14, color: Colors.green[800]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 16),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı Test',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Test Kelimesi',
                        hintText: 'Arapça veya Türkçe bir kelime girin',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _testWord),
                      onChanged: (value) => _testWord = value,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _runQuickTest,
                      child: Text('Test Et'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                    ),
                    if (_quickTestResult != null) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _quickTestResult!.contains('BAŞARILI') 
                              ? Colors.green[50] 
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _quickTestResult!.contains('BAŞARILI')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _quickTestResult!,
                          style: TextStyle(
                            color: _quickTestResult!.contains('BAŞARILI')
                                ? Colors.green[900]
                                : Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 16),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Bilgi',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Test edilen model adları:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• gemini-2.5-flash-preview'),
                    Text('• gemini-2.5-flash-lite-preview'),
                    Text('• gemini-2.5-flash-lite-preview-06-17'),
                    Text('• gemini-2.5-flash-preview-06-17'),
                    SizedBox(height: 8),
                    Text(
                      'Not: Test sonuçlarına göre çalışan bir model bulunursa otomatik olarak seçilecektir.',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _testAllModels() async {
    setState(() {
      _isTestingModels = true;
      _testResults = null;
    });
    
    try {
      final results = await GeminiService.testGemini25Models();
      setState(() {
        _testResults = results;
        _isTestingModels = false;
      });
      
      // Başarılı bir model varsa kullanıcıyı bilgilendir
      final successfulModel = results.entries.firstWhere(
        (entry) => entry.value['success'] == true,
        orElse: () => MapEntry('', {}),
      );
      
      if (successfulModel.key.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${successfulModel.key} modeli başarıyla çalışıyor!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hiçbir model çalışmadı. Lütfen API anahtarınızı kontrol edin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isTestingModels = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _applyModel(String modelName) async {
    final service = GeminiService();
    await service.setConfigValues(model: modelName);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $modelName modeli uygulandı'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Future<void> _runQuickTest() async {
    setState(() {
      _quickTestResult = null;
    });
    
    try {
      final service = GeminiService();
      final result = await service.searchWord(_testWord);
      
      setState(() {
        if (result.bulunduMu) {
          _quickTestResult = 'TEST BAŞARILI ✅\n\nKelime: ${result.kelime}\nAnlam: ${result.anlam}\nHarekeli: ${result.harekeliKelime}';
        } else {
          _quickTestResult = 'TEST BAŞARISIZ ❌\n\nHata: ${result.anlam}';
        }
      });
    } catch (e) {
      setState(() {
        _quickTestResult = 'TEST HATASI ❌\n\nHata: $e';
      });
    }
  }
}
