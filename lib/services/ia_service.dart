// =============================================================================
// ARQUIVO: lib/services/ia_service.dart
// FINALIDADE: Integracao com o servico de Inteligencia Artificial.
//             Usamos a API do Google Gemini (modelo de linguagem pre-treinado)
//             para duas funcoes:
//               1) TRIAGEM: le a descricao escrita pelo lider de producao e
//                  sugere especialidade, prioridade, titulo e causa provavel.
//               2) RELATORIO: le os chamados de um periodo e escreve uma
//                  analise gerencial em texto corrido.
//
// FLUXO DA INTEGRACAO (exigido pelo enunciado do PI):
//   Tela (input do usuario) -> IaService monta o prompt -> HTTP POST para a
//   API do Gemini -> resposta JSON -> tratamento/parse aqui -> objeto Dart ->
//   exibicao na tela.
// =============================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chamado.dart';

/// Resultado estruturado devolvido pela triagem automatica.
/// A IA responde em texto; aqui ele ja chega convertido em objeto Dart.
class SugestaoTriagem {
  final String titulo;
  final Especialidade especialidade;
  final Prioridade prioridade;
  final String causaProvavel;

  SugestaoTriagem({
    required this.titulo,
    required this.especialidade,
    required this.prioridade,
    required this.causaProvavel,
  });
}

/// Erro especifico da camada de IA, para a tela conseguir mostrar uma
/// mensagem clara em vez de um erro tecnico cru.
class IaException implements Exception {
  final String mensagem;
  IaException(this.mensagem);
  @override
  String toString() => mensagem;
}

class IaService {
  // ---------------------------------------------------------------------------
  // CONFIGURACAO
  // A chave e lida de uma variavel de ambiente de compilacao, para nao ficar
  // gravada dentro do codigo-fonte publicado no GitHub. Para rodar:
  //   flutter run --dart-define=GEMINI_API_KEY=sua_chave_aqui
  // ---------------------------------------------------------------------------
  static const String _chaveApi = String.fromEnvironment('GEMINI_API_KEY');

  // Modelo utilizado. Se o Google alterar a nomenclatura, basta trocar aqui.
  static const String _modelo = 'gemini-2.0-flash';

