// =============================================================================
// ARQUIVO: lib/screens/relatorio_screen.dart
// FINALIDADE: SEGUNDA INTEGRACAO COM IA.
//             O usuario escolhe um periodo; o app busca os chamados desse
//             intervalo no Firestore, calcula os indicadores (total, MTTR,
//             distribuicao por especialidade e por maquina) e envia tudo para
//             o Gemini, que devolve um relatorio gerencial em texto corrido
//             com analise de padroes e recomendacoes de preventiva.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/ia_service.dart';

class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  // Periodo padrao: ultimos 30 dias.
  DateTime _inicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fim = DateTime.now();

  bool _gerando = false;
  String? _relatorio;
  String? _erro;

  final _formatador = DateFormat('dd/MM/yyyy', 'pt_BR');

  /// Abre o calendario nativo para o usuario escolher a data.
  Future<void> _escolherData({required bool ehInicio}) async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: ehInicio ? _inicio : _fim,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (escolhida == null) return;

    setState(() {
      if (ehInicio) {
        // Zera o horario para incluir o dia inteiro na busca.
        _inicio = DateTime(escolhida.year, escolhida.month, escolhida.day);
      } else {
        _fim = DateTime(
            escolhida.year, escolhida.month, escolhida.day, 23, 59, 59);
      }
    });
  }

  Future<void> _gerar() async {
    setState(() {
      _gerando = true;
      _relatorio = null;
      _erro = null;
    });

    try {
      final texto =
          await context.read<AppProvider>().gerarRelatorio(_inicio, _fim);
      setState(() => _relatorio = texto);
    } on IaException catch (e) {
      setState(() => _erro = e.mensagem);
    } catch (e) {
      setState(() => _erro = 'Erro inesperado ao gerar o relatorio: $e');
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatorio com IA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Selecione o periodo e gere uma analise automatica dos chamados.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _BotaoData(
                  rotulo: 'De',
                  data: _formatador.format(_inicio),
                  aoTocar: () => _escolherData(ehInicio: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BotaoData(
                  rotulo: 'Ate',
                  data: _formatador.format(_fim),
                  aoTocar: () => _escolherData(ehInicio: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: _gerando ? null : _gerar,
            icon: _gerando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_gerando ? 'Gerando...' : 'Gerar relatorio'),
          ),
          const SizedBox(height: 20),

          // ---------- Mensagem de erro ----------
          if (_erro != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_erro!)),
                ],
              ),
            ),

          // ---------- Relatorio gerado ----------
          if (_relatorio != null)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Periodo ${_formatador.format(_inicio)} a '
                            '${_formatador.format(_fim)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Copiar permite colar o relatorio em um e-mail
                        // ou no grupo da lideranca.
                        IconButton(
                          tooltip: 'Copiar',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _relatorio!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Relatorio copiado.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    // SelectableText permite ao usuario marcar e copiar
                    // apenas um trecho do texto.
                    SelectableText(
                      _relatorio!,
                      style: const TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botao que exibe uma data e abre o seletor ao ser tocado.
class _BotaoData extends StatelessWidget {
  final String rotulo;
  final String data;
  final VoidCallback aoTocar;

  const _BotaoData({
    required this.rotulo,
    required this.data,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoTocar,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: rotulo,
          prefixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(data),
      ),
    );
  }
}
