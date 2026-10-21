# Changelog

Todas as mudanças relevantes do Lumivent são registradas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e o
projeto usa [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não publicado]

## [1.0.0] — 2026-10-21

Primeira versão pública.

### Adicionado

- Monitoramento de CPU, GPU, memória, placa-mãe, fans AL V2 e SSDs NVMe, com
  histórico de 5 minutos.
- Curvas de fan por grupo do hub Lian Li UNI FAN AL V2, com presets, curvas
  personalizadas, start/stop, fonte de temperatura e resposta configurável.
- Iluminação ARGB por canvas de 320×200, cor fixa e modos de hardware para fans,
  placa-mãe, gabinete, memórias Kingston Fury e GPU Gigabyte.
- Efeitos nativos e importação de efeitos HTML/Canvas (arquivo, pasta, ZIP e cache
  do Windows), com verificação de compatibilidade. Efeitos pagos (assinatura ou
  compra) não são importados do cache do Windows.
- “Desligar todos os ARGB”, apagar ao suspender/desligar e bandeja do sistema.
- Início automático via unidade `systemd --user`.
- Exportação e importação de configuração em JSON.
- Diagnóstico de udev, drivers, SMBus, helper NVMe e programas conflitantes.
- Pacote Arch Linux com regras udev, módulos, atalho, ícone, helper com
  capabilities, documentação e as licenças de terceiros (Inter e QuickJS).
- Tela **Configurações → Sobre → Licenças** com as licenças de tudo que vai no
  app.
- Documentação pública de arquitetura, configuração, hardware, desenvolvimento,
  diagnóstico e release.
- Automação de CI e de release com pacote `.pkg.tar.zst` para Arch Linux.
- 498 testes automatizados, incluindo a verificação das regras de arquitetura.

### Segurança

- Escritas no ITE e na GPU passam por guardas que bloqueiam comandos capazes de
  deixar o controlador em estado irrecuperável.
- O helper de SMART é somente leitura e usa o mínimo de capabilities necessário.
- As regras udev usam `uaccess` e não liberam os barramentos DDC dos monitores.

[1.0.0]: https://github.com/lcsssilva/lumivent/releases/tag/v1.0.0
