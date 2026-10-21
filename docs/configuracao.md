# Configuração e dados

O Lumivent guarda tudo em arquivos no `$HOME` do usuário. Não há banco de dados,
serviço ou configuração em `/etc` além das regras instaladas pelo pacote.

## Caminhos

| Caminho | Conteúdo | Respeita |
|---|---|---|
| `~/.config/lumivent/config.json` | preferências, fans e iluminação | `XDG_CONFIG_HOME` |
| `~/.config/lumivent/config.json.antes-import` | cópia feita antes de importar | `XDG_CONFIG_HOME` |
| `~/.config/lumivent/config.json.bad` | arquivo corrompido, preservado | `XDG_CONFIG_HOME` |
| `~/.local/share/lumivent/effects/<id>/` | efeitos importados | `XDG_DATA_HOME` |
| `~/.config/systemd/user/lumivent.service` | início automático, se ativado | `XDG_CONFIG_HOME` |

A desinstalação do pacote **não** remove esses arquivos.

## `config.json`

Um único arquivo com uma seção por módulo e a versão do schema:

```json
{
  "version": 1,
  "preferences": {
    "closeToTray": true,
    "temperatureUnit": "celsius",
    "effectsFps": 30
  },
  "fans": { "groups": [] },
  "lighting": { "effectId": "rainbowWave" }
}
```

Garantias do `ConfigStore`:

- **Escrita atômica**: grava em `config.json.tmp`, dá `flush` e renomeia.
- **Escrita serializada**: gravações concorrentes entram numa fila.
- **Leitura tolerante**: chave ausente, tipo errado ou valor desconhecido usa o
  default; o app abre mesmo com um arquivo antigo ou editado à mão.
- **Corrupção**: JSON inválido ou raiz que não seja objeto é renomeado para
  `config.json.bad` (não é sobrescrito) e o app começa com os defaults.
- **Exportação**: cópia profunda de todas as seções + `version`.
- **Importação**: substitui apenas `preferences`, `lighting` e `fans`, numa
  única escrita, após copiar o arquivo atual para `.antes-import`. Um arquivo de
  versão de schema mais nova é recusado.

> Editar o arquivo com o app aberto pode ser sobrescrito na próxima gravação.
> Feche o app antes de editar à mão.

## `preferences`

| Chave | Tipo | Default | Descrição |
|---|---|---|---|
| `closeToTray` | bool | `true` | fechar a janela apenas oculta para a bandeja |
| `temperatureUnit` | `"celsius"` \| `"fahrenheit"` | `"celsius"` | unidade exibida na interface |
| `effectsFps` | `15` \| `30` \| `60` | `30` | FPS do laço de iluminação |

Qualquer outro valor de `effectsFps` cai em `30`; o hub AL V2 rende melhor perto
de 15 fps quando recebe streaming de canvas.

## `fans`

A seção contém exatamente quatro grupos (as quatro portas do hub). O grupo 0 é
vazio nesta máquina e fica sempre apagado.

```json
{
  "groups": [
    {
      "name": "Grupo 0",
      "size": "mm120",
      "preset": "standard",
      "customPoints": [[25, 20], [40, 50], [55, 62], [70, 75], [90, 100]],
      "userPoints": {},
      "fixedPercent": 50,
      "startStop": false,
      "source": "cpuTctl",
      "response": "normal"
    }
  ]
}
```

| Chave | Tipo | Default | Descrição |
|---|---|---|---|
| `name` | string | `"Grupo N"` | nome mostrado na interface |
| `size` | `"mm120"` \| `"mm140"` | grupo 1: `mm140`; demais: `mm120` | limites de RPM da curva |
| `preset` | `quiet`, `standard`, `high`, `full`, `fixed`, `user1`–`user4`, `custom` | `standard` | curva ativa |
| `customPoints` | `[[°C, %], …]` | pontos de Standard | pontos da curva `custom` |
| `userPoints` | mapa preset → pontos | vazio (usa Quiet) | pontos salvos de UserDefine 1–4 |
| `fixedPercent` | número 0–100 | `50` | velocidade no modo `fixed` |
| `startStop` | bool | `false` | duty 1 abaixo do primeiro ponto |
| `source` | ver tabela abaixo | `cpuTctl` | temperatura seguida pela curva |
| `response` | `fast` \| `normal` \| `smooth` | `normal` | média móvel e rampa |

