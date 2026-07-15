// Classe que representa um livro dentro do aplicativo.
//
// Sempre que um livro for criado, ele será um objeto desta classe.
class BookModel {
  String title;
  String author;
  String image;
  String year;
  String category;
  String description;
  // Indica se o livro está disponível para empréstimo.
  // true = disponível
  // false = emprestado
  bool available;

  BookModel({
    // "required" significa que esses dados são obrigatórios.
    required this.title,
    required this.author,
    required this.image,
    required this.year,
    required this.category,
    required this.description,
    this.available = true,
  });
}
