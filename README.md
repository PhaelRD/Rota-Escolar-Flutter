# Rota Escolar - Resumo de Funcionamento do Software

**Observação:** Este documento descreve as funcionalidades garantidas 100% no sistema. Outras funcionalidades estão planejadas para futuras implementações, dependendo de tempo e outros fatores.

## Objetivo

O **Rota Escolar** foi desenvolvido para atender às necessidades de transportadores escolares, oferecendo uma solução completa que otimiza a gestão e operação do transporte escolar.

## Tecnologias Utilizadas

- **Flutter & Dart:**  
  Utilizados para o desenvolvimento da interface e funcionalidades, possibilitando a criação de uma solução multiplataforma.

- **Firebase:**  
  - **Hospedagem:** A versão web é hospedada na nuvem, assegurando alta disponibilidade e escalabilidade.  
  - **Banco de Dados:** Responsável pelo armazenamento e gerenciamento seguro dos dados em nuvem.  
  - **Autenticação de Usuários:** Gerencia o acesso e garante a segurança dos usuários nas plataformas web e Android.

- **Cloud Run:**  
  Utilizado como webhook de comunicação entre o Stripe e o Firebase Realtime Database, garantindo a atualização automática de informações de pagamentos e assinaturas.

- **APIs:**  
  - **Brevo:** Utilizada para envio de e-mails automáticos, como notificações de reajuste de mensalidade.  
  - **Stripe:** Implementada para gerenciamento de pagamentos e assinaturas recorrentes.

![Imagem do WhatsApp de 2025-03-11 à(s) 15 57 21_2119be74](https://github.com/user-attachments/assets/582237de-6768-49c1-b502-5b9895dc0669)

## Plataformas

- **Web:**  
  Acesso via navegador com integração completa das funcionalidades suportadas pelo Firebase.
  
- **Android:**  
  Versão mobile que integra autenticação e demais funcionalidades, mantendo a consistência com a versão web.

## Detalhamento das Funcionalidades por Página

### Tela de Login

- **Login no App:**  
  Permite que o usuário insira suas credenciais (usuário e senha) para acessar o aplicativo.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_33_43](https://github.com/user-attachments/assets/508d4d56-cd58-4645-862f-f02e695001fd)
  
- **Recuperação de Senha:**  
  Disponibiliza uma funcionalidade para que o usuário recupere sua senha em caso de esquecimento, facilitando o restabelecimento do acesso ao app.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_34_24](https://github.com/user-attachments/assets/b193d61a-0853-4c33-9324-00f78ea68b6f)

### Tela de Registro

- **Registro de Usuário:**  
  Permite que novos usuários criem uma conta no aplicativo, inserindo informações como nome, e-mail, senha e demais dados necessários para o cadastro.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_34_01](https://github.com/user-attachments/assets/c5b11e35-a62c-4963-9f33-91b7abb5195f)

### Dashboard

- **Resumo de Informações Importantes:**  
  Exibição de dados organizados em gráficos para fornecer uma visão geral da operação do transporte escolar, com métricas essenciais para auxiliar o transportador na tomada de decisões.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_38_33](https://github.com/user-attachments/assets/87c32222-5eae-4284-a031-6b79bedea89b)
  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_38_50](https://github.com/user-attachments/assets/0d4467d7-d84e-46ef-8150-dc69e6957b77)


### Escolas

- **Registro de Escolas:**  
  Permite o cadastro de novas escolas no sistema.
  
- **Edição de Escolas:**  
  Possibilita a alteração dos dados das escolas cadastradas.
  
- **Exclusão de Escolas:**  
  Permite a remoção de escolas do sistema quando necessário.
  
- **Pesquisa de Escolas por Nome:**  
  Facilita a busca por escolas cadastradas utilizando o nome como critério.
  
- **Envio de Mensagens para Escola via WhatsApp:**  
  Permite a comunicação direta com a escola através do WhatsApp.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_35_10](https://github.com/user-attachments/assets/17d6aea5-7504-480d-b7f2-11d48fd7887b)

### Alunos

- **Registro de Alunos:**  
  Permite o cadastro de novos alunos no sistema.
  
- **Edição de Alunos:**  
  Possibilita a alteração dos dados dos alunos cadastrados.
  
- **Exclusão de Alunos:**  
  Permite a remoção de alunos do sistema quando necessário.
  
- **Pesquisa de Aluno por Nome:**  
  Facilita a busca por alunos cadastrados utilizando o nome como critério.
  
- **Envio de Mensagem para o Responsável via WhatsApp:**  
  Permite a comunicação direta com o responsável do aluno através do WhatsApp.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_35_31](https://github.com/user-attachments/assets/754232cd-2c8c-45df-83db-eebc8dc2c413)

### Reajuste

- **Aplicação de Reajuste de Mensalidade:**  
  Permite aplicar reajuste nos valores das mensalidades para alunos selecionados.
  
- **Envio de E-mail de Aviso:**  
  Integração com a API Brevo para envio automático de notificações sobre reajustes aos responsáveis.
  
- **Pesquisa de Alunos:**  
  Permite buscar alunos por nome ou valor da mensalidade.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_35_43](https://github.com/user-attachments/assets/6b8b044b-3504-4b4c-9975-b9f04f49a203)

### Convite

- **Definição de Valor do Convite:**  
  Permite que o transportador defina o valor do convite para novos alunos.
  
- **Envio de Convite para Cadastro:**  
  Envio de um link para que o responsável do aluno se auto cadastre via página web.

### Gastos

- **Cadastro de Gastos:**  
  Permite registrar despesas relacionadas à operação do transporte escolar.
  
- **Edição e Exclusão de Gastos:**  
  Possibilita a modificação ou remoção de registros de gastos.
  
- **Filtragem por Categoria e Período:**  
  Organização e análise dos gastos mensalmente, categorizando as despesas.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_36_00](https://github.com/user-attachments/assets/4f704485-93ad-47b8-9aee-6832bb311986)

### Avisos de Pagamento

- **Listagem de Pagamentos:**  
  Lista os pagamentos das mensalidades dos alunos, concluídos ou não.
  
- **Cobranças:**  
  Permite a realização de cobranças via WhatsApp dos responsáveis que tiveram atraso nas mensalidades.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_36_21](https://github.com/user-attachments/assets/c779d529-1aca-499b-aa76-41f4ed8a4022)
  
### Assinatura

- **Realização de Assinatura:**  
  Funcionalidade para assinar planos que liberam recursos extras no aplicativo.
  
- **Integração com API Stripe:**  
  Permite pagamentos seguros e recorrentes via Stripe.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_36_35](https://github.com/user-attachments/assets/891e0b8a-5064-40c5-8115-47b32c38a9e1)

### Perfil

- **Informações do Usuário:**  
  Exibição e edição dos dados do usuário cadastrado no sistema.
  
- **Logout:**  
  Permite que o usuário encerre sua sessão com segurança, garantindo a proteção dos dados e acessos.
  
- **Exclusão de Conta:**  
  Funcionalidade que permite ao usuário excluir sua conta do sistema, removendo todos os seus dados de forma permanente.

  ![screencapture-9000-idx-rota-escolar-1740271762534-cluster-uf6urqn4lned4spwk4xorq6bpo-cloudworkstations-dev-2025-03-11-15_36_59](https://github.com/user-attachments/assets/4635583c-6146-4a7b-9654-c6c71e2ed0f4)
