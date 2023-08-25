import 'package:flutter/material.dart';
import 'package:flutter_qjs/flutter_qjs.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  IsolateQjs? _engine;
  IsolateFunction? _setCallJs;
  IsolateFunction? _setConsoleJs;
  IsolateFunction? _funcaoLocal;
  String texto = "AGUARDANDO";

  @override
  void initState() {
    super.initState();
    init();
  }

  Future init() async {
    _engine = IsolateQjs();

//COLOCANDO CONSOLE
    _setConsoleJs = await _engine!.evaluate('''
(val) => {
      this.console = {};
      this.console.log = val;
    }
''');
    await _setConsoleJs!.invoke([
      IsolateFunction((String valorLog) => print(valorLog)),
    ]);

//PREPARANDO P RECEBER FUNCOES
    _setCallJs = await _engine!.evaluate('''
      (tipo, funcao) => {
        this[tipo] = funcao;
      }
''');

//SETANDO CALLBACK
    await _setCallJs!.invoke([
      'CALL_GLOBAL',
      IsolateFunction(
        (
          String funcao,
          List args,
        ) =>
            callbackLocal(
          funcao,
          args,
        ),
      )
    ]);

//FAZENDO O BIND
    await _engine!.evaluate('''
this.TesteService = {};

this.TesteService.chamarDart = async (param1) => { 
  console.log("Chamou o FUNCAO DO JS PARA CHAMAR DART ");
   var args = [];
   args.push((param1 == null ? null : JSON.stringify(param1)));
   await this.CALL_GLOBAL('chamarDart', args);
   return null; 
}
''');

//CRiando JS
    _funcaoLocal = await _engine!.evaluate('''
this.Regra1 = {};

this.Regra1.chamarJs = async (param1) => { 
   console.log("Chamou o JS ");
   var resp = await this.TesteService.chamarDart(param1);
   console.log("Retornou p JS ");
   return (resp == null ? null : JSON.parse(resp)); 
}

async (funcao, parametros) =>  {
  console.log("TESTANDO ");
  if(funcao == 'chamarJs'){
    var resp = await this.Regra1.chamarJs(parametros);
    return JSON.stringify(resp);
  } 
}

''');
  }

  Future callbackLocal(String funcao, List parametros) async {
    print("CHAMOU O DART $parametros");
    await Future.delayed(Duration(seconds: 5));
    print("ESPEROU OS 5 seg $parametros");
    return parametros;
  }

  Future rodarFuncao() async {
    setState(() {
      texto = 'iniciando ...';
    });

    Future.delayed(Duration(seconds: 5));

    var resp = await _funcaoLocal!.invoke(['chamarJs', []]);

    setState(() {
      texto = 'terminou $resp';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(texto),
            Text(
              '',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: rodarFuncao,
        tooltip: 'test',
        child: const Icon(Icons.run_circle),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
