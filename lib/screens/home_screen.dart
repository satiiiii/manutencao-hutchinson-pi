// =============================================================================
// ARQUIVO: lib/screens/home_screen.dart
// FINALIDADE: Tela principal. Lista os chamados em tempo real, permite filtrar
//             por status e da acesso as demais telas (novo chamado, detalhe e
//             relatorio de IA).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chamado.dart';
import '../providers/app_provider.dart';
import '../widgets/chamado_card.dart';
import 'novo_chamado_screen.dart';
import 'detalhe_chamado_screen.dart';
import 'relatorio_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final ehProducao = provider.perfil == PerfilUsuario.producao;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chamados de manutencao'),
        actions: [
          IconButton(
            tooltip: 'Relatorio com IA',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RelatorioScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Trocar usuario',
            icon: const Icon(Icons.logout),
            onPressed: () => provider.sair(),
          ),
        ],
      ),

      // Botao de novo chamado aparece somente para o perfil de producao.
      floatingActionButton: ehProducao
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NovoChamadoScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Novo chamado'),
            )
          : null,

      body: Column(
        children: [
          _BarraDeFiltros(provider: provider),

          // Expanded faz a lista ocupar todo o espaco restante da tela.
          Expanded(
            // StreamBuilder escuta o fluxo do Firestore: cada vez que um
            // chamado e criado ou alterado por QUALQUER usuario, este widget
            // se reconstroi com a lista nova. E o coracao da comunicacao
            // em tempo real entre producao e manutencao.
            child: StreamBuilder<List<Chamado>>(
              stream: provider.observarChamados(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _Mensagem(
                    icone: Icons.cloud_off,
                    texto: 'Nao foi possivel carregar os chamados.\n'
                        'Verifique a conexao.',
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chamados = snapshot.data ?? [];

                if (chamados.isEmpty) {
                  return const _Mensagem(
                    icone: Icons.inbox_outlined,
                    texto: 'Nenhum chamado neste filtro.',
                  );
                }

                // ListView.builder constroi apenas os itens visiveis na tela,
                // o que mantem o app fluido mesmo com centenas de chamados.
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 90),
                  itemCount: chamados.length,
                  itemBuilder: (context, indice) {
                    final chamado = chamados[indice];
                    return ChamadoCard(
                      chamado: chamado,
                      aoTocar: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              DetalheChamadoScreen(chamado: chamado),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de "chips" para filtrar a lista por status.
class _BarraDeFiltros extends StatelessWidget {
  final AppProvider provider;
  const _BarraDeFiltros({required this.provider});

  @override
  Widget build(BuildContext context) {
    // Lista de opcoes: o valor `null` representa "Todos".
    final opcoes = <StatusChamado?>[null, ...StatusChamado.values];

    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: opcoes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, indice) {
          final opcao = opcoes[indice];
          return ChoiceChip(
            label: Text(opcao?.rotulo ?? 'Todos'),
            selected: provider.filtroStatus == opcao,
            onSelected: (_) => provider.definirFiltro(opcao),
          );
        },
      ),
    );
  }
}

/// Mensagem centralizada usada para estados vazios ou de erro.
class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Mensagem({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 56, color: Colors.black26),
          const SizedBox(height: 12),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
