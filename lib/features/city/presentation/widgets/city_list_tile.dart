import 'package:flutter/material.dart';
import 'package:pulz_app/features/city/domain/models/ville.dart';

class CityListTile extends StatelessWidget {
  final VilleModel ville;
  final VoidCallback? onTap;

  const CityListTile({
    super.key,
    required this.ville,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFF0F0F0),
        child: Icon(
          Icons.location_city,
          color: Color(0xFF666666),
          size: 20,
        ),
      ),
      title: Text(
        ville.nom,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        [
          if (ville.codePostal.isNotEmpty) ville.codePostal,
          if (ville.departement.isNotEmpty) ville.departement,
        ].join(' - '),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
        ),
      ),
      trailing: ville.population > 0
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ville.populationFormatted,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : null,
    );
  }
}
