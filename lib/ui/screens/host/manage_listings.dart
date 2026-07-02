import 'package:flutter/material.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'add_property.dart';
import 'calendar_pricing_editor.dart';

class ManageListings extends StatefulWidget {
  const ManageListings({Key? key}) : super(key: key);

  @override
  State<ManageListings> createState() => _ManageListingsState();
}

class _ManageListingsState extends State<ManageListings> {
  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _showEditPriceBottomSheet(Destination dest) {
    final priceController = TextEditingController(text: dest.price.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Price for ${dest.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price per Night (TSh)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty || int.tryParse(val.trim()) == null) {
                      return 'Enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          // Find destination in mutable list and update
                          final index = destinations.indexOf(dest);
                          if (index != -1) {
                            destinations[index] = Destination(
                              imageUrl: dest.imageUrl,
                              name: dest.name,
                              city: dest.city,
                              area: dest.area,
                              roomType: dest.roomType,
                              distance: dest.distance,
                              rating: dest.rating,
                              price: int.parse(priceController.text.trim()),
                              duration: dest.duration,
                              guests: dest.guests,
                              bedrooms: dest.bedrooms,
                              beds: dest.beds,
                              baths: dest.baths,
                              condition: dest.condition,
                              amenities: dest.amenities,
                            );
                          }
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Price updated successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
                    child: const Text('Update Price', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteListing(Destination dest) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Listing?'),
          content: Text('Are you sure you want to permanently remove "${dest.name}" from your active properties?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  destinations.remove(dest);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listing removed successfully.'), backgroundColor: Colors.red),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
              child: const Text('Remove', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('My Properties', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: destinations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.home_work_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No properties listed yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tap the + button to add a new lodge listing.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final prop = destinations[index];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.asset(
                          prop.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteListing(prop),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(prop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('${prop.area}, ${prop.city}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('${_formatPrice(prop.price)} / night', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 16)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showEditPriceBottomSheet(prop),
                                  icon: const Icon(Icons.edit, size: 14, color: Colors.black87),
                                  label: const Text('Price', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CalendarPricingEditorScreen(destination: prop),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.calendar_month, size: 14, color: Colors.black87),
                                  label: const Text('Calendar', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(prop.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade900,
        onPressed: () async {
          final success = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddProperty()),
          );
          if (success == true) {
            setState(() {});
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
