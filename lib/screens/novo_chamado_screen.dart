// =============================================================================
// ARQUIVO: lib/screens/novo_chamado_screen.dart
// FINALIDADE: Formulario de abertura de chamado.
//
// AQUI ESTA A PRIMEIRA INTEGRACAO COM IA:
// o lider de producao descreve o problema com as proprias palavras e toca em
// "Analisar com IA". O app envia setor, maquina e descricao para o Gemini,
// que devolve titulo, especialidade, prioridade e causa provavel ja
// preenchidos no formulario. O usuario pode corrigir tudo antes de salvar.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chamado.dart';
import '../providers/app_provider.dart';
import '../services/ia_service.dart';

class NovoChamadoScreen extends StatefulWidget {
  const NovoChamadoScreen({super.key});

  @override
  State<NovoChamadoScreen> createState() => _NovoChamadoScreenState();
}

class _NovoChamadoScreenState extends State<NovoChamadoScreen> {
  final _chaveFormulario = GlobalKey<FormState>();

  final _controllerSetor = TextEditingController();
  final _controllerMaquina = TextEditingController();
  final _controllerDescricao = TextEditingController();
  final _controllerTitulo = TextEditingController();

  Especialidade _especialidade = Especialidade.mecanica;
  Prioridade _prioridade = Prioridade.media;
  String? _causaProvavelIA;

  // Flags de controle da interface durante operacoes assincronas.
  bool _analisando = false;
  bool _salvando = false;

  @override
  void dispose() {
    _controllerSetor.dispose();
    _controllerMaquina.dispose();
    _controllerDescricao.dispose();
    _controllerTitulo.dispose();
    super.dispose();
  }

  /// Exibe uma mensagem rapida na parte inferior da tela.
  void _avisar(String mensagem, {bool erro = false}) {
    if (!mounted) return; // evita usar o context de uma tela ja fechada
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Colors.red.shade700 : null,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ACAO 1: chamar a IA para classificar o chamado
  // ---------------------------------------------------------------------------
  Future<void> _analisarComIa() async {
    if (_controllerDescricao.text.trim().length < 10) {
      _avisar('Descreva o problema com mais detalhes antes de analisar.',
          erro: true);
      return;
    }

    setState(() => _analisando = true);

    try {
      final sugestao = await context.read<AppProvider>().triar(
            descricao: _controllerDescricao.text,
            maquina: _controllerMaquina.text,
            setor: _controllerSetor.text,
          );

      // Preenche o formulario com o que a IA sugeriu.
      setState(() {
        _controllerTitulo.text = sugestao.titulo;
        _especialidade = sugestao.especialidade;
        _prioridade = sugestao.prioridade;
        _causaProvavelIA = sugestao.causaProvavel;
      });

      _avisar('Sugestao aplicada. Revise antes de enviar.');
    } on IaException catch (e) {
      // Se a IA falhar, o chamado ainda pode ser aberto manualmente:
      // a IA e um apoio, nao uma dependencia do processo.
      _avisar(e.mensagem, erro: true);
    } finally {
      if (mounted) setState(() => _analisando = false);
    }
  }

  // ---------------------------------------------------------------------------
  // ACAO 2: gravar o chamado no banco
  // ---------------------------------------------------------------------------
  Future<void> _salvar() async {
    if (!_chaveFormulario.currentState!.validate()) return;

    setState(() => _salvando = true);

    final provider = context.read<AppProvider>();

    final novo = Chamado(
      titulo: _controllerTitulo.text.trim(),
      descricao: _controllerDescricao.text.trim(),
      setor: _controllerSetor.text.trim(),
      maquina: _controllerMaquina.text.trim(),
      especialidade: _especialidade,
      prioridade: _prioridade,
      status: StatusChamado.aberto,
      solicitante: provider.nomeUsuario ?? 'Nao identificado',
      causaProvavelIA: _causaProvavelIA,
      criadoEm: DateTime.now(),
    );

    try {
      await provider.criarChamado(novo);
      if (!mounted) return;
      Navigator.pop(context); // volta para a lista
      _avisar('Chamado aberto com sucesso.');
    } catch (e) {
      _avisar('Erro ao salvar o chamado: $e', erro: true);
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo chamado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _chaveFormulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _controllerSetor,
                decoration: const InputDecoration(
                  labelText: 'Setor / Linha',
                  hintText: 'Ex.: Linha 3 - Injecao',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o setor' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _controllerMaquina,
                decoration: const InputDecoration(
                  labelText: 'Maquina / Equipamento',
                  hintText: 'Ex.: Prensa 07',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe a maquina'
                    : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _controllerDescricao,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'O que esta acontecendo?',
                  hintText: 'Descreva com suas palavras, como falaria com o '
                      'manutentor.',
                  alignLabelWithHint: true,
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Descreva o problema com mais detalhes'
                    : null,
              ),
              const SizedBox(height: 12),

              // --------- Botao que aciona a IA ---------
              OutlinedButton.icon(
                onPressed: _analisando ? null : _analisarComIa,
                icon: _analisando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  _analisando ? 'Analisando...' : 'Analisar com IA',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 20),

              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Classificacao',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'Preenchida pela IA. Corrija se necessario.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _controllerTitulo,
                decoration: const InputDecoration(labelText: 'Titulo'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Informe um titulo'
                    : null,
              ),
              const SizedBox(height: 12),

              // DropdownButtonFormField integra o seletor ao Form,
              // permitindo validacao junto com os demais campos.
              DropdownButtonFormField<Especialidade>(
                value: _especialidade,
                decoration: const InputDecoration(labelText: 'Especialidade'),
                items: Especialidade.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.rotulo),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _especialidade = v!),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<Prioridade>(
                value: _prioridade,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: Prioridade.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.rotulo),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _prioridade = v!),
              ),

              // Mostra a hipotese da IA apenas quando ela existir.
              if (_causaProvavelIA != null &&
                  _causaProvavelIA!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Causa provavel sugerida pela IA',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_causaProvavelIA!),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: const Icon(Icons.send),
                label: Text(_salvando ? 'Enviando...' : 'Abrir chamado'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
