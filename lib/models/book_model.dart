class BookModel {
  String title;
  String author;
  String image;
  String year;
  String category;
  String description;
  bool available;

  BookModel({
    required this.title,
    required this.author,
    required this.image,
    required this.year,
    required this.category,
    required this.description,
    this.available = true,
  });
}
