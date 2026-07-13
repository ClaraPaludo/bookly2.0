import 'book_model.dart';
import 'friend_model.dart';

class LoanModel {
  BookModel book;
  FriendModel friend;
  DateTime loanDate;
  DateTime returnDate;
  bool returned;

  LoanModel({
    required this.book,
    required this.friend,
    required this.loanDate,
    required this.returnDate,
    this.returned = false,
  });
}
