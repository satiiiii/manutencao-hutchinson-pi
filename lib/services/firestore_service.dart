// =============================================================================
// ARQUIVO: lib/services/firestore_service.dart
// FINALIDADE: Concentra TODA a conversa com o banco de dados (Cloud Firestore).
//             Nenhuma tela fala com o Firestore diretamente; elas pedem para
//             este servico. Assim, se um dia trocarmos de banco, so este
//             arquivo precisa mudar.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chamado.dart';

class FirestoreService {
  // Referencia para a colecao "chamados" no banco. Pense nela como a
  // "tabela" onde cada documento e um chamado.
  final CollectionReference<Map<String, dynamic>> _colecao =
      FirebaseFirestore.instance.collection('chamados');

  /// Retorna um "fluxo" (Stream) com todos os chamados.
  ///
  /// Diferente de uma consulta comum, o Stream continua aberto: sempre que
  /// alguem na fabrica abrir, assumir ou concluir um chamado, o Firestore
  /// empurra a lista atualizada e a tela se redesenha sozinha. E isso que
  /// da o efeito de "tempo real" entre o lider de producao e o manutentor.
  Stream<List<Chamado>> observarChamados() {
    return _colecao
        .orderBy('criadoEm', descending: true) // mais recentes primeiro
        .snapshots()
        .map((consulta) =>
            consulta.docs.map((doc) => Chamado.doDocumento(doc)).toList());
  }

  /// Grava um novo chamado e devolve o id gerado pelo Firestore.
  Future<String> criarChamado(Chamado chamado) async {
    final doc = await _colecao.add(chamado.paraMap());
    return doc.id;
  }

  /// Marca o chamado como "em andamento" e registra quem assumiu.
  ///
  /// Gravamos apenas os tres campos que mudaram (`update`), e nao o documento
  /// inteiro. Isso evita sobrescrever alteracoes feitas por outro usuario
  /// no mesmo instante.
  Future<void> assumirChamado(String id, String responsavel) {
    return _colecao.doc(id).update({
      'status': StatusChamado.emAndamento.name,
      'responsavel': responsavel,
      'iniciadoEm': Timestamp.now(),
    });
  }

  /// Finaliza o chamado registrando o que foi feito.
  Future<void> concluirChamado(String id, String solucao) {
    return _colecao.doc(id).update({
      'status': StatusChamado.concluido.name,
      'solucao': solucao,
      'concluidoEm': Timestamp.now(),
    });
  }

  /// Busca uma unica vez os chamados criados dentro de um intervalo de datas.
  /// Usado pela tela de relatorio, que nao precisa de atualizacao em tempo
  /// real - so de uma "foto" do periodo escolhido.
  Future<List<Chamado>> buscarChamadosDoPeriodo(
    DateTime inicio,
    DateTime fim,
  ) async {
    final consulta = await _colecao
        .where('criadoEm', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('criadoEm', isLessThanOrEqualTo: Timestamp.fromDate(fim))
        .get();

    return consulta.docs.map((doc) => Chamado.doDocumento(doc)).toList();
  }
}
