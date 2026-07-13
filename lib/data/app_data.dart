import '../models/book_model.dart';
import '../models/friend_model.dart';
import '../models/loan_model.dart';

List<BookModel> books = [
  BookModel(
    title: "Amor, Teoricamente",
    author: "Ali Hazelwood",
    image:
        "https://img.br.my-best.com/product_images/78119c9e42075cdc6b7a8f2448ff0af9.jpg",
    year: "2023",
    category: "Romance",
    description: "Uma história de romance entre pesquisadores.",
  ),

  BookModel(
    title: "Patinando no Amor",
    author: "Lynn Painter",
    image:
        "https://http2.mlstatic.com/D_NQ_NP_812454-MLA94687199899_102025-O.webp",
    year: "2022",
    category: "Romance",
    description: "Uma história leve sobre amizade.",
    available: false,
  ),

  BookModel(
    title: "A Hipótese do Amor",
    author: "Ali Hazelwood",
    image: "https://m.media-amazon.com/images/I/81LTEfXYgcL.jpg",
    year: "2021",
    category: "Romance",
    description: "Uma pesquisadora vive uma situação inesperada.",
  ),
];

List<FriendModel> friends = [];

List<LoanModel> loans = [];
