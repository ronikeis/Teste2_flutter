import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseHelper {
  static final _dbName = 'estudantes.db';
  static final _dbVersion = 1;
  static final _tableEstudantes = 'tb_estudantes';
  static final _tableLogEstudantes = 'tb_logestudantes';
  
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
    await db.execute('''
      CREATE TABLE $_tableEstudantes (
        aluno_codigo INTEGER PRIMARY KEY,
        aluno_nome TEXT,
        aluno_nota1 REAL,
        aluno_nota2 REAL,
        aluno_nota3 REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tableLogEstudantes (
        log_data TEXT,
        log_time TEXT,
        log_tipoacao TEXT,
        log_aluno INTEGER
      )
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

  Future _inserirLog(String tipoAcao, int alunoCodigo) async {
    final db = await database;
    DateTime now = DateTime.now();
    await db.insert('tb_logestudantes', {
      'log_data': now.toIso8601String().split('T')[0],
      'log_time': now.toIso8601String().split('T')[1],
      'log_tipoacao': tipoAcao,
      'log_aluno': alunoCodigo
    });
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