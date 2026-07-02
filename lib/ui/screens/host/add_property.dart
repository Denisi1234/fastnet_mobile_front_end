import 'package:flutter/material.dart';
import 'package:airbnb_ui_clone/models/destination.dart';

class AddProperty extends StatefulWidget {
  const AddProperty({Key? key}) : super(key: key);

  @override
  State<AddProperty> createState() => _AddPropertyState();
}

class _AddPropertyState extends State<AddProperty> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _guestsController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedImage;

  // Available mock images for selection
  final List<String> _mockImages = [
    'assets/images/home.webp',
    'assets/images/home2.webp',
    'assets/images/house.jpeg',
    'assets/images/house2.webp',
    'assets/images/house3.webp',
    'assets/images/house4.webp',
    'assets/images/room.webp',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _guestsController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showImageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Property Cover Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mockImages.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final img = _mockImages[index];
                    final isSelected = _selectedImage == img;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = img;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.red.shade900 : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          image: DecorationImage(
                            image: AssetImage(img),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _saveProperty() {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a cover photo for your property.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Parse Address e.g. "Sakina, Arusha"
      final addressParts = _addressController.text.trim().split(',');
      String area = addressParts.first.trim();
      String city = addressParts.length > 1 ? addressParts[1].trim() : 'Dodoma';

      final newLodge = Destination(
        imageUrl: _selectedImage!,
        name: _nameController.text.trim(),
        city: city,
        area: area,
        roomType: 'Deluxe private room',
        distance: 3,
        rating: 4.8,
        price: int.tryParse(_priceController.text.trim()) ?? 85000,
        duration: 'Available today',
        guests: int.tryParse(_guestsController.text.trim()) ?? 2,
        bedrooms: 1,
        beds: 1,
        baths: 1,
        condition: _descController.text.trim(),
        amenities: ['Wi-Fi', 'Air conditioning', 'Breakfast', 'Parking'],
      );

      // Mutate global list
      destinations.insert(0, newLodge);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newLodge.name} has been published successfully!'),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Add New Property', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Property Details'),
              _buildTextField('Property Name', 'e.g., Luxury Ocean View Room', _nameController),
              const SizedBox(height: 16),
              _buildTextField('Location / Address', 'e.g., Masaki, Dar es Salaam', _addressController),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildTextField('Price per Night (TSh)', 'e.g., 150000', _priceController, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Max Guests', 'e.g., 2', _guestsController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Description'),
              _buildTextField('About the property', 'Describe what makes your place unique...', _descController, maxLines: 4),
              const SizedBox(height: 24),
              
              _buildSectionTitle('Photos'),
              GestureDetector(
                onTap: _showImageSelector,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null
                        ? DecorationImage(image: AssetImage(_selectedImage!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Tap to select cover photo', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProperty,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save & Publish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade900),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter this field';
        }
        return null;
      },
    );
  }
}
