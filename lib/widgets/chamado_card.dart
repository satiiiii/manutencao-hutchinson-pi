// =============================================================================
// ARQUIVO: lib/widgets/chamado_card.dart
// FINALIDADE: Componente reutilizavel que desenha um chamado na lista.
//             Separar o card em seu proprio arquivo mantem a tela de lista
//             enxuta e permite reaproveitar o componente em outras telas.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chamado.dart';
import '../tema.dart';

class ChamadoCard extends StatelessWidget {
  final Chamado chamado;
  final VoidCallback aoTocar;

  const ChamadoCard({
    super.key,
    required this.chamado,
    required this.aoTocar,
  });

  @override
  Widget build(BuildContext context) {
    final formatador = DateFormat("dd/MM 'as' HH:mm", 'pt_BR');

    return Card(
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- Linha superior: etiquetas de prioridade e status ---
              Row(
                children: [
                  _Etiqueta(
                    texto: chamado.prioridade.rotulo,
                    cor: TemaApp.corDaPrioridade(chamado.prioridade),
                  ),
                  const SizedBox(width: 6),
                  _Etiqueta(
                    texto: chamado.status.rotulo,
                    cor: TemaApp.corDoStatus(chamado.status),
                  ),
                  const Spacer(),
                  Icon(
                    TemaApp.iconeDaEspecialidade(chamado.especialidade),
                    size: 18,
                    color: Colors.black45,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ---------- Titulo do chamado ----------
              Text(
                chamado.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              // ---------- Localizacao do equipamento ----------
              Row(
                children: [
                  const Icon(Icons.place_outlined,
                      size: 15, color: Colors.black45),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${chamado.setor} - ${chamado.maquina}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ---------- Rodape: autor e horario ----------
              Text(
                'Aberto por ${chamado.solicitante} - '
                '${formatador.format(chamado.criadoEm)}',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),

              // Mostra o responsavel apenas se alguem ja assumiu.
              if (chamado.responsavel != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Responsavel: ${chamado.responsavel}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pequena etiqueta colorida usada para prioridade e status.
class _Etiqueta extends StatelessWidget {
  final String texto;
  final Color cor;

  const _Etiqueta({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withOpacity(0.4)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cor,
        ),
      ),
    );
  }
}
