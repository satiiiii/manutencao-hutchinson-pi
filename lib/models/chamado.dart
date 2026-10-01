// =============================================================================
// ARQUIVO: lib/models/chamado.dart
// FINALIDADE: Define a estrutura de dados de um chamado de manutencao.
//             Este e o "contrato" que o app inteiro usa para falar de um
//             chamado: telas, provider e banco de dados usam esta mesma classe.
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Especialidade da equipe de manutencao responsavel pelo atendimento.
/// Usamos um `enum` em vez de texto solto para evitar erros de digitacao
/// (ex.: "eletrica" vs "Eletrica") e para o compilador nos avisar se
/// esquecermos de tratar algum caso.
enum Especialidade {
  ferramentaria,
  eletrica,
  pneumatica,
  mecanica;

  /// Texto amigavel que aparece na interface para o usuario.
  String get rotulo {
    switch (this) {
      case Especialidade.ferramentaria:
        return 'Ferramentaria';
      case Especialidade.eletrica:
        return 'Eletrica';
      case Especialidade.pneumatica:
        return 'Pneumatica';
      case Especialidade.mecanica:
        return 'Mecanica';
    }
  }

  /// Converte um texto vindo do banco (ou da IA) de volta para o enum.
  /// Se o texto nao for reconhecido, assume "mecanica" como padrao seguro,
  /// garantindo que o app nunca quebre por causa de um dado inesperado.
  static Especialidade dePlanoTexto(String? valor) {
    return Especialidade.values.firstWhere(
      (e) => e.name == valor?.toLowerCase().trim(),
      orElse: () => Especialidade.mecanica,
    );
  }
}

/// Nivel de urgencia do chamado. A ordem da declaracao importa: usamos o
/// `index` de cada item para ordenar a lista (mais critico primeiro).
enum Prioridade {
  paradaDeLinha, // index 0 - maquina parada, producao interrompida
  alta, // index 1 - risco de parar em breve
  media, // index 2 - afeta qualidade ou desempenho
  baixa; // index 3 - melhoria / preventiva

  String get rotulo {
    switch (this) {
      case Prioridade.paradaDeLinha:
        return 'Parada de linha';
      case Prioridade.alta:
        return 'Alta';
      case Prioridade.media:
        return 'Media';
      case Prioridade.baixa:
        return 'Baixa';
    }
  }

  static Prioridade dePlanoTexto(String? valor) {
    final limpo = valor?.toLowerCase().trim().replaceAll(' ', '');
    switch (limpo) {
      case 'paradadelinha':
      case 'paradalinha':
      case 'critica':
        return Prioridade.paradaDeLinha;
      case 'alta':
        return Prioridade.alta;
      case 'baixa':
        return Prioridade.baixa;
      default:
        return Prioridade.media;
    }
  }
}

/// Ciclo de vida do chamado dentro do app.
enum StatusChamado {
  aberto, // criado pelo lider de producao, aguardando manutencao
  emAndamento, // um manutentor assumiu e esta trabalhando
  concluido; // servico finalizado e descrito

  String get rotulo {
    switch (this) {
      case StatusChamado.aberto:
        return 'Aberto';
      case StatusChamado.emAndamento:
        return 'Em andamento';
      case StatusChamado.concluido:
        return 'Concluido';
    }
  }

  static StatusChamado dePlanoTexto(String? valor) {
    return StatusChamado.values.firstWhere(
      (e) => e.name == valor,
      orElse: () => StatusChamado.aberto,
    );
  }
}

/// Representa um chamado de manutencao aberto pela producao.
///
/// A classe e imutavel (todos os campos sao `final`): quando precisamos
/// alterar algo, criamos uma copia com `copyWith`. Isso evita bugs de estado
/// compartilhado, um problema comum em apps com varias telas.
class Chamado {
  /// Identificador do documento no Firestore. Fica nulo enquanto o chamado
  /// ainda nao foi gravado no banco.
  final String? id;

  final String titulo;
  final String descricao;
  final String setor; // ex.: "Linha 3 - Extrusao"
  final String maquina; // ex.: "Prensa 07"
  final Especialidade especialidade;
  final Prioridade prioridade;
  final StatusChamado status;

  /// Nome de quem abriu o chamado (lider de producao).
  final String solicitante;

  /// Nome do manutentor que assumiu o chamado (nulo enquanto ninguem assumiu).
  final String? responsavel;

  /// Descricao do servico executado, preenchida na conclusao.
  final String? solucao;

