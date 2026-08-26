# Mobile App - Tutor

Aplicativo Flutter do tutor para gerenciar o prontuário de saúde do pet.

## Stack

- Flutter / Dart
- Material 3
- `http` para comunicação com a API e upload direto ao storage
- `flutter_secure_storage` para tokens, cache offline e fila local protegida
- `crypto` para SHA-256 local
- `file_picker` para seleção de exames e documentos
- `mime` para detecção de tipo de arquivo
- `qr_flutter` para QR temporário gerado localmente
- `url_launcher` para abertura de downloads pré-assinados
- `uuid` para identidade do dispositivo e eventos idempotentes de sincronização
- `intl` para datas

## Já implementado

- login com TOTP ou código de recuperação
- cadastro de tutor
- restauração de sessão local
- logout com revogação do refresh token
- lista de pets do tutor
- cadastro, edição e exclusão de pet com confirmação
- perfil completo do pet
- central de segurança da conta
- solicitação de verificação de e-mail
- carteira de vacinação
- prescrições em modo leitura para o tutor
- alergias ativas e inativas
- cadastro de alergia pelo tutor
- desativação não destrutiva de alergias
- histórico clínico com diagnóstico, tratamento e observações
- visualização do histórico de versões do prontuário quando houver emendas
- QR temporário com nível READ/WRITE, expiração, limite de usos e revogação
- seleção de exames/documentos no aparelho
- cálculo de SHA-256 no próprio dispositivo antes do upload
- upload direto para S3 compatível por URL pré-assinada
- registro do anexo somente após validação de integridade no backend
- vínculo opcional de documento a um atendimento clínico
- listagem de exames e documentos por pet
- download/visualização por URL temporária autorizada pelo backend
- cache local protegido da lista de pets
- edição de pet em modo offline com fila idempotente
- identidade persistente do dispositivo para sincronização
- envio automático da fila ao recuperar conectividade
- detecção de conflitos de versão pelo backend
- resolução visual de conflitos sem sobrescrita silenciosa
- escolha entre manter a versão do servidor ou reaplicar a alteração local sobre a versão mais recente
- carregamento independente de cada seção clínica para reduzir impacto de falhas parciais
- tratamento de erros da API
- tema Material 3
- testes de modelos clínicos e de anexos

## Fluxo seguro de documentos

1. O tutor seleciona um arquivo de até 50 MB.
2. O app calcula o SHA-256 antes de transmitir o arquivo.
3. A API fornece uma URL de upload pré-assinada de curta duração.
4. O app envia os bytes diretamente ao storage, junto com `Content-Type` e `x-amz-meta-sha256`.
5. O app solicita o registro do anexo.
6. O backend executa `HEAD` no objeto e confere SHA-256, tamanho e MIME type antes de aceitar o registro.
7. Para abrir um documento, a API valida a autorização do tutor e retorna uma URL de download temporária.

O arquivo pode ficar no prontuário geral do pet ou ser vinculado a um `MedicalRecord` existente. As URLs pré-assinadas não são persistidas no aplicativo.

## Offline-first e conflitos

A lista de pets e a fila de alterações ficam no armazenamento seguro do sistema. Cada evento recebe um `clientEventId` UUID e um `deviceId` persistente. Quando uma edição de pet não consegue alcançar a API, o app atualiza o cache local e guarda um evento `UPDATE` para envio posterior.

Ao recuperar conexão, a fila é enviada para `/sync/push`. O backend compara a versão local com a versão corrente e pode responder com conflitos como `STALE_VERSION`, `VERSION_GAP`, `CONCURRENT_VERSION` ou `OPTIMISTIC_LOCK_FAILED`.

Quando isso acontece, a alteração local permanece pendente. A interface carrega a versão atual do servidor e apresenta lado a lado os valores do servidor e deste aparelho. O tutor escolhe explicitamente entre:

- **Usar servidor:** descarta somente aquele evento pendente e atualiza o cache com a versão oficial.
- **Reaplicar minha alteração:** cria um novo evento idempotente baseado em `serverVersion + 1`, preservando o payload local para nova tentativa.

Nenhum conflito é resolvido automaticamente por sobrescrita silenciosa.

## Regras clínicas importantes

O tutor pode consultar prescrições e histórico clínico, mas registros profissionais continuam sujeitos às regras do backend. Criação de prontuário, vacinação e prescrição exige profissional veterinário verificado e autorização clínica válida quando aplicável.

Alergias podem ser informadas pelo próprio tutor. Quando uma alergia deixa de ser vigente, ela é marcada como inativa em vez de ser apagada, preservando o histórico.

Emendas do prontuário não substituem silenciosamente versões anteriores. A interface exibe o número da versão atual e permite consultar versões anteriores quando existentes.

## API

Por padrão, o Android Emulator usa:

```text
http://10.0.2.2:3000/api
```

Para apontar para outro backend:

```bash
flutter run --dart-define=API_BASE_URL=https://api.exemplo.com/api
```

## Desenvolvimento

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Próximos passos

1. cache offline do prontuário clínico essencial, além do cadastro do pet
2. sincronização de entidades clínicas permitidas ao tutor
3. notificações de vacinas, medicamentos e eventos importantes
4. acessibilidade, internacionalização e design system
5. telemetria de erros sem conteúdo clínico sensível
