// =============================================================================
// ARQUIVO: lib/main.dart
// FINALIDADE: Ponto de entrada do aplicativo. Inicializa o Firebase, registra
//             o gerenciador de estado (Provider) e decide qual a primeira tela.
//
// PROJETO INTEGRADO - UNIFEOB / ADS - Modulo Desenvolvimento Mobile - 2026
// App de chamados de manutencao com apoio de Inteligencia Artificial.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'screens/identificacao_screen.dart';
import 'screens/home_screen.dart';
import 'tema.dart';

Future<void> main() async {
  // Garante que o motor do Flutter esta pronto antes de chamar codigo nativo
  // (Firebase). Sem esta linha o app quebra na inicializacao.
  WidgetsFlutterBinding.ensureInitialized();

  // Conecta o app ao projeto Firebase. O arquivo firebase_options.dart e
  // gerado automaticamente pelo comando `flutterfire configure`.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Carrega os dados de formatacao de data em portugues do Brasil.
  await initializeDateFormatting('pt_BR');

  runApp(const AplicativoManutencao());
}

class AplicativoManutencao extends StatelessWidget {
  const AplicativoManutencao({super.key});

  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider disponibiliza o AppProvider para toda a arvore
    // de widgets abaixo dele - ou seja, para o app inteiro.
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..carregarUsuarioSalvo(),
      child: MaterialApp(
        title: 'Manutencao Hutchinson',
        debugShowCheckedModeBanner: false,
        theme: TemaApp.tema,
        home: const RoteadorInicial(),
      ),
    );
  }
}

/// Decide a primeira tela conforme o usuario ja esta identificado ou nao.
///
/// `context.watch` faz este widget se reconstruir sempre que o AppProvider
/// mudar - entao, assim que o usuario se identifica, a navegacao acontece
/// automaticamente, sem `Navigator.push` manual.
class RoteadorInicial extends StatelessWidget {
  const RoteadorInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return provider.estaIdentificado
        ? const HomeScreen()
        : const IdentificacaoScreen();
  }
}
