// =============================================================================
// ARQUIVO: lib/tema.dart
// FINALIDADE: Centraliza cores e estilos do app em um unico lugar.
//             Assim a interface fica consistente em todas as telas e uma
//             mudanca de identidade visual e feita em um so arquivo.
// =============================================================================

import 'package:flutter/material.dart';
import 'models/chamado.dart';

class TemaApp {
  // Azul industrial como cor base da marca.
  static const Color corPrimaria = Color(0xFF12467B);
  static const Color corFundo = Color(0xFFF2F4F7);

  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: corPrimaria,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: corFundo,
      appBarTheme: const AppBarTheme(
        backgroundColor: corPrimaria,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  /// Cor associada a cada prioridade, usada nas etiquetas dos cards.
  /// Manter esse mapeamento aqui evita repetir `switch` de cores nas telas.
  static Color corDaPrioridade(Prioridade p) {
    switch (p) {
      case Prioridade.paradaDeLinha:
        return const Color(0xFFC62828); // vermelho
      case Prioridade.alta:
        return const Color(0xFFEF6C00); // laranja
      case Prioridade.media:
        return const Color(0xFF1565C0); // azul
      case Prioridade.baixa:
        return const Color(0xFF2E7D32); // verde
    }
  }

  /// Cor associada a cada status do chamado.
  static Color corDoStatus(StatusChamado s) {
    switch (s) {
      case StatusChamado.aberto:
        return const Color(0xFFC62828);
      case StatusChamado.emAndamento:
        return const Color(0xFFEF6C00);
      case StatusChamado.concluido:
        return const Color(0xFF2E7D32);
    }
  }

  /// Icone que representa cada especialidade da manutencao.
  static IconData iconeDaEspecialidade(Especialidade e) {
    switch (e) {
      case Especialidade.ferramentaria:
        return Icons.handyman;
      case Especialidade.eletrica:
        return Icons.bolt;
      case Especialidade.pneumatica:
        return Icons.air;
      case Especialidade.mecanica:
        return Icons.settings;
    }
  }
}
