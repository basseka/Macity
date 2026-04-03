class TheatreVenue {
  final String id;
  final String name;
  final String description;
  final String city;
  final String horaires;
  final String? ticketUrl;
  final String? websiteUrl;
  final bool hasOnlineTicket;
  final String image;
  final bool isVerified;

  const TheatreVenue({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.horaires,
    this.ticketUrl,
    this.websiteUrl,
    required this.hasOnlineTicket,
    required this.image,
    this.isVerified = false,
  });
}
