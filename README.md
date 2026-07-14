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
## Como acessar e executar o projeto

O código-fonte do projeto Bookly está disponível publicamente no GitHub pelo link: https://github.com/ClaraPaludo/bookly2.0. Para executar o projeto localmente, é necessário ter o Flutter instalado e configurado na máquina. Após acessar o repositório, o usuário pode clonar o projeto, abrir a pasta no editor de código, instalar as dependências com o comando `flutter pub get` e executar o aplicativo no navegador Chrome com o comando `flutter run -d chrome --web-port 5000`.

O uso da porta fixa `5000` é recomendado porque o projeto utiliza SQLite local no navegador. Dessa forma, durante os testes no Flutter Web, os dados têm maior chance de continuar salvos ao fechar e abrir novamente o projeto no mesmo navegador. O aplicativo também pode ser executado em um emulador Android ou em um dispositivo físico configurado com Flutter, utilizando o comando `flutter run`.

Como o Bookly utiliza SQLite local, os dados são armazenados no próprio dispositivo ou navegador onde o aplicativo está sendo executado. No Flutter Web, esses dados ficam salvos no armazenamento local do navegador e podem ser perdidos caso o usuário limpe os dados do site, limpe o cache, utilize aba anônima ou acesse o projeto por outro navegador ou dispositivo. Em Android ou Windows, os dados ficam salvos localmente no aplicativo/dispositivo.
