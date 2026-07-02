import 'package:flutter/material.dart';

class ReviewsScreen extends StatefulWidget {
  final String lodgeName;

  const ReviewsScreen({Key? key, required this.lodgeName}) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  // Initial list of guest reviews
  final List<Map<String, dynamic>> _reviews = [
    {
      'guestName': 'Baraka Mwangi',
      'rating': 5,
      'date': 'June 18, 2026',
      'comment': 'Outstanding experience! The rooms are exceptionally clean, air conditioning works perfectly, and the location is super convenient near local dining.',
      'avatar': 'assets/images/man2.jpeg'
    },
    {
      'guestName': 'Christina Kim',
      'rating': 4,
      'date': 'June 05, 2026',
      'comment': 'Really comfortable lodge. The host was very responsive and helpful. Safe secure parking and very fast Wi-Fi. Highly recommended.',
      'avatar': 'assets/images/man.jpeg'
    },
    {
      'guestName': 'John Kamau',
      'rating': 5,
      'date': 'May 28, 2026',
      'comment': 'Absolutely beautiful setup. Feels premium at an affordable budget. Check-in was fully automated and effortless.',
      'avatar': 'assets/images/man2.jpeg'
    }
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  int _selectedRating = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _reviews.insert(0, {
          'guestName': _nameController.text.trim(),
          'rating': _selectedRating,
          'date': 'Today',
          'comment': _commentController.text.trim(),
          'avatar': 'assets/images/user-2.png' // Fallback avatar asset
        });
      });
      
      _nameController.clear();
      _commentController.clear();
      setState(() {
        _selectedRating = 5;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully! Thank you.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guest Reviews', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
            Text(widget.lodgeName, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Write a review block (collapsible or neat input card)
            const Text('Write a Guest Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your full name',
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    // Interactive Star Selection
                    Row(
                      children: [
                        const Text('Rating: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final score = index + 1;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRating = score;
                                });
                              },
                              child: Icon(
                                Icons.star,
                                color: score <= _selectedRating ? Colors.amber : Colors.grey.shade300,
                                size: 28,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Your Comment',
                        hintText: 'Share details of your experience...',
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please write a review comment';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Submit Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Airbnb-style rating category scores
            const Text('Rating Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildRatingMetric('Cleanliness', 4.8),
                _buildRatingMetric('Accuracy', 4.9),
                _buildRatingMetric('Communication', 4.7),
                _buildRatingMetric('Location', 4.9),
                _buildRatingMetric('Check-in', 4.8),
                _buildRatingMetric('Value', 4.6),
              ],
            ),
            const SizedBox(height: 32),

            // Reviews List
            Text('All Reviews (${_reviews.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final rev = _reviews[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: AssetImage(rev['avatar']),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rev['guestName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(rev['date'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: List.generate(5, (starIndex) {
                              return Icon(
                                Icons.star,
                                color: starIndex < rev['rating'] ? Colors.black87 : Colors.grey.shade300,
                                size: 14,
                              );
                            }),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rev['comment'],
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingMetric(String label, double score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score / 5.0,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.black87),
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
