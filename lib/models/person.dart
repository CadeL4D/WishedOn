class Person {
  final String id;
  final String name;
  final String avatarUrl;
  final List<dynamic> wishlist; // We can use dynamic or import MyListItem later

  Person({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.wishlist,
  });
}
