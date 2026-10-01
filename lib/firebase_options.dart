// =============================================================================
// ARQUIVO: lib/firebase_options.dart
// ATENCAO: ESTE E UM ARQUIVO DE EXEMPLO (PLACEHOLDER).
//
// Ele existe apenas para o projeto abrir sem erro de "arquivo nao encontrado"
// antes da configuracao. Os valores abaixo sao FICTICIOS e NAO conectam a
// nenhum banco de dados real.
//
// PASSO OBRIGATORIO ANTES DE RODAR O APP DE VERDADE:
//   1. No terminal, dentro da pasta do projeto, rode:
//        flutterfire configure
//   2. Escolha (ou crie) o seu projeto Firebase e a plataforma Android.
//   3. O comando vai SOBRESCREVER este arquivo com as credenciais reais
//      do seu projeto Firebase. Isso e esperado e correto.
//
// Sem esse passo, o app abre mas trava ao tentar falar com o Firestore.
// =============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions nao foi configurado para Web. '
        'Rode "flutterfire configure" para gerar as opcoes reais.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions nao foi configurado para esta plataforma. '
          'Rode "flutterfire configure" para gerar as opcoes reais.',
        );
    }
  }

  // ---------------------------------------------------------------------
  // VALORES FICTICIOS - serao substituidos pelo "flutterfire configure"
  // ---------------------------------------------------------------------
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'SUBSTITUA_RODANDO_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'substitua-rodando-flutterfire-configure',
    storageBucket: 'substitua-rodando-flutterfire-configure.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'SUBSTITUA_RODANDO_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'substitua-rodando-flutterfire-configure',
    storageBucket: 'substitua-rodando-flutterfire-configure.appspot.com',
    iosBundleId: 'com.example.manutencaoApp',
  );
}
