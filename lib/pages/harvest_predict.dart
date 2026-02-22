import 'package:flutter/material.dart';
import '../services/api_service.dart';
class HarvestPredictionPage extends StatefulWidget {
  const HarvestPredictionPage({Key? key}) : super(key: key);

  @override
  State<HarvestPredictionPage> createState() => _HarvestPredictionPageState();
}

class _HarvestPredictionPageState extends State<HarvestPredictionPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _feedingController = TextEditingController();
  
  // Dropdown values
  String? _selectedSpecies;
  final List<String> _fishSpecies = [
  'Tilapia',
  'Rohu',
  'Catla',
  'Common Carp',
  'Pangasius',
  'Grass Carp',
  'Silver Carp',
  'Murrel',
];
  
  // Prediction result
  int? _predictedDays;
  bool _isLoading = false;

  // TODO: Replace these colors with your theme colors
  final Color primaryColor = const Color(0xFF667eea);
  final Color secondaryColor = const Color(0xFF764ba2);
  final Color backgroundColor = const Color(0xFFF5F7FA);
  final Color cardColor = Colors.white;
  final Color textColor = const Color(0xFF333333);
  final Color subtextColor = const Color(0xFF666666);

  @override
  void dispose() {
    _ageController.dispose();
    _feedingController.dispose();
    super.dispose();
  }

  Future<void> _predictHarvest() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    try {
      final prediction = await ApiService.predictFish(
        _selectedSpecies!,
        int.parse(_ageController.text),
        int.parse(_feedingController.text),
      );

      setState(() {
        _predictedDays = prediction;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Server error. Check Flask API")),
      );
    }

    setState(() => _isLoading = false);
  }
}

  void _resetForm() {
    setState(() {
      _selectedSpecies = null;
      _ageController.clear();
      _feedingController.clear();
      _predictedDays = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Harvest Prediction'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                _buildHeaderCard(),
                const SizedBox(height: 24),
                
                // Input Form Card
                _buildInputCard(),
                const SizedBox(height: 24),
                
                // Predict Button
                _buildPredictButton(),
                const SizedBox(height: 24),
                
                // Result Card
                if (_predictedDays != null) _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 50,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'AI-Powered Harvest Prediction',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter fish details to predict harvest time',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fish Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Species Dropdown
          _buildLabel('Fish Species'),
          DropdownButtonFormField<String>(
            value: _selectedSpecies,
            decoration: _inputDecoration('Select fish species'),
            items: _fishSpecies.map((species) {
              return DropdownMenuItem(
                value: species,
                child: Text(species),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedSpecies = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a fish species';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Age Input
          _buildLabel('Current Age (in days)'),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Enter age in days'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter fish age';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (int.parse(value) < 0) {
                return 'Age cannot be negative';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Feeding Frequency Input
          _buildLabel('Feeding Frequency (times per day)'),
          TextFormField(
            controller: _feedingController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Enter feeding times per day'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter feeding frequency';
              }
              if (int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              if (int.parse(value) < 1 || int.parse(value) > 10) {
                return 'Feeding frequency should be between 1-10';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: subtextColor.withOpacity(0.5)),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildPredictButton() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _predictHarvest,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 5,
              shadowColor: primaryColor.withOpacity(0.5),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.disabled)) {
                  return subtextColor;
                }
                return primaryColor;
              }),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.psychology, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Predict Harvest',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_predictedDays != null) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: _resetForm,
            icon: const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: backgroundColor,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 60,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'Prediction Result',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Estimated Harvest Time',
      style: TextStyle(
        fontSize: 12,
        color: subtextColor,
      ),
    ),
    SizedBox(height: 4),
    Text(
      '$_predictedDays days',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade700,
      ),
    ),
  ],
)
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildInfoRow('Species', _selectedSpecies ?? ''),
                const Divider(height: 16),
                _buildInfoRow('Current Age', '${_ageController.text} days'),
                const Divider(height: 16),
                _buildInfoRow('Feeding Frequency', '${_feedingController.text}x per day'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '* This is an AI prediction. Actual harvest time may vary based on environmental conditions.',
            style: TextStyle(
              fontSize: 12,
              color: subtextColor,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: subtextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}