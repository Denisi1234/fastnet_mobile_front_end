import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:fastnet_mobile_front_end/ui/widgets/destination.dart';
import 'package:flutter/material.dart';

class Destinations extends StatelessWidget {
  final List<Destination> filteredList;
  final String? selectedDatesText;
  final int numNights;

  const Destinations({
    Key? key,
    required this.filteredList,
    this.selectedDatesText,
    required this.numNights,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (filteredList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 60.0, left: 30, right: 30),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No rooms found in this area',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              const Text(
                'Try searching for "Dodoma", "Dar es Salaam", "Mtumba", "Sabasaba" or clear filters.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const ScrollPhysics(),
      padding: const EdgeInsets.only(top: 40, left: 30, right: 30),
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 30),
      shrinkWrap: true,
      itemCount: filteredList.length,
      itemBuilder: (BuildContext context, int index) {
        final destination = filteredList[index];
        return DestinationWidget(
          destination: destination,
          index: index,
          selectedDatesText: selectedDatesText,
          numNights: numNights,
        );
      },
    );
  }
}

