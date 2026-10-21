# Hardware, protocolos e segurança

Este documento descreve o que o Lumivent controla, como fala com cada
dispositivo e quais guardas existem para não deixar o hardware num estado
irrecuperável.

A engenharia reversa que originou os drivers está em notas históricas locais,
que não fazem parte do repositório nem do pacote.

## Resumo

| Dispositivo | Transporte | Identificação | Direção |
|---|---|---|---|
| Hub Lian Li UNI FAN AL V2 | hidraw | `0cf2:a104`, interface 1, report `0xE0` | leitura e escrita |
| Gigabyte RGB Fusion 2 (ITE IT5702) | hidraw | `048d:5702`, report `0xCC` | leitura e escrita |
| Kingston Fury DDR5 | SMBus PIIX4 (`/dev/i2c-N`) | endereços `0x61` e `0x63` | leitura e escrita |
| Gigabyte RX 9060 XT (RGB) | I²C bruto no `AMDGPU DM i2c OEM bus` | endereço `0x75`, SSID `0x2429` | leitura e escrita |
| Sensores da placa-mãe | sysfs (`it87`) | `it8689`, `it8792` | somente leitura |
| SSDs NVMe | sysfs + helper | `/dev/nvmeN`, log `02h` | somente leitura |

O app roda como usuário comum. O único componente com privilégio é o helper
`lumivent-nvme-smart`, com capabilities, e ele só lê o log SMART.

## Hub Lian Li UNI FAN AL V2

- VID:PID `0cf2:a104`; interface HID 1; report de feature `0xE0`.
- Relatório de saída de 353 bytes (ID + 352) para cores; entrada de 65 bytes.
- Quatro grupos (portas físicas), oito portas de iluminação (duas por grupo:
  anel interno e externo) e até seis fans por grupo.
- Cada fan AL120 tem 20 LEDs: 8 no anel interno e 12 no externo.
- Pacotes de duty `E0 (20|g) 00 duty`, com duty limitado a 1–100 (0 nunca é
  enviado; 1 é o valor de parada do firmware).
- Sync de RPM da placa-mãe é desligado no início: se o software do fabricante
  deixou o sync ligado no Windows, o hub ignoraria o duty do app.

### Streaming e RPM

Medições no hardware mostraram que streaming contínuo de cores derruba o RPM
das fans (o firmware gasta tempo no barramento e perde a comutação). Por isso:

- o app usa **modos de hardware** do firmware sempre que o efeito tem
  equivalente (`hardware_equivalents.dart`);
- quando precisa transmitir canvas, as fans recebem no máximo um frame a cada
  **500 ms** (`alv2SafeStreamGap`, ~2 fps); 5 fps já derrubava o RPM em até 15%;
- entre pacotes de iluminação, o driver respeita 2 ms (`alv2StreamGap`), e 20 ms
  entre pacotes que o firmware exige.

Os efeitos de firmware têm velocidade e direção próprias; o app alinha a fase do
canvas à animação do firmware (por exemplo, `Breathing` e `Scan`) para que
fans, fita, RAM e GPU mostrem o mesmo instante.

### Merge

O hub permite mesclar os grupos num efeito único (`E0 10 60 ...` + ordem). A
ordem configura: qual grupo ocupa cada posição física. O grupo 0 é vazio nesta
máquina e precisa continuar em primeiro na ordem; a UI só reordena os grupos
1–3.

## ITE IT5702 (placa-mãe e gabinete)

- VID:PID `048d:5702`; report `0xCC`; pacotes de 64 bytes.
- Zonas endereçáveis expostas: `0x20` (IO Shield 1), `0x22` (LED_CPU) e `0x23`
  (IO Shield 2).
- `D_LED1` (`0x58`) controla a fita do gabinete: 47 LEDs.
- Ordem de cor varia por canal: fitas ARGB 5 V usam G,R,B; zonas da placa usam
  B,G,R. O driver lê a ordem do `CalStrip` quando disponível.
- Máximo de 19 LEDs por pacote de cor.

### Comandos proibidos

Toda escrita passa por `checkIteCommand`. São bloqueados:

| Comando | Motivo |
|---|---|
| `0x5E` | gravação na flash do MCU |
| `0x47` | persistir configuração após desligar (não suportado) |
| `0x48` | troca para MSDL (não suportado) |
| `0x59` | dados do D_LED2, que alimenta a entrada ARGB do hub |
| `CC 32` com bit D_LED2 | modo direto do D_LED2 (header do hub) |

O `0x59` é especialmente perigoso: ele alimenta a entrada ARGB do hub AL V2 e
pode misturar os dois barramentos.

## Kingston Fury DDR5

- Barramento encontrado pelo nome `SMBus PIIX4 adapter port 0 at 0b00` (o número
  de `/dev/i2c-N` muda entre boots).