  /// Hipotese de causa provavel sugerida pela IA na abertura do chamado.
  /// E apenas um apoio: quem decide continua sendo o manutentor.
  final String? causaProvavelIA;

  final DateTime criadoEm;
  final DateTime? iniciadoEm;
  final DateTime? concluidoEm;

  const Chamado({
    this.id,
    required this.titulo,
    required this.descricao,
    required this.setor,
    required this.maquina,
    required this.especialidade,
    required this.prioridade,
    required this.status,
    required this.solicitante,
    required this.criadoEm,
    this.responsavel,
    this.solucao,
    this.causaProvavelIA,
    this.iniciadoEm,
    this.concluidoEm,
  });

  /// Tempo entre a abertura e a conclusao do chamado.
  /// Usado para calcular o MTTR (tempo medio de reparo) nos indicadores.
  Duration? get tempoDeAtendimento {
    if (concluidoEm == null) return null;
    return concluidoEm!.difference(criadoEm);
  }

  /// Cria uma copia do chamado alterando somente os campos informados.
  Chamado copyWith({
    String? id,
    String? titulo,
    String? descricao,
    String? setor,
    String? maquina,
    Especialidade? especialidade,
    Prioridade? prioridade,
    StatusChamado? status,
    String? solicitante,
    String? responsavel,
    String? solucao,
    String? causaProvavelIA,
    DateTime? criadoEm,
    DateTime? iniciadoEm,
    DateTime? concluidoEm,
  }) {
    return Chamado(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      setor: setor ?? this.setor,
      maquina: maquina ?? this.maquina,
      especialidade: especialidade ?? this.especialidade,
      prioridade: prioridade ?? this.prioridade,
      status: status ?? this.status,
      solicitante: solicitante ?? this.solicitante,
      responsavel: responsavel ?? this.responsavel,
      solucao: solucao ?? this.solucao,
      causaProvavelIA: causaProvavelIA ?? this.causaProvavelIA,
      criadoEm: criadoEm ?? this.criadoEm,
      iniciadoEm: iniciadoEm ?? this.iniciadoEm,
      concluidoEm: concluidoEm ?? this.concluidoEm,
    );
  }

  /// Converte o objeto Dart em um Map para gravar no Firestore.
  /// Enums viram texto (`.name`) e datas viram `Timestamp`, que sao os
  /// formatos que o Firestore entende.
  Map<String, dynamic> paraMap() {
    return {
      'titulo': titulo,
      'descricao': descricao,
      'setor': setor,
      'maquina': maquina,
      'especialidade': especialidade.name,
      'prioridade': prioridade.name,
      'status': status.name,
      'solicitante': solicitante,
      'responsavel': responsavel,
      'solucao': solucao,
      'causaProvavelIA': causaProvavelIA,
      'criadoEm': Timestamp.fromDate(criadoEm),
      'iniciadoEm': iniciadoEm == null ? null : Timestamp.fromDate(iniciadoEm!),
      'concluidoEm':
          concluidoEm == null ? null : Timestamp.fromDate(concluidoEm!),
    };
  }

  /// Caminho inverso: transforma um documento do Firestore em um objeto Dart.
  factory Chamado.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final dados = doc.data() ?? <String, dynamic>{};

    // Funcao auxiliar local para converter Timestamp em DateTime com seguranca.
    DateTime? paraData(dynamic valor) =>
        valor is Timestamp ? valor.toDate() : null;

    return Chamado(
      id: doc.id,
      titulo: dados['titulo'] as String? ?? 'Sem titulo',
      descricao: dados['descricao'] as String? ?? '',
      setor: dados['setor'] as String? ?? '',
      maquina: dados['maquina'] as String? ?? '',
      especialidade:
          Especialidade.dePlanoTexto(dados['especialidade'] as String?),
      prioridade: Prioridade.dePlanoTexto(dados['prioridade'] as String?),
      status: StatusChamado.dePlanoTexto(dados['status'] as String?),
      solicitante: dados['solicitante'] as String? ?? '',
      responsavel: dados['responsavel'] as String?,
      solucao: dados['solucao'] as String?,
      causaProvavelIA: dados['causaProvavelIA'] as String?,
      criadoEm: paraData(dados['criadoEm']) ?? DateTime.now(),
      iniciadoEm: paraData(dados['iniciadoEm']),
      concluidoEm: paraData(dados['concluidoEm']),
    );
  }
}
