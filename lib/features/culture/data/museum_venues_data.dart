class MuseumVenue {
  final String id;
  final String name;
  final String description;
  final String category;
  final String city;
  final String horaires;
  final String? ticketUrl;
  final String websiteUrl;
  final bool hasOnlineTicket;
  final String image;

  const MuseumVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.city,
    required this.horaires,
    this.ticketUrl,
    required this.websiteUrl,
    required this.hasOnlineTicket,
    required this.image,
  });
}
