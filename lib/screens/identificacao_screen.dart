// =============================================================================
// ARQUIVO: lib/screens/identificacao_screen.dart
// FINALIDADE: Primeira tela do app. O usuario informa o nome e escolhe o
//             perfil (producao ou manutencao). Optamos por uma identificacao
//             simples, sem senha, porque os aparelhos ficam dentro da fabrica
//             e o objetivo e substituir o papel com o menor atrito possivel.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../tema.dart';

class IdentificacaoScreen extends StatefulWidget {
  const IdentificacaoScreen({super.key});

  @override
  State<IdentificacaoScreen> createState() => _IdentificacaoScreenState();
}

class _IdentificacaoScreenState extends State<IdentificacaoScreen> {
  // A GlobalKey do formulario permite validar todos os campos de uma vez.
  final _chaveFormulario = GlobalKey<FormState>();

  // Controller le o que o usuario digitou no campo de texto.
  final _controllerNome = TextEditingController();

  PerfilUsuario _perfilSelecionado = PerfilUsuario.producao;

  @override
  void dispose() {
    // Libera a memoria do controller quando a tela e destruida.
    _controllerNome.dispose();
    super.dispose();
  }

  void _entrar() {
    // `validate()` dispara os validators de cada campo do formulario.
    if (!_chaveFormulario.currentState!.validate()) return;

    context.read<AppProvider>().identificar(
          _controllerNome.text,
          _perfilSelecionado,
        );
    // Nao chamamos Navigator aqui: o RoteadorInicial em main.dart percebe a
    // mudanca de estado e troca a tela sozinho.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea evita que o conteudo fique embaixo da barra de status.
      body: SafeArea(
        // SingleChildScrollView impede o erro de "overflow" quando o teclado
        // abre em telas pequenas - parte do requisito de responsividade.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _chaveFormulario,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.engineering,
                  size: 72,
                  color: TemaApp.corPrimaria,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manutencao Hutchinson',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chamados digitais de manutencao',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _controllerNome,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Seu nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (valor) =>
                      (valor == null || valor.trim().length < 3)
                          ? 'Informe seu nome completo'
                          : null,
                ),
                const SizedBox(height: 24),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Voce e:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),

                // Gera um card selecionavel para cada perfil disponivel.
                ...PerfilUsuario.values.map((perfil) {
                  final selecionado = _perfilSelecionado == perfil;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: selecionado
                        ? TemaApp.corPrimaria.withOpacity(0.08)
                        : Colors.white,
                    child: ListTile(
                      leading: Icon(
                        perfil == PerfilUsuario.producao
                            ? Icons.factory_outlined
                            : Icons.build_outlined,
                        color: selecionado ? TemaApp.corPrimaria : Colors.grey,
                      ),
                      title: Text(perfil.rotulo),
                      trailing: selecionado
                          ? const Icon(Icons.check_circle,
                              color: TemaApp.corPrimaria)
                          : null,
                      onTap: () =>
                          setState(() => _perfilSelecionado = perfil),
                    ),
                  );
                }),

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _entrar,
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