  static const String _urlBase =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Metodo interno unico que conversa com a API.
  ///
  /// Recebe o prompt pronto e devolve o texto gerado pela IA.
  /// Concentrar a chamada HTTP em um so lugar evita repeticao de codigo
  /// e facilita o tratamento de erros.
  Future<String> _gerarConteudo(String prompt) async {
    if (_chaveApi.isEmpty) {
      throw IaException(
        'Chave da API nao configurada. Rode o app com '
        '--dart-define=GEMINI_API_KEY=sua_chave.',
      );
    }

    final url = Uri.parse('$_urlBase/$_modelo:generateContent?key=$_chaveApi');

    // Corpo da requisicao no formato esperado pela API do Gemini.
    final corpo = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        // Temperatura baixa = respostas mais previsiveis e tecnicas,
        // que e o que queremos em um contexto industrial.
        'temperature': 0.2,
        'maxOutputTokens': 1024,
      }
    });

    late final http.Response resposta;
    try {
      // `await` = comunicacao assincrona: a interface nao trava enquanto
      // espera a resposta da internet.
      resposta = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: corpo,
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw IaException('Falha de conexao com o servico de IA: $e');
    }

    if (resposta.statusCode != 200) {
      throw IaException(
        'O servico de IA retornou erro ${resposta.statusCode}.',
      );
    }

    // A resposta vem aninhada: candidates -> content -> parts -> text
    final Map<String, dynamic> json = jsonDecode(resposta.body);
    final candidatos = json['candidates'] as List?;
    if (candidatos == null || candidatos.isEmpty) {
      throw IaException('A IA nao retornou nenhuma resposta.');
    }

    final partes = candidatos.first['content']?['parts'] as List?;
    final texto = partes?.first?['text'] as String?;

    if (texto == null || texto.trim().isEmpty) {
      throw IaException('A IA retornou uma resposta vazia.');
    }
    return texto.trim();
  }

  // ===========================================================================
  // FUNCAO 1 - TRIAGEM INTELIGENTE DO CHAMADO
  // ===========================================================================

  /// Analisa a descricao livre do problema e sugere como o chamado deve ser
  /// classificado. O lider de producao pode aceitar ou corrigir a sugestao -
  /// a IA apoia a decisao, nao a substitui.
  Future<SugestaoTriagem> triarChamado({
    required String descricao,
    required String maquina,
    required String setor,
  }) async {
    // Pedimos explicitamente JSON puro, sem texto em volta, para conseguirmos
    // converter a resposta em objeto de forma confiavel.
    final prompt = '''
Voce e um tecnico experiente em manutencao industrial de uma fabrica de
componentes automotivos. Analise o relato abaixo, feito por um lider de
producao, e classifique o chamado.

Setor: $setor
Maquina/Equipamento: $maquina
Relato: "$descricao"

Responda APENAS com um objeto JSON valido, sem markdown, sem crases e sem
nenhum texto antes ou depois, exatamente neste formato:
{
  "titulo": "resumo do problema em ate 8 palavras",
  "especialidade": "ferramentaria | eletrica | pneumatica | mecanica",
  "prioridade": "paradaDeLinha | alta | media | baixa",
  "causaProvavel": "hipotese tecnica em ate 2 frases"
}

Criterios de prioridade:
- paradaDeLinha: a maquina esta parada e a producao interrompida.
- alta: risco iminente de parada ou risco de seguranca.
- media: afeta qualidade, desempenho ou setup, mas a linha segue rodando.
- baixa: melhoria, ajuste ou manutencao preventiva.
''';

    final textoBruto = await _gerarConteudo(prompt);

    // Mesmo pedindo JSON puro, modelos as vezes devolvem dentro de ```json.
    // Por seguranca, recortamos do primeiro "{" ate o ultimo "}".
    final inicio = textoBruto.indexOf('{');
    final fim = textoBruto.lastIndexOf('}');
    if (inicio == -1 || fim == -1) {
      throw IaException('Nao foi possivel interpretar a resposta da IA.');
    }

    try {
      final Map<String, dynamic> dados =
          jsonDecode(textoBruto.substring(inicio, fim + 1));

      return SugestaoTriagem(
        titulo: (dados['titulo'] as String?)?.trim() ?? 'Chamado de manutencao',
        especialidade:
            Especialidade.dePlanoTexto(dados['especialidade'] as String?),
        prioridade: Prioridade.dePlanoTexto(dados['prioridade'] as String?),
        causaProvavel: (dados['causaProvavel'] as String?)?.trim() ?? '',
      );
    } catch (_) {
      throw IaException('A IA respondeu em um formato inesperado.');
    }
  }

  // ===========================================================================
  // FUNCAO 2 - RELATORIO GERENCIAL AUTOMATICO
  // ===========================================================================

  /// Recebe os chamados do periodo e pede a IA um relatorio analitico.
  ///
  /// Observacao importante: os NUMEROS (totais, MTTR) sao calculados pelo
  /// proprio app, nao pela IA. Enviamos os dados ja consolidados e pedimos a
  /// IA apenas a interpretacao e as recomendacoes. Isso evita que o modelo
  /// invente estatisticas.
  Future<String> gerarRelatorio({
    required List<Chamado> chamados,
    required DateTime inicio,
    required DateTime fim,
  }) async {
    if (chamados.isEmpty) {
      throw IaException('Nao ha chamados registrados no periodo selecionado.');
    }

    // --- Consolidacao dos dados feita localmente, em Dart ---
    final total = chamados.length;
    final concluidos =
        chamados.where((c) => c.status == StatusChamado.concluido).toList();

    // Contagem por especialidade.
    final porEspecialidade = <String, int>{};
    for (final c in chamados) {
      porEspecialidade.update(
        c.especialidade.rotulo,
        (v) => v + 1,
        ifAbsent: () => 1,
      );
    }

    // Contagem por maquina, para identificar equipamentos reincidentes.
    final porMaquina = <String, int>{};
    for (final c in chamados) {
      porMaquina.update(c.maquina, (v) => v + 1, ifAbsent: () => 1);
    }

    // MTTR - tempo medio de reparo, em minutos, dos chamados concluidos.
    String mttr = 'sem dados';
    if (concluidos.isNotEmpty) {
      final somaMinutos = concluidos
          .map((c) => c.tempoDeAtendimento!.inMinutes)
          .reduce((a, b) => a + b);
      mttr = '${(somaMinutos / concluidos.length).round()} minutos';
    }

    // Lista resumida dos chamados, para a IA identificar padroes nos relatos.
    final listaResumida = chamados
        .map((c) => '- [${c.maquina} | ${c.especialidade.rotulo} | '
            '${c.prioridade.rotulo} | ${c.status.rotulo}] ${c.titulo}: '
            '${c.descricao}${c.solucao != null ? " >> Solucao: ${c.solucao}" : ""}')
        .join('\n');

    final prompt = '''
Voce e um analista de manutencao industrial. Escreva um relatorio gerencial
em portugues do Brasil sobre o periodo de
${inicio.day}/${inicio.month}/${inicio.year} a ${fim.day}/${fim.month}/${fim.year}.

DADOS JA CONSOLIDADOS (use exatamente estes numeros, nao invente outros):
- Total de chamados: $total
- Chamados concluidos: ${concluidos.length}
- Tempo medio de atendimento (MTTR): $mttr
- Chamados por especialidade: ${porEspecialidade.entries.map((e) => "${e.key}: ${e.value}").join(", ")}
- Chamados por equipamento: ${porMaquina.entries.map((e) => "${e.key}: ${e.value}").join(", ")}

RELATOS DO PERIODO:
$listaResumida

Estruture a resposta em texto corrido com estes titulos, sem usar tabelas:
1. Resumo do periodo
2. Principais ocorrencias e equipamentos criticos
3. Padroes e causas recorrentes identificadas
4. Recomendacoes de manutencao preventiva

Seja objetivo e tecnico. Maximo de 400 palavras.
''';

    return _gerarConteudo(prompt);
  }
}