Fontes de temperatura (`source`):

| Valor | Sensor |
|---|---|
| `cpuTctl` | CPU (`k10temp`) |
| `gpuJunction` | GPU, temperatura de junção |
| `gpuEdge` | GPU, borda |
| `boardSystem1`, `boardSystem2` | System 1 / System 2 |
| `boardPch` | PCH |
| `boardCpuSocket` | soquete da CPU |
| `boardVrm` | VRM MOS |
| `boardPciex16`, `boardPciex4` | PCIEX16 / PCIEX4 |

Limites: até 8 pontos por curva, temperatura e porcentagem entre 0 e 100.
Pontos fora da faixa são limitados; um preset de fábrica vira `custom` ao ser
editado. A resposta `fast` não faz média nem rampa; `normal` usa 4 s de média e
sobe 15 pontos/s (desce 3); `smooth` usa 10 s e sobe 5 (desce 1).

## `lighting`

As chaves de nível superior:

| Chave | Tipo | Default | Descrição |
|---|---|---|---|
| `argbOff` | bool | `false` | “Desligar todos os ARGB” |
| `brightness` | número 0–1 | `1` | brilho global de canvas/cor fixa |
| `offOnSleep` | bool | `true` | apagar ao suspender/desligar |
| `autoHardware` | bool | `true` | usar modo do firmware quando houver equivalente |
| `effectId` | string | `"rainbowWave"` | efeito global (nativo ou `html:<id>`) |
| `effectValues` | objeto | `{}` | parâmetros por id de efeito |
| `devices` | objeto | defaults | configuração por dispositivo |
| `fanQuantity` | lista de 4 inteiros 0–6 | `[0, 3, 3, 1]` | fans por grupo do hub |
| `alv2Hardware` | lista de 4 objetos | `StaticColor` | modo de hardware por grupo |
| `alv2Merge` | bool | `false` | mesclar os grupos num efeito único |
| `alv2MergeMode` | string | `"Runway"` | modo da mesclagem |
| `alv2MergeOrder` | lista de 4 inteiros | `[0, 1, 2, 3]` | ordem física dos grupos; o grupo 0 vem primeiro |
| `boardZones` | objeto | defaults | zonas `0x20`, `0x22` e `0x23` da placa |
| `gpuHardware` | objeto | `Pulse` | efeito de firmware da GPU |

### `devices`

Chaves: `alv2Group1`, `alv2Group2`, `alv2Group3`, `chassis`, `motherboard`,
`ram1`, `ram2`, `gpu`.

```json
{
  "gpu": {
    "enabled": true,
    "mode": "canvas",
    "fixedColor": "#FFFFFF",
    "placement": { "x": 220, "y": 45, "w": 90, "h": 40 }
  }
}
```

| Chave | Tipo | Default | Descrição |
|---|---|---|---|
| `enabled` | bool | `true` (dispositivos suportados) | dispositivo participa do efeito |
| `mode` | `canvas` \| `hardware` \| `fixed` | `canvas` | quem decide a cor |
| `fixedColor` | `"#RRGGBB"` | `"#FFFFFF"` | cor do modo `fixed` |
| `placement` | `{x, y, w, h}` | por dispositivo | retângulo no canvas 320×200 |

Modos aceitos por dispositivo:

| Dispositivo | Canvas | Hardware | Cor fixa |
|---|---|---|---|
| Fans (grupos 1–3), placa-mãe, GPU | sim | sim | sim |
| Gabinete, memória 1 e 2 | sim | não | sim |

O retângulo é validado e limitado ao canvas; valores ausentes ou inválidos usam
a posição padrão.

### `alv2Hardware`

Objeto por grupo (índice 0–3). O índice 0 guarda apenas as configurações da
mesclagem, porque não tem fans.

