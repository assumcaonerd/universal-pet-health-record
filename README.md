# 🐾 Universal Pet Health Record (Prontuário Universal do Pet)

> **Software proprietário em desenvolvimento.** O código-fonte e os componentes autorais deste projeto são protegidos. Consulte o arquivo [`LICENSE`](LICENSE) antes de qualquer uso, cópia, modificação ou distribuição.

Sistema descentralizado, interoperável e centrado no tutor para o histórico de saúde e bem-estar de animais de estimação.
O objetivo deste projeto é eliminar a fragmentação de dados entre clínicas veterinárias, petshops, hotéis de animais e emergências, dando ao tutor o controle total e o acesso imediato ao prontuário do seu pet em qualquer lugar do mundo.

---

## 🚀 Como Funciona (O Ecossistema)

1. **App do Tutor (Mobile - Offline First):** O dono do pet carrega o prontuário no celular. Funciona mesmo sem internet (usando cache local criptografado) gerando um **QR Code Dinâmico** de emergência ou leitura rápida.
2. **Portal do Veterinario (Web/Clinic):** Permite que novas clínicas leiam o QR Code (com autorização temporária do tutor), adicionem novas consultas, exames e vacinas direto no registro universal.
3. **Módulo Petshop/Hotel:** Permite verificar atestados de vacinação (raiva, giárdia, etc.) de forma instantânea e segura, sem precisar de papéis.

---

## 📋 Módulos de Informações Essenciais (Baseado em Boas Práticas Globais)

### 1. Identificação Inegociável
- Nome, Espécie, Raça, Pelagem/Cor, Data de Nascimento (ou idade estimada).
- **Identificação Biométrica/Eletrônica:** Número do Microchip (padrão ISO 11784/11785) e foto do focinho (biometria facial pet) ou impressão nasal.
- Árvore genealógica / Dados do Criador (se houver).

### 2. Histórico Médico e Clínico (Veterinários)
- **Alergias Críticas:** Alergia a medicamentos (ex: penicilina), alimentos ou anestésicos (destaque em vermelho no app).
- **Condições Crônicas:** Diabetes, insuficiência renal, cardiopatias.
- **Linha do Tempo de Consultas:** Diagnósticos, prescrições de uso contínuo e evoluções clínicas.
- **Laudos de Exames:** Upload de PDF/Imagens de exames de sangue, ultrassom, raio-x e eletrocardiograma.

### 3. Prevenção e Sanidade (Petshops e Clínicas)
- **Carteira de Vacinação Digital:** Vacinas aplicadas, lote, fabricante, veterinário responsável e data do próximo reforço (com alertas push para o tutor).
- **Controle de Parasitas:** Histórico de aplicação de anti-pulgas, carrapatos e vermífugos.

### 4. Estilo de Vida e Bem-Estar (Petshops)
- Dieta atual (marca, quantidade, restrições alimentares).
- Comportamento (nível de sociabilidade com outros cães/humanos, reações a fogos de artifício ou manuseio).

---

## 🔒 Privacidade e Segurança (LGPD e GDPR)

- **Consentimento Dinâmico:** O tutor gera um token de acesso de 15 minutos para que o veterinário da nova clínica visualize ou edite o prontuário.
- **Criptografia Ponta a Ponta:** Dados sensíveis armazenados com chaves pertencentes exclusivamente ao dono do pet.

---

## 🛠️ Tecnologias Sugeridas

- **Mobile:** Flutter (para rodar liso em Android e iOS com suporte nativo a SQLite/Hive para modo offline).
- **Backend:** Node.js (NestJS) ou Go, com arquitetura orientada a eventos.
- **Banco de Dados:** PostgreSQL (dados relacionais estruturados) + MongoDB ou Armazenamento de Objetos (para exames e imagens).
- **Padrão de Dados:** Baseado em interoperabilidade JSON para facilitar a integração com sistemas de clínicas já existentes (como SimplesVet, HiperZoo, etc.).

---

## 🔐 Licença e propriedade intelectual

O Universal Pet Health Record é desenvolvido como **software proprietário**. Salvo quando um componente de terceiro possuir licença própria, nenhuma permissão é concedida para copiar, modificar, redistribuir, sublicenciar, vender ou explorar comercialmente este código sem autorização prévia por escrito.

Bibliotecas, frameworks, SDKs, modelos, padrões e demais componentes de terceiros continuam sujeitos aos respectivos termos e licenças.

Consulte [`LICENSE`](LICENSE) para os termos aplicáveis ao código autoral deste repositório.

## 🤝 Colaboração

Contribuições externas não são aceitas automaticamente. Propostas de parceria, integração técnica ou contribuição de código devem ser previamente autorizadas e, quando aplicável, acompanhadas de instrumento adequado de cessão ou licenciamento de propriedade intelectual.
