class MyListItem {
  final String id;
  final String name;
  final double price;
  final String url;
  final String? domain;

  MyListItem({
    required this.id,
    required this.name,
    required this.price,
    required this.url,
    this.domain,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'url': url,
      'domain': domain,
    };
  }

  factory MyListItem.fromJson(Map<String, dynamic> json) {
    return MyListItem(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      url: json['url'],
      domain: json['domain'],
    );
  }
}
