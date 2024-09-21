import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'db/database_helper.dart';
import 'package:flutter/scheduler.dart'; // Import necessário para usar SchedulerBinding

void main() {

  // Inicializar sqflite_common_ffi para ambientes desktop
  //if (sqfliteFfiInit != null) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  //}

  runApp(const MyApp());

}
 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Estudantes',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: _HomeScreen(), // Chama a tela inicial
    );
  }
}

class _HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  final dbHelper = DatabaseHelper.instance;
  final _codigoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _nota1Controller = TextEditingController();
  final _nota2Controller = TextEditingController();
  final _nota3Controller = TextEditingController();
  bool _codigoInvalido = false;
  bool _nomeInvalido = false;
  final FocusNode _focusCodigo = FocusNode();
  final FocusNode _focusNome = FocusNode();
  final FocusNode _focusNota1 = FocusNode();
  //late ScrollController _scrollController;
 
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> listaDeAlunos = []; // Lista de alunos simulada



  //get listaDeAlunos => null;  
  
  @override

  void dispose() {
    _codigoController.dispose();
    _nomeController.dispose();
    _focusCodigo.dispose();
    _focusNome.dispose();
    _focusNota1.dispose();
    super.dispose();
  }

  

  // Função para validar o código
  void validarCodigo(String value) {
    int? codigoAluno = int.tryParse(value);
    setState(() {
      _codigoInvalido = codigoAluno == null || codigoAluno == 0;
      if (!_codigoInvalido) {
        // Se o código for válido, mover para o próximo campo (Nome)
        FocusScope.of(context).requestFocus(_focusNome);
      }
    });
  }
  
  void validarNome(String value) {
    setState(() {
      _nomeInvalido = value.isEmpty; // Verifica se o nome está vazio
    });
  }   

  void limparCampos() {
    _codigoController.clear();
    _nomeController.clear();
    _nota1Controller.clear();
    _nota2Controller.clear();
    _nota3Controller.clear();
  
    setState(() {
     _codigoInvalido = false; // Resetar a validação do código
     _nomeInvalido = false;   // Resetar a validação do nome
    });
  }
  
  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de  Estudantes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              maxLength: 5,
              controller: _codigoController,
              keyboardType: TextInputType.number,
              focusNode: _focusCodigo,
              decoration: InputDecoration(
                labelText: 'Código do Aluno',
                errorText: _codigoInvalido ? 'O código deve ser diferente de zero e não pode ser nulo' : null,
              ),
              //onChanged: validarCodigo, 
              onChanged: (value) {
                setState(() {
                  if (value.isNotEmpty) {
                    int codigo = int.tryParse(value) ?? 0;
                   // Verifica se o código está entre 1 e 99999
                    _codigoInvalido = (codigo < 1 || codigo > 99999);
                  } else {
                    _codigoInvalido = true; // Caso o campo esteja vazio
                  }
                });
              },
            ),
          
            const SizedBox(height: 20),
            
            TextField(
              maxLength: 30,
              controller: _nomeController,
              focusNode: _focusNome,
              decoration: InputDecoration(
                labelText: 'Nome do Aluno',
                errorText: _nomeInvalido ? 'O nome não pode ser nulo' : null,
              ),
              onChanged: (value) {
                //validarNome(value);
                setState(() {
                  // Verifica se o nome é inválido (se está vazio)
                  _nomeInvalido = value.isEmpty;
                  
                });
              },
              onSubmitted: (value) {
                if (_nomeController.text.isEmpty) {
                  setState(() {
                   _nomeInvalido = true; // Exibe o erro se o nome estiver vazio
                   
                  });
                } else {
                  FocusScope.of(context).requestFocus(_focusNota1); // Move para o próximo campo
                }
                
              },
            ),
            
            TextField(
              maxLength: 3,
              controller: _nota1Controller,
              decoration: const InputDecoration(labelText: 'Nota 1'),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Permite números e ponto (.)
              ]


            ),
            TextField(
              maxLength: 3,
              controller: _nota2Controller,
              decoration: const InputDecoration(labelText: 'Nota 2'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Permite números e ponto (.)
              ],

              
            ),
            TextField(
              maxLength: 3,
              controller: _nota3Controller,
              decoration: const InputDecoration(labelText: 'Nota 3'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), // Permite números e ponto (.)
              ],

            ),

            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _inserirEstudante,
                  child: const Text('Inserir'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _atualizarEstudante,
                  child: const Text('Atualizar'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  //onPressed: _deletarEstudante,
                  child: const Text('Excluir'),
                  onPressed: () {
                    confirmarExclusao(context); // Chama o diálogo de confirmação
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: dbHelper.listarEstudantes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  
                  return ListView(
                    children: snapshot.data!.map((estudante) {
                      return ListTile(
                        title: Text(estudante['aluno_nome']),
                        subtitle: Text(
                          'Código: ${estudante['aluno_codigo']}, '
                          'Nota1: ${estudante['aluno_nota1']}, '
                          'Nota2: ${estudante['aluno_nota2']}, '
                          'Nota3: ${estudante['aluno_nota3']}',
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _inserirEstudante() async {

    int codigo = int.parse(_codigoController.text);
    // Verifica se o aluno já existe
    bool existe = await dbHelper.alunoExiste(codigo);
    String nome = _nomeController.text;
    
    if (existe) {
      // Exibe uma mensagem ou lida com o caso de aluno já existente
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Codigo do aluno já existe!')),
      );
    } else {
    // Aluno não existe, então insere no banco de dados
      if (!validarCampos()) {
        mostrarMensagem("Erro na validação. Não foi possível incluir o aluno.");
        return;
      }

      Map<String, dynamic> row = {
        'aluno_codigo': codigo,
        'aluno_nome': _nomeController.text,
        'aluno_nota1': double.parse(_nota1Controller.text),
        'aluno_nota2': double.parse(_nota2Controller.text),
        'aluno_nota3': double.parse(_nota3Controller.text),
      };
      await dbHelper.inserirEstudante(row);
     // Atualiza a UI após a inserção     
      //setState(() {});

      setState(() {
         listaDeAlunos.add(row);  // Supondo que você tenha uma lista de alunos
      });

      
            // Aguarda um pequeno tempo para o layout ser atualizado
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          // Rola para o final da lista após a inserção
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });








      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aluno inserido com sucesso!')),
      );
      limparCampos();
    } 
  }
 
  void _atualizarEstudante() async {

    int codigo = int.parse(_codigoController.text);
    // Verifica se o aluno já existe
    bool existe = await dbHelper.alunoExiste(codigo);
    
    if (!existe){
      mostrarMensagem("Aluno não cadastrado ! .");
      return;
    }
    
    if (!validarCampos()) {
      mostrarMensagem("Erro na validação. Não foi possível Alterar o aluno.");
      return;
    }


    Map<String, dynamic> row = {
      'aluno_codigo': int.parse(_codigoController.text),
      'aluno_nome': _nomeController.text,
      'aluno_nota1': double.parse(_nota1Controller.text),
      'aluno_nota2': double.parse(_nota2Controller.text),
      'aluno_nota3': double.parse(_nota3Controller.text),
    };
    await dbHelper.atualizarEstudante(row);
    setState(() {});
    limparCampos();
  }

  void confirmarExclusao(BuildContext context) {
   showDialog(
    context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmação'),
          content: const Text('Deseja realmente excluir este registro?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo sem excluir
              },
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () {
                // Chame sua função de exclusão aqui
                _deletarEstudante();
                Navigator.of(context).pop(); // Fecha o diálogo após a exclusão
              },
            ),
          ],
        );
      },
    );
  }

  void _deletarEstudante() async {
    int codigo = int.parse(_codigoController.text);
    await dbHelper.deletarEstudante(codigo);
    setState(() {});
    limparCampos();
  }
  
  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
      content: Text(mensagem),
      duration: const Duration(seconds: 2), // Tempo que a mensagem ficará visível
      ),
    );
  }
  bool validarCampos() {
  // Validar código
    int codigo = int.tryParse(_codigoController.text) ?? 0;



    if (codigo <= 0) {
      mostrarMensagem("O código deve ser maior que zero.");
      return false;
    }

    // Validar nome
    String nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      mostrarMensagem("O nome do aluno não pode ser nulo.");
      return false;
    }

    // Validar notas
    double nota1 = double.tryParse(_nota1Controller.text) ?? 0;
    double nota2 = double.tryParse(_nota2Controller.text) ?? 0;
    double nota3 = double.tryParse(_nota3Controller.text) ?? 0;

    if (nota1 > 10 || nota2 > 10 || nota3 > 10) {
      mostrarMensagem(" Nota não pode ser maior que 10.");
      return false;
    }

    return true; // Se todas as validações passarem
  }



}