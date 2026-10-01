// =============================================================================
// ARQUIVO: lib/providers/app_provider.dart
// FINALIDADE: Gerenciamento de estado da aplicacao usando o pacote `provider`
//             (padrao ChangeNotifier). Guarda quem esta usando o app e faz a
//             ponte entre as telas e os servicos (Firestore e IA).
//
// Por que usar Provider: sem ele, cada tela precisaria receber os dados por
// parametro, tela por tela. Com ele, qualquer widget da arvore acessa o estado
// com `context.watch<AppProvider>()` e se redesenha sozinho quando algo muda.
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chamado.dart';
import '../services/firestore_service.dart';
import '../services/ia_service.dart';

/// Perfil de acesso do usuario. Define o que ele pode fazer no app.
enum PerfilUsuario {
  producao, // lider de producao: abre chamados
  manutencao; // manutentor: assume e conclui chamados

  String get rotulo =>
      this == PerfilUsuario.producao ? 'Lider de producao' : 'Manutentor';
}

class AppProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final IaService _ia = IaService();

  // --- Estado do usuario logado ---
  String? _nomeUsuario;
  PerfilUsuario? _perfil;

  String? get nomeUsuario => _nomeUsuario;
  PerfilUsuario? get perfil => _perfil;
  bool get estaIdentificado => _nomeUsuario != null && _perfil != null;

  // --- Estado de filtro da lista ---
  StatusChamado? _filtroStatus;
  StatusChamado? get filtroStatus => _filtroStatus;

  /// Carrega o usuario salvo no aparelho. Assim ele nao precisa se
  /// identificar toda vez que abrir o app.
  Future<void> carregarUsuarioSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString('nomeUsuario');
    final perfilTexto = prefs.getString('perfilUsuario');

    if (nome != null && perfilTexto != null) {
      _nomeUsuario = nome;
      _perfil = PerfilUsuario.values.firstWhere(
        (p) => p.name == perfilTexto,
        orElse: () => PerfilUsuario.producao,
      );
      notifyListeners(); // avisa as telas para se redesenharem
    }
  }

  /// Salva a identificacao do usuario no aparelho e atualiza o estado.
  Future<void> identificar(String nome, PerfilUsuario perfil) async {
    _nomeUsuario = nome.trim();
    _perfil = perfil;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nomeUsuario', _nomeUsuario!);
    await prefs.setString('perfilUsuario', perfil.name);

    notifyListeners();
  }

  /// Remove a identificacao (usado no botao "trocar usuario").
  Future<void> sair() async {
    _nomeUsuario = null;
    _perfil = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  void definirFiltro(StatusChamado? status) {
    _filtroStatus = status;
    notifyListeners();
  }

  // ===========================================================================
  // OPERACOES COM CHAMADOS
  // ===========================================================================

  /// Fluxo de chamados ja com o filtro de status aplicado e ordenado
  /// por prioridade (parada de linha primeiro).
  Stream<List<Chamado>> observarChamados() {
    return _firestore.observarChamados().map((lista) {
      final filtrada = _filtroStatus == null
          ? lista
          : lista.where((c) => c.status == _filtroStatus).toList();

      // Ordena por prioridade; em caso de empate, o mais antigo vem primeiro,
      // porque ja esta esperando ha mais tempo.
      filtrada.sort((a, b) {
        final porPrioridade =
            a.prioridade.index.compareTo(b.prioridade.index);
        if (porPrioridade != 0) return porPrioridade;
        return a.criadoEm.compareTo(b.criadoEm);
      });

      return filtrada;
    });
  }

  Future<void> criarChamado(Chamado chamado) =>
      _firestore.criarChamado(chamado);

  Future<void> assumirChamado(String id) =>
      _firestore.assumirChamado(id, _nomeUsuario ?? 'Nao identificado');

  Future<void> concluirChamado(String id, String solucao) =>
      _firestore.concluirChamado(id, solucao);

  // ===========================================================================
  // OPERACOES DE IA
  // ===========================================================================

  /// Pede a triagem automatica do chamado ao servico de IA.
  Future<SugestaoTriagem> triar({
    required String descricao,
    required String maquina,
    required String setor,
  }) {
    return _ia.triarChamado(
      descricao: descricao,
      maquina: maquina,
      setor: setor,
    );
  }

  /// Busca os chamados do periodo e pede o relatorio analitico a IA.
  Future<String> gerarRelatorio(DateTime inicio, DateTime fim) async {
    final chamados = await _firestore.buscarChamadosDoPeriodo(inicio, fim);
    return _ia.gerarRelatorio(chamados: chamados, inicio: inicio, fim: fim);
  }
}
