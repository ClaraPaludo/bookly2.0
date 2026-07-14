# Bookly - Minha Biblioteca

Bookly é um aplicativo desenvolvido em Flutter para gerenciamento de uma biblioteca pessoal. O sistema permite cadastrar livros, amigos e empréstimos, funcionando com banco de dados local SQLite.

## Objetivo do projeto

O objetivo do Bookly é facilitar o controle de livros emprestados, permitindo que o usuário registre quais livros possui, para quem emprestou, qual o prazo de devolução e o estado do livro antes e depois do empréstimo.

## Tecnologias utilizadas

- Flutter
- Dart
- SQLite local
- Sqflite
- Sqflite Common FFI
- Sqflite Common FFI Web
- Image Picker

## Funcionalidades principais

- Cadastro de livros
- Cadastro de amigos
- Registro de empréstimos
- Definição de prazo de devolução
- Controle de status dos empréstimos:
  - Pendente
  - Atrasado
  - Devolvido
- Registro de foto da capa do livro
- Registro de foto antes do empréstimo
- Registro de foto depois da devolução
- Listagem de livros disponíveis e emprestados
- Visualização de empréstimos recentes
- Tela de detalhes do empréstimo
- Armazenamento local dos dados com SQLite

## Banco de dados

O aplicativo utiliza SQLite local, sem necessidade de backend externo.

As principais tabelas utilizadas são:

- `users`
- `books`
- `friends`
- `loans`
- `notification_settings`

A tabela `books` armazena os dados dos livros, incluindo título, autor, categoria, descrição, capa e disponibilidade.

A tabela `friends` armazena os dados das pessoas que podem receber livros emprestados.

A tabela `loans` armazena os empréstimos, incluindo amigo, livro, data do empréstimo, prazo de devolução, status, foto antes do empréstimo e foto depois da devolução.

## Observação sobre armazenamento local

Como o projeto utiliza SQLite local, os dados ficam armazenados no dispositivo ou navegador onde o aplicativo está sendo executado.

No Flutter Web, os dados dependem do armazenamento local do navegador. Para testes no Chrome, recomenda-se executar sempre com a mesma porta:

```bash
flutter run -d chrome --web-port 5000
