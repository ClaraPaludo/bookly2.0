// Importa a classe BookModel.
// Ela será usada para armazenar qual livro foi emprestado.
import 'book_model.dart';
import 'friend_model.dart';

// Classe responsável por representar um empréstimo de livro.
class LoanModel {
  // Guarda o livro que foi emprestado.
  BookModel book;
  FriendModel friend;
  // Data em que o empréstimo foi realizado.
  DateTime loanDate;
  DateTime returnDate;
  // Indica se o livro já foi devolvido.
  // false = ainda não devolveu
  // true = devolveu
  bool returned;

  LoanModel({
    required this.book,
    required this.friend,
    required this.loanDate,
    required this.returnDate,
    this.returned = false,
  });
}
