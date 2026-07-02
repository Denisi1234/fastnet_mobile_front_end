// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:airbnb_ui_clone/models/destination.dart';
import 'package:airbnb_ui_clone/ui/screens/book_room/widgets/book_room.dart';
import 'package:airbnb_ui_clone/ui/screens/auth/user_session.dart';
import 'package:flutter/material.dart';

class DestinationWidget extends StatefulWidget {
  final Destination destination;
  final int index;
  final String? selectedDatesText;
  final int numNights;

  const DestinationWidget({
    Key? key,
    required this.destination,
    required this.index,
    this.selectedDatesText,
    required this.numNights,
  }) : super(key: key);

  @override
  State<DestinationWidget> createState() => _DestinationWidgetState();
}

class _DestinationWidgetState extends State<DestinationWidget> {
  String _formatPrice(int price) {
    return 'TSh ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookRoom(
                destination: destination,
                selectedDatesText: widget.selectedDatesText ?? 'Jun 20 – 23',
                numNights: widget.numNights,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    destination.imageUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Top Rated / Best Value tag overlay
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: destination.rating >= 4.7 
                          ? Colors.green.shade700 
                          : Colors.red.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      destination.rating >= 4.7 ? 'TOP RATED' : 'FEATURED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                // Favorite overlay button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        WishlistData.toggle(destination);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            WishlistData.contains(destination)
                                ? '${destination.name} added to Wishlist'
                                : '${destination.name} removed from Wishlist',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: WishlistData.contains(destination) ? Colors.red : Colors.grey.shade400,
                        size: 20,
                      ),
                    ),
                  ),
                )
              ],
            ),
            
            // Text Content Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          destination.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 15,
                            color: Colors.amber,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            destination.rating.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Location details with pin icon
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${destination.area}, ${destination.city}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Room type & Bed count specifications
                  Text(
                    '${destination.roomType} • ${destination.guests} guests • ${destination.beds} bed${destination.beds > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Price block
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatPrice(destination.price),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const Text(
                            ' / night',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        ],
                      ),
                      Text(
                        '${destination.distance} km away',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