```json
{
  "scope": "whole",
  "mode": "StaticColor",
  "speed": 2,
  "brightness": 4,
  "directionLeft": false,
  "colors": ["#FF0000", "#0000FF", "#00FF00", "#FFFF00", "#FF8000", "#00FFFF"]
}
```

| Chave | Tipo | Default | Descrição |
|---|---|---|---|
| `scope` | `whole` \| `innerOuter` | `whole` | fan inteira ou anéis interno/externo |
| `mode` | string | `"StaticColor"` | nome do modo do firmware |
| `speed` | inteiro 0–4 | `2` | velocidade do firmware |
| `brightness` | inteiro 0–4 | `4` | brilho do firmware |
| `directionLeft` | bool | `false` | direção do efeito |
| `colors` | lista de `#RRGGBB` | paleta de fábrica | cores do efeito |

Os nomes de modo são os do firmware (por exemplo `Rainbow`, `Breathing`,
`Runway`, `Scan`, `Taichi`); a tabela de bytes fica no módulo `devices`.

### `boardZones`

Chaves `0x20` (IO Shield 1), `0x22` (LED_CPU) e `0x23` (IO Shield 2).

| Chave | Tipo | Default |
|---|---|---|
| `mode` | `static`, `pulse`, `flash`, `doubleFlash`, `colorCycle`, `wave` | `static` |
| `color` | `#RRGGBB` | `#FFFFFF` |
| `speed` | inteiro 0–9 | `5` |
| `brightness` | inteiro 0–9 | `9` |

### `gpuHardware`

| Chave | Tipo | Default |
|---|---|---|
| `effect` | `off`, `staticColor`, `pulse`, `flash`, `doubleFlash`, `cycle`, `wave`, `gradient`, `colorShift`, `rainbow`, `tricolor`, `claws`, `dazzle` | `pulse` |
| `speed` | inteiro 0–10 | `5` |
| `brightness` | inteiro 0–10 | `10` |
| `color` | `#RRGGBB` | `#FFFFFF` |
| `colors` | lista de 8 `#RRGGBB` | paleta padrão (ColorShift) |

O driver só aceita a GPU depois de ler o SSID `0x2429`. Um valor inválido cai no
default; o firmware nunca recebe um efeito fora da tabela.

## Efeitos importados

Cada efeito fica em `~/.local/share/lumivent/effects/<id>/`:

| Arquivo | Conteúdo |
|---|---|
| `effect.html` | script e metadados do efeito |
| `effect.json` | `title`, `origin` (`file`, `folder`, `zip`, `windowsCache`), `importedAt`, `publisher`, `description`, `tags` |
| `thumbnail.png` | prévia gerada na primeira execução (opcional) |

O `id` é o nome da pasta, sanitizado para `[a-z0-9._-]`. Importar um efeito com
o mesmo `id` substitui o anterior. Na importação do cache do Windows, o arquivo
de catálogo (`catalog_en.json`) é obrigatório: ele acrescenta nome, autor,
descrição e tags — o efeito em si vem de `effect.html` — e marca os efeitos
pagos (assinatura ou compra), que **não** são importados.

## Exportar e importar

Em **Configurações → Configuração**:

- **Exportar** grava todas as seções em `lumivent-config.json` (JSON indentado).
- **Importar** lê um JSON, valida o schema e substitui
  `preferences`/`lighting`/`fans` de uma vez; a configuração anterior vira
  `config.json.antes-import`.
- A importação é aplicada na hora, sem reiniciar: cada módulo recarrega a
  própria seção e reenvia a configuração à engine.

Erros exibidos ao usuário: JSON inválido, arquivo que não é uma configuração,
arquivo de versão mais nova e arquivo sem nenhuma seção conhecida.

## Migração e compatibilidade

- `version` é `1` nesta série. A leitura não exige a chave.
- Chaves desconhecidas são ignoradas (não são apagadas até a próxima gravação da
  seção).
- Uma chave com tipo errado usa o default daquele campo, sem impedir o resto.
- Configurações antigas, como `{"argbOff": true}` sozinho na seção
  `lighting`, continuam válidas.
- Se o formato mudar de forma incompatível, a versão do schema sobe e o app
  recusa importar arquivos mais novos; a migração é feita na leitura.
