import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class Produto {
  String nome;
  int quantidade;
  int quantidadeMinima;
  double preco;

  Produto({
    required this.nome,
    required this.quantidade,
    required this.quantidadeMinima,
    required this.preco,
  });

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'quantidade': quantidade,
        'quantidadeMinima': quantidadeMinima,
        'preco': preco,
      };

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      nome: json['nome'],
      quantidade: json['quantidade'],
      quantidadeMinima: json['quantidadeMinima'],
      preco: (json['preco'] as num).toDouble(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Estoque',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 6, 7, 105),
          foregroundColor: Color.fromARGB(223, 206, 206, 206),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Produto> produtos = [];

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  // Função que grava os dados no "disco" do PC/Celular
  Future<void> salvarProdutos() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> lista = produtos.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('produtos', lista);
  }

  // Função que busca os dados ao abrir o app
  Future<void> carregarProdutos() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? lista = prefs.getStringList('produtos');
    if (lista != null) {
      setState(() {
        produtos = lista.map((item) => Produto.fromJson(jsonDecode(item))).toList();
      });
    }
  }

  void menuAdicionar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.add)),
              title: const Text("Cadastrar produto"),
              onTap: () async {
                Navigator.pop(context);
                final novo = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CadastroPage()),
                );
                if (novo != null) {
                  setState(() => produtos.add(novo));
                  salvarProdutos();
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.warning_amber, color: Colors.white)),
              title: const Text("Produtos com estoque baixo"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EstoqueBaixoPage(produtos: produtos)),
                );
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.assignment, color: Colors.white)),
              title: const Text("Gerar relatório geral"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RelatorioGeralPage(produtos: produtos)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void excluir(int index) {
    setState(() => produtos.removeAt(index));
    salvarProdutos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/caixa.png', 
              height: 35,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.inventory_2, color: Color.fromARGB(255, 234, 236, 235));
              },
            ),
            const SizedBox(width: 12),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 22, color: Colors.white),
                children: [
                  TextSpan(text: "MEU "),
                  TextSpan(
                    text: "ESTOQUE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: produtos.isEmpty
          ? const Center(
              child: Text("Nenhum produto cadastrado",
                  style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 85),
              itemCount: produtos.length,
              itemBuilder: (context, index) {
                final p = produtos[index];
                bool alerta = p.quantidade <= p.quantidadeMinima;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text(p.nome.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Qtd: ${p.quantidade}",
                            style: TextStyle(
                                color: alerta ? Colors.red : Colors.black87,
                                fontWeight: alerta ? FontWeight.bold : FontWeight.normal)),
                        Text("Preço: R\$ ${p.preco.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note, color: Colors.indigo),
                          onPressed: () async {
                            final editado = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CadastroPage(produto: p)),
                            );
                            if (editado != null) {
                              setState(() => produtos[index] = editado);
                              salvarProdutos();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => excluir(index),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ControlePage(produto: p)),
                      );
                      // Ao voltar da tela de controle, salvamos as alterações de quantidade
                      setState(() {});
                      salvarProdutos();
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: menuAdicionar,
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ================= CADASTRO =================
class CadastroPage extends StatefulWidget {
  final Produto? produto;
  const CadastroPage({super.key, this.produto});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final nome = TextEditingController();
  final qtd = TextEditingController();
  final min = TextEditingController();
  final preco = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.produto != null) {
      nome.text = widget.produto!.nome;
      qtd.text = widget.produto!.quantidade.toString();
      min.text = widget.produto!.quantidadeMinima.toString();
      preco.text = widget.produto!.preco.toString();
    }
  }

  void salvar() {
    if (nome.text.isEmpty ||
        qtd.text.isEmpty ||
        min.text.isEmpty ||
        preco.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos!")));
      return;
    }
    Navigator.pop(
        context,
        Produto(
          nome: nome.text,
          quantidade: int.parse(qtd.text),
          quantidadeMinima: int.parse(min.text),
          preco: double.parse(preco.text.replaceAll(',', '.')),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.produto == null ? "Novo Produto" : "Editar Produto")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInput(nome, "Nome do Produto", Icons.shopping_bag_outlined),
            _buildInput(qtd, "Quantidade Atual", Icons.numbers, isNumeric: true),
            _buildInput(min, "Estoque Mínimo", Icons.low_priority, isNumeric: true),
            _buildInput(preco, "Preço Unitário (R\$)", Icons.payments_outlined,
                isNumeric: true),
            const SizedBox(height: 30),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: salvar,
                child: const Text("SALVAR NO ESTOQUE",
                    style: TextStyle(fontWeight: FontWeight.bold)))
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }
}

// ================= CONTROLE (CORRIGIDO COM CHAVES) =================
class ControlePage extends StatefulWidget {
  final Produto produto;
  const ControlePage({super.key, required this.produto});
  @override
  State<ControlePage> createState() => _ControlePageState();
}

class _ControlePageState extends State<ControlePage> {
  final mov = TextEditingController();

  void realizarMovimento(bool isEntrada) {
    if (mov.text.isEmpty) return;
    int v = int.parse(mov.text);
    if (!isEntrada && v > widget.produto.quantidade) {
      msg("❌ Produto insuficiente!");
      return;
    }
    setState(() {
      if (isEntrada) {
        widget.produto.quantidade += v;
      } else {
        widget.produto.quantidade -= v;
      }
    });
    msg(isEntrada ? "✅ Entrada realizada!" : "✅ Saída realizada!");
    mov.clear();
    verificar();
  }

  void verificar() {
    if (widget.produto.quantidade == 0) {
      msg("❌ ATENÇÃO: Produto zerado!");
    } else if (widget.produto.quantidade <= widget.produto.quantidadeMinima) {
      msg("⚠️ Estoque baixo!");
    }
  }

  void msg(String t) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.produto.nome)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoCard("ESTOQUE", widget.produto.quantidade.toString(),
                      Colors.white),
                  _infoCard(
                      "VALOR",
                      "R\$ ${widget.produto.preco.toStringAsFixed(2)}",
                      Colors.greenAccent),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: mov,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Quantidade", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed: () => realizarMovimento(true),
                  icon: const Icon(Icons.add),
                  label: const Text("ENTRADA"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15)),
                )),
                const SizedBox(width: 15),
                Expanded(
                    child: ElevatedButton.icon(
                  onPressed: () => realizarMovimento(false),
                  icon: const Icon(Icons.remove),
                  label: const Text("SAÍDA"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(15)),
                )),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: valColor, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ================= RELATÓRIO GERAL =================
