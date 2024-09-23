import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static const _dbName = 'estudantes.db';
  //static final _dbVersion = 1;
  static const _tableEstudantes = 'tb_estudantes';
  static const _tableLogEstudantes = 'tb_logestudantes';
  
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
  // Criação da tabela de estudantes, se ainda não existir
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tb_estudantes (
        aluno_codigo INTEGER PRIMARY KEY,
        aluno_nome TEXT,
        aluno_nota1 REAL,
        aluno_nota2 REAL,
        aluno_nota3 REAL,
        aluno_situacao TEXT
      );
    ''');

    // Criação da tabela de log, se ainda não existir
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tb_logestudantes (
        log_data TEXT,
        log_time TEXT,
        log_tipoacao TEXT,
        log_aluno INTEGER,
        log_situacao TEXT
      );
    ''');

    // Criação das triggers
    await db.execute('''
      CREATE TRIGGER log_insercao
      AFTER INSERT ON tb_estudantes
      FOR EACH ROW
      BEGIN
          INSERT INTO tb_logestudantes (log_data, log_time, log_tipoacao, log_aluno, log_situacao)
          VALUES (DATE('now'), TIME('now'), 'Inclusão', NEW.aluno_codigo,  NEW.aluno_situacao);
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER log_atualizacao
      AFTER UPDATE ON tb_estudantes
      FOR EACH ROW
      BEGIN
          INSERT INTO tb_logestudantes (log_data, log_time, log_tipoacao, log_aluno, log_situacao)
          VALUES (DATE('now'), TIME('now'), 'Alteração', NEW.aluno_codigo, NEW.aluno_situacao );
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER log_exclusao
      AFTER DELETE ON tb_estudantes
      FOR EACH ROW
      BEGIN
          INSERT INTO tb_logestudantes (log_data, log_time, log_tipoacao, log_aluno, log_situacao)
          VALUES (DATE('now'), TIME('now'), 'Exclusão', OLD.aluno_codigo, NEW.aluno_situacao);
      END;
    ''');
  }

  Future<int> inserirEstudante(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(_tableEstudantes, row);
  }

  Future<int> atualizarEstudante(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['aluno_codigo'];
    return await db.update(_tableEstudantes, row, where: 'aluno_codigo = ?', whereArgs: [id]);
  }

  Future<int> deletarEstudante(int id) async {
    Database db = await instance.database;
    return await db.delete(_tableEstudantes, where: 'aluno_codigo = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> listarEstudantes() async {
    Database db = await instance.database;
    return await db.query(_tableEstudantes);

  }
  
  // Seu código existente para a conexão com o banco de dados...

  Future<bool> alunoExiste(int codigo) async {
    final db = await database;
    var result = await db.query(
      'tb_estudantes',
      where: 'aluno_codigo = ?',
      whereArgs: [codigo],
    );
    return result.isNotEmpty; // Retorna true se o aluno já existe
  }

}