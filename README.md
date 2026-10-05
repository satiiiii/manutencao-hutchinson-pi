# App de Chamados de Manutenção — Hutchinson~

RA:26002043

Projeto Integrado — UNIFEOB / Análise e Desenvolvimento de Sistemas
Módulo: Desenvolvimento Mobile — 3º trimestre letivo de 2026

Aplicativo mobile em **Flutter** que digitaliza a comunicação entre líderes de produção e as equipes de manutenção (ferramentaria, elétrica, pneumática e mecânica), substituindo o processo atual feito em papel. Integra o modelo de linguagem **Google Gemini** para triagem automática dos chamados e geração de relatórios gerenciais.

**ODS relacionado:** ODS 9 — Indústria, Inovação e Infraestrutura.

---

## Funcionalidades

| Perfil | O que faz |
|---|---|
| Líder de produção | Abre chamados descrevendo o problema em texto livre |
| Manutentor | Visualiza a fila priorizada, assume e conclui chamados |
| Ambos | Consultam o histórico e geram relatórios do período |

**Integração com IA (dois pontos):**

1. **Triagem inteligente** — a descrição em linguagem natural é enviada ao Gemini, que retorna título, especialidade, prioridade e causa provável já preenchidos no formulário. O usuário revisa antes de enviar.
2. **Relatório gerencial** — o app consolida os indicadores localmente (total, MTTR, distribuição por especialidade e por equipamento) e o Gemini produz a análise de padrões e as recomendações de manutenção preventiva.

---

## Arquitetura

```
lib/
├── main.dart                 Inicialização, Provider e roteamento inicial
├── tema.dart                 Cores, estilos e ícones centralizados
├── models/
│   └── chamado.dart          Modelo de dados + enums + serialização
├── services/
│   ├── firestore_service.dart  Toda a comunicação com o banco
│   └── ia_service.dart         Toda a comunicação com a API de IA
├── providers/
│   └── app_provider.dart     Estado global (ChangeNotifier)
├── screens/
│   ├── identificacao_screen.dart
│   ├── home_screen.dart
│   ├── novo_chamado_screen.dart
│   ├── detalhe_chamado_screen.dart
│   └── relatorio_screen.dart
└── widgets/
    └── chamado_card.dart     Componente reutilizável da lista
```

Camadas separadas: as telas nunca falam com o Firestore ou com a API de IA diretamente — sempre passam pelo `AppProvider`, que chama os serviços.

---

## Como rodar

### 1. Pré-requisitos
- Flutter 3.19 ou superior
- Uma conta Google (Firebase + Google AI Studio)

### 2. Dependências
```bash
flutter pub get
```

### 3. Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
O comando gera o arquivo `lib/firebase_options.dart`. Crie um banco **Cloud Firestore** em modo de teste no console do Firebase.

### 4. Chave da API de IA
Gere uma chave em https://aistudio.google.com/apikey e rode o app passando-a como variável de compilação (assim ela **não** vai para o repositório):

```bash
flutter run --dart-define=GEMINI_API_KEY=sua_chave_aqui
```

### 5. Build de release
```bash
flutter build apk --release --dart-define=GEMINI_API_KEY=sua_chave_aqui
```

---

## Observações técnicas

- A comunicação em tempo real usa `snapshots()` do Firestore: quando um chamado muda de status, todos os aparelhos conectados atualizam a lista automaticamente.
- Os números dos relatórios são calculados em Dart, não pela IA — o modelo recebe os totais prontos e só interpreta. Isso evita estatísticas inventadas.
- A IA é um apoio e não uma dependência: se a API falhar, o chamado continua podendo ser aberto e classificado manualmente.
- As regras do Firestore devem ser restringidas antes de qualquer uso real em produção; o modo de teste é adequado apenas para a demonstração acadêmica.
