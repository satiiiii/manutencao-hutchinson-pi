// =============================================================================
// ARQUIVO: lib/screens/detalhe_chamado_screen.dart
// FINALIDADE: Mostra todos os dados do chamado e permite ao manutentor
//             assumir o atendimento e depois conclui-lo registrando o que fez.
//             E aqui que o "papel" e substituido: o historico fica gravado.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/chamado.dart';
import '../providers/app_provider.dart';
import '../tema.dart';

class DetalheChamadoScreen extends StatelessWidget {
  final Chamado chamado;
  const DetalheChamadoScreen({super.key, required this.chamado});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final ehManutentor = provider.perfil == PerfilUsuario.manutencao;
    final formatador = DateFormat("dd/MM/yyyy 'as' HH:mm", 'pt_BR');

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do chamado')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------- Cabecalho ----------
          Text(
            chamado.titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(chamado.prioridade.rotulo),
                backgroundColor:
                    TemaApp.corDaPrioridade(chamado.prioridade)
                        .withOpacity(0.12),
              ),
              Chip(
                label: Text(chamado.status.rotulo),
                backgroundColor:
                    TemaApp.corDoStatus(chamado.status).withOpacity(0.12),
              ),
              Chip(
                avatar: Icon(
                  TemaApp.iconeDaEspecialidade(chamado.especialidade),
                  size: 16,
                ),
                label: Text(chamado.especialidade.rotulo),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---------- Dados do equipamento ----------
          _Bloco(
            titulo: 'Equipamento',
            children: [
              _Linha(rotulo: 'Setor', valor: chamado.setor),
              _Linha(rotulo: 'Maquina', valor: chamado.maquina),
            ],
          ),

          // ---------- Relato original ----------
          _Bloco(
            titulo: 'Relato da producao',
            children: [
              Text(chamado.descricao),
              const SizedBox(height: 8),
              Text(
                'Por ${chamado.solicitante} em '
                '${formatador.format(chamado.criadoEm)}',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),

          // ---------- Hipotese da IA (se houver) ----------
          if (chamado.causaProvavelIA != null &&
              chamado.causaProvavelIA!.isNotEmpty)
            _Bloco(
              titulo: 'Causa provavel (sugestao da IA)',
              children: [Text(chamado.causaProvavelIA!)],
            ),

          // ---------- Atendimento ----------
          if (chamado.responsavel != null)
            _Bloco(
              titulo: 'Atendimento',
              children: [
                _Linha(rotulo: 'Responsavel', valor: chamado.responsavel!),
                if (chamado.iniciadoEm != null)
                  _Linha(
                    rotulo: 'Iniciado em',
                    valor: formatador.format(chamado.iniciadoEm!),
                  ),
                if (chamado.concluidoEm != null)
                  _Linha(
                    rotulo: 'Concluido em',
                    valor: formatador.format(chamado.concluidoEm!),
                  ),
                if (chamado.tempoDeAtendimento != null)
                  _Linha(
                    rotulo: 'Tempo total',
                    valor: '${chamado.tempoDeAtendimento!.inMinutes} min',
                  ),
              ],
            ),

          // ---------- Servico executado ----------
          if (chamado.solucao != null)
            _Bloco(
              titulo: 'Servico executado',
              children: [Text(chamado.solucao!)],
            ),

          const SizedBox(height: 24),

          // ---------- Acoes disponiveis para o manutentor ----------
          if (ehManutentor && chamado.status == StatusChamado.aberto)
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Assumir chamado'),
              onPressed: () async {
                await provider.assumirChamado(chamado.id!);
                if (context.mounted) Navigator.pop(context);
              },
            ),

          if (ehManutentor && chamado.status == StatusChamado.emAndamento)
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Concluir chamado'),
              onPressed: () => _abrirDialogoConclusao(context, provider),
            ),
        ],
      ),
    );
  }

  /// Abre uma caixa de dialogo pedindo a descricao do servico executado.
  /// Esse texto alimenta o historico e, depois, o relatorio gerado pela IA.
  Future<void> _abrirDialogoConclusao(
    BuildContext context,
    AppProvider provider,
  ) async {
    final controller = TextEditingController();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (contextoDialogo) => AlertDialog(
        title: const Text('Concluir chamado'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Descreva o que foi feito, pecas trocadas, etc.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contextoDialogo, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(contextoDialogo, true),
            child: const Text('Concluir'),
          ),
        ],
      ),
    );

    if (confirmou == true && controller.text.trim().isNotEmpty) {
      await provider.concluirChamado(chamado.id!, controller.text.trim());
      if (context.mounted) Navigator.pop(context);
    }
  }
}

/// Bloco de conteudo com titulo, usado para organizar a tela em secoes.
class _Bloco extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _Bloco({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black45,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Par rotulo/valor exibido em uma linha.
class _Linha extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _Linha({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