- Endereços validados nesta máquina: `0x61` e `0x63`. O app **não faz varredura**
  de endereços.
- Antes de qualquer escrita, lê o registrador de guarda `0xDD`. Valores `0x72` e
  `0x78` indicam controlador PWM RT3678/RT3672 no lugar do LED: o endereço é
  ignorado.
- 12 LEDs por pente, 36 registradores de cor (`0x50 + 3·led + canal`).
- Sessão: `0x08 = 0x53` abre, `0x08 = 0x44` fecha; brilho em `0x20 = 0x50`.
- O SMBus PIIX4 só aparece com `acpi_enforce_resources=lax` no kernel.

O `core/platform/smbus_ffi.dart` recusa os endereços SPD `0x50–0x57` antes de
qualquer ioctl: acessar SPD/EEPROM pode danificar o módulo.

## GPU Gigabyte RX 9060 XT

- Adaptador `AMDGPU DM i2c OEM bus` (não use as linhas DDC dos monitores).
- Endereço de 7 bits `0x75`; pacotes de 64 bytes; resposta de 4 bytes.
- Firmware, SSID e efeito: comandos `0x10`, `0x11` e `0x12`.
- **Guarda de identidade:** o SSID `0x2429` é lido antes de qualquer `0x12`.
  Outra placa nunca recebe efeito.
- **Comandos bloqueados:** `0x13` (save), `0x16` (sync), `0x17` e `0x18`
  (desconhecidos; o `0x18` precede um crash do software do fabricante no
  Windows).
- Espera de 200 ms após leitura de identificação e 120 ms após escrita de
  efeito (máximo ~8 efeitos/s).
- Efeitos de firmware: `off`, `staticColor`, `pulse`, `flash`, `doubleFlash`,
  `cycle`, `wave`, `gradient`, `colorShift` (8 cores), `rainbow`, `tricolor`,
  `claws`, `dazzle`; velocidade e brilho de 0 a 10.

Se o software do fabricante estiver aberto no Windows com SYNC ON, ele pode
sobrescrever a cor. Não use outro programa de RGB ao mesmo tempo que o app.

## Sensores e SSD

### `it87`

O pacote carrega `it87` com `ignore_resource_conflict=1` e `i2c-dev` no boot. Os
chips esperados são `it8689` (temperaturas e fans 0–4) e `it8792` (sensores 6–8
e fans 5–7). Fans e bomba da placa-mãe são **somente leitura**.

### Helper NVMe

`tool/lumivent-nvme-smart/lumivent-nvme-smart.c` compila para
`/usr/lib/lumivent/lumivent-nvme-smart` e recebe:

```sh
sudo setcap cap_sys_admin,cap_dac_read_search+ep /usr/lib/lumivent/lumivent-nvme-smart
```

- `cap_sys_admin`: o kernel exige essa capability para `Get Log Page 02h`.
- `cap_dac_read_search`: abre `/dev/nvmeN` (root:root, 600).
- O helper só envia o comando de log SMART; não escreve, não formata e não
  altera nada.
- Saída: uma linha JSON por controlador, com o log de 512 bytes em hexadecimal
  ou um erro. O app faz o parse e calcula vida restante e saúde.

Caminhos procurados: `$LUMIVENT_NVME_SMART`,
`/usr/lib/lumivent/lumivent-nvme-smart` e
`/usr/local/lib/lumivent/lumivent-nvme-smart`.

## Conflitos com outros programas

Dois donos do mesmo hidraw/SMBus misturam pacotes. O app detecta e **avisa**,
mas nunca encerra processos:

| Programa | Processo |
|---|---|
| OpenRGB | `openrgb` |
| liquidctl | `liquidctl` (inclusive via Python) |
| CoolerControl | `coolercontrold` |
| ckb-next | `ckb-next-daemon` |

Feche-os antes de usar o Lumivent ou de rodar as ferramentas de `tool/`.

## Limitações e compatibilidade

- O suporte é validado no hardware listado no README. Outros modelos de hub,
  placa ou GPU podem não responder.
- O RGB da GPU é restrito ao SSID `0x2429`.
- O hub AL V2 não executa curvas sozinho: ao sair, as fans ficam no duty de
  saída calculado pela curva.
- O app não controla a curva da placa-mãe nem a bomba do AIO.
- A tela do AIO SmartMonitor X28 está fora do escopo.
- Não há suporte a Windows ou macOS.

## Aviso legal

Lian Li, Gigabyte, AORUS e Kingston são marcas de seus respectivos
donos. O Lumivent é um projeto independente, sem afiliação ou endosso. Nenhum
firmware, efeito, fonte ou binário proprietário é redistribuído pelo projeto; a
importação de efeitos lê apenas arquivos que o usuário já possui.
