import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  // Nome do arquivo do banco local.
  // Esse arquivo fica salvo no dispositivo/navegador do usuário.
  static const String databaseName = 'bookly.db';

  // Versão atual do banco de dados.
  // Sempre que a estrutura das tabelas muda,
  // aumentamos esse número.
  static const int databaseVersion = 4;

  // Guarda uma única instância do banco.
  // O ? significa que ela pode começar como null.
  static Database? _database;

  // Getter responsável por fornecer o banco para o restante do aplicativo.
  static Future<Database> get database async {
    // Se o banco já estiver aberto,
    // apenas retorna a instância existente.
    if (_database != null) {
      return _database!;
    }

    // Caso ainda não exista,
    // inicializa o banco.
    _database = await _initDatabase();
    return _database!;
  }

  // Método responsável por abrir ou criar o banco.
  static Future<Database> _initDatabase() async {
    // Obtém a pasta onde o banco será salvo.
    final databasePath = await getDatabasesPath();
    // Junta o caminho da pasta com o nome do banco.
    final path = join(databasePath, databaseName);

    return openDatabase(
      path,
      version: databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Ativa as chaves estrangeiras.
  // Isso ajuda o SQLite a respeitar relações entre usuários, livros,
  // amigos e empréstimos.
  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Executa quando o banco é criado pela primeira vez.
  // Aqui criamos todas as tabelas do app.
  static Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createBooksTable(db);
    await _createFriendsTable(db);
    await _createLoansTable(db);
    await _createNotificationSettingsTable(db);
    await _createIndexes(db);
  }

  // Executa quando o app já tinha um banco salvo,
  // mas a versão do banco aumentou.
  //
  // Exemplo:
  // O usuário já tinha banco versão 2.
  // Agora o app está na versão 3.
  // Então o SQLite chama essa função para adicionar as colunas novas
  // sem apagar os dados antigos.
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _safeAddColumn(
        db,
        table: 'users',
        columnDefinition: 'updatedAt TEXT',
      );

      await _safeAddColumn(
        db,
        table: 'books',
        columnDefinition: 'updatedAt TEXT',
      );

      await _safeAddColumn(
        db,
        table: 'friends',
        columnDefinition: 'updatedAt TEXT',
      );

      await _safeAddColumn(
        db,
        table: 'loans',
        columnDefinition: 'updatedAt TEXT',
      );

      await _safeAddColumn(
        db,
        table: 'loans',
        columnDefinition: 'reminderEnabled INTEGER NOT NULL DEFAULT 1',
      );

      await _safeAddColumn(
        db,
        table: 'loans',
        columnDefinition: 'reminderDaysBefore INTEGER NOT NULL DEFAULT 1',
      );

      await _safeCreateNotificationSettingsTable(db);
      await _createIndexes(db);
    }

    if (oldVersion < 3) {
      // Foto do livro antes de emprestar.
      // Vai guardar a imagem em base64 no SQLite.
      await _safeAddColumn(
        db,
        table: 'loans',
        columnDefinition: 'beforePhotoUrl TEXT',
      );

      // Foto do livro depois da devolução.
      // Vai permitir comparar o estado antes/depois.
      await _safeAddColumn(
        db,
        table: 'loans',
        columnDefinition: 'afterPhotoUrl TEXT',
      );

      await _createIndexes(db);
    }

    if (oldVersion < 4) {
      // Foto de perfil do usuário local.
      // Salvamos em base64 para funcionar no Chrome, Android e Windows.
      await _safeAddColumn(
        db,
        table: 'users',
        columnDefinition: 'profilePhotoUrl TEXT',
      );
    }
  }

  static Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  profilePhotoUrl TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT
)
    ''');
  }

  static Future<void> _createBooksTable(Database db) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        publisher TEXT,
        category TEXT,
        description TEXT,
        coverUrl TEXT,
        available INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createFriendsTable(Database db) async {
    await db.execute('''
      CREATE TABLE friends (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        name TEXT NOT NULL,
        email TEXT,
        phone TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createLoansTable(Database db) async {
    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,

        -- Usuário dono desse empréstimo.
        userId INTEGER NOT NULL,

        -- Amigo que pegou o livro emprestado.
        friendId INTEGER NOT NULL,

        -- Livro emprestado.
        bookId INTEGER NOT NULL,

        -- Data em que o empréstimo foi feito.
        loanDate TEXT NOT NULL,

        -- Data prevista de devolução.
        dueDate TEXT NOT NULL,

        -- Data real de devolução. Fica null enquanto não devolveu.
        returnedDate TEXT,

        -- Status do empréstimo:
        -- PENDING = pendente
        -- LATE = atrasado
        -- RETURNED = devolvido
        status TEXT NOT NULL DEFAULT 'PENDING',

        -- Observações gerais.
        notes TEXT,

        -- Campo antigo de foto. Mantemos para compatibilidade.
        photoUrl TEXT,

        -- Foto do livro antes de emprestar.
        -- Aqui vamos salvar a imagem em base64.
        beforePhotoUrl TEXT,

        -- Foto do livro depois de devolvido.
        -- Aqui também vamos salvar a imagem em base64.
        afterPhotoUrl TEXT,

        -- Configurações futuras para lembrete/notificações.
        reminderEnabled INTEGER NOT NULL DEFAULT 1,
        reminderDaysBefore INTEGER NOT NULL DEFAULT 1,

        createdAt TEXT NOT NULL,
        updatedAt TEXT,

        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (friendId) REFERENCES friends (id) ON DELETE RESTRICT,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE RESTRICT
      )
    ''');
  }

  static Future<void> _createNotificationSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE notification_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL UNIQUE,
        enabled INTEGER NOT NULL DEFAULT 1,
        defaultDaysBefore INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Versão segura para criar a tabela de notificações quando o banco já existe.
  // O IF NOT EXISTS evita erro caso ela já tenha sido criada antes.
  static Future<void> _safeCreateNotificationSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL UNIQUE,
        enabled INTEGER NOT NULL DEFAULT 1,
        defaultDaysBefore INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Índices deixam buscas mais rápidas.
  // Exemplo: buscar livros por usuário, empréstimos por status,
  // empréstimos por prazo, etc.
  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_books_userId ON books(userId)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_books_available ON books(available)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_friends_userId ON friends(userId)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_userId ON loans(userId)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_friendId ON loans(friendId)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_bookId ON loans(bookId)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_status ON loans(status)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_dueDate ON loans(dueDate)',
    );
  }

  // Adiciona uma coluna sem quebrar o app caso ela já exista.
  //
  // Isso é útil durante desenvolvimento, porque às vezes o banco local
  // já tem parte das colunas.
  static Future<void> _safeAddColumn(
    Database db, {
    required String table,
    required String columnDefinition,
  }) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    } catch (_) {
      // Se a coluna já existe, ignoramos o erro.
    }
  }

  // Fecha o banco local.
  static Future<void> closeDatabase() async {
    final db = _database;

    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Apaga o banco local.
  //
  // Use só em testes, porque isso remove todos os livros,
  // amigos e empréstimos salvos no dispositivo/navegador.
  static Future<void> deleteLocalDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, databaseName);

    await closeDatabase();
    await deleteDatabase(path);
  }
}
