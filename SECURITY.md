# Política de segurança

## Versões suportadas

Correções de segurança são aplicadas à versão estável mais recente.

| Versão | Suporte |
|---|---|
| 1.x | Sim |
| < 1.0 | Não |

## Como relatar

**Não abra issue pública para vulnerabilidades.**

Use o canal privado do GitHub:

1. Acesse <https://github.com/lcsssilva/lumivent/security/advisories/new>.
2. Descreva o problema, a versão afetada e o hardware/sistema.
3. Inclua passos de reprodução, impacto e, se possível, uma prova de conceito.
4. Se ainda não houver correção, combine com o mantenedor um prazo de
   divulgação (normalmente 90 dias).

Você receberá uma confirmação em até 7 dias. Problemas críticos são tratados
primeiro; a correção e o aviso são publicados em um release com nota de
segurança.

## Escopo

O Lumivent roda como usuário comum, mas interage com dispositivos sensíveis.
São considerados no escopo:

- regras udev e permissões (`uaccess`) que exponham dispositivos além do
  necessário;
- o helper `lumivent-nvme-smart` e o uso de `cap_sys_admin` /
  `cap_dac_read_search`;
- leitura e escrita via `dart:ffi` em hidraw, I²C/SMBus e sysfs;
- comandos de driver que possam danificar hardware ou contornar guardas de
  segurança (ITE, GPU e SMBus);
- importação de efeitos (HTML, pasta, ZIP e cache do Windows), incluindo path
  traversal, ZIP bomb e execução de JavaScript no runtime QuickJS;
- importação de configuração e escrita do `config.json`;
- a unidade `systemd --user` gerada pelo app.

Fora do escopo:

- vulnerabilidades em dependências de terceiros já corrigidas upstream (relate
  ao projeto original; avise-nos se o Lumivent precisar de atualização);
- problemas que exigem acesso root prévio ou modificação local das regras udev;
- engenharia social, phishing ou ataques físicos.

## Boas práticas para usuários

- Instale apenas pacotes do release oficial ou compile a partir do código.
- Confira o checksum `sha256sums.txt` antes de instalar um `.pkg.tar.zst`.
- Não adicione seu usuário ao grupo `i2c`; as regras `uaccess` já cobrem os
  dispositivos do app.
- Importe efeitos apenas de fontes confiáveis: o efeito roda JavaScript no
  runtime do app.
- Mantenha o pacote atualizado com `pacman -Syu`.

## Divulgação responsável

Pedimos que você:

- dê tempo razoável para a correção antes de divulgar publicamente;
- evite acessar dados de terceiros, interromper serviços ou destruir hardware;
- atue de boa-fé, sem extorsão ou exigências financeiras.

Não tomaremos medidas legais contra pesquisadores que sigam esta política.