class RelatorioGeralPage extends StatelessWidget {
  final List<Produto> produtos;
  const RelatorioGeralPage({super.key, required this.produtos});

  @override
  Widget build(BuildContext context) {
    // Cálculo de valor total removido daqui
    return Scaffold(
      appBar: AppBar(
        title: const Text("RELATÓRIO DE ESTOQUE"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Cabeçalho simplificado apenas com o título da contagem
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: const Text(
              "ITENS CADASTRADOS",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white, 
                  fontSize: 18,
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 1.2),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: produtos.length,
              itemBuilder: (context, i) {
                final p = produtos[i];
                return Card( // Adicionei um Card para ficar mais organizado visualmente
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.inventory, color: Color(0xFF1A237E)),
                    title: Text(
                      p.nome.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Quantidade em estoque: ${p.quantidade} unidades",
                      style: const TextStyle(fontSize: 15),
                    ),
                    // Trailing (preço à direita) removido daqui
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
// ================= ESTOQUE BAIXO =================
class EstoqueBaixoPage extends StatelessWidget {
  final List<Produto> produtos;
  const EstoqueBaixoPage({super.key, required this.produtos});

  @override
  Widget build(BuildContext context) {
    final lista =
        produtos.where((p) => p.quantidade <= p.quantidadeMinima).toList();
    return Scaffold(
      appBar: AppBar(
          title: const Text("RELATÓRIO DE ALERTA"),
          backgroundColor: Colors.orange.shade900),
      body: lista.isEmpty
          ? const Center(child: Text("Estoque em dia! ✅"))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: lista.length,
              itemBuilder: (context, i) => Card(
                color: Colors.orange.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: Text(lista[i].nome,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Apenas ${lista[i].quantidade} unidades restando."),
                ),
              ),
            ),
    );
  }
}