# Solução de problemas

Antes de abrir uma issue, confira esta lista e o diagnóstico em
**Configurações → Permissões e sistema**. Inclua na issue a saída dos comandos
relevantes, a versão (`lumivent --version` não existe; use `pacman -Q lumivent`)
e o hardware.

## O app não abre

Rode pelo terminal para ver o erro:

```sh
lumivent
```

Causas comuns:

| Sintoma | Causa provável | Correção |
|---|---|---|
| `error while loading shared libraries` | dependência ausente | `sudo pacman -S --needed gtk3 hidapi libcap` |
| erro de `libhidapi-hidraw` | `hidapi` não instalado | instale `hidapi` |
| janela não aparece, processo fica vivo | iniciou com `--minimized` | abra pelo ícone da bandeja ou rode sem o argumento |
| fecha ao abrir | configuração corrompida | veja [Configuração corrompida](#configuração-corrompida) |

Se o app abriu pelo terminal, os erros da engine aparecem em `stderr` (a mesma
janela do terminal).

## Dispositivo “sem permissão”

1. Confira a ACL:

   ```sh
   getfacl /dev/hidraw* 2>/dev/null | grep -B2 -A4 "$USER"
   getfacl /dev/i2c-* 2>/dev/null | grep -B2 -A4 "$USER"
   ```

2. Se não houver `user:$USER:rw-`, confira se a regra existe:

   ```sh
   ls -l /usr/lib/udev/rules.d/99-lumivent.rules /etc/udev/rules.d/99-lumivent.rules
   ```

3. Recarregue e reconecte:

   ```sh
   sudo udevadm control --reload-rules
   sudo udevadm trigger --subsystem-match=hidraw --subsystem-match=i2c-dev
   ```

4. Se ainda não aparecer, saia e entre na sessão (a ACL `uaccess` é aplicada no
   login).

**Não** adicione seu usuário ao grupo `i2c`: isso liberaria também os barramentos
DDC dos monitores.

## Memórias/Fury ou SMBus não aparecem

O adaptador PIIX4 depende do parâmetro de kernel:

```sh
cat /proc/cmdline          # precisa conter acpi_enforce_resources=lax
i2cdetect -l | grep PIIX4
```

Se não aparecer, edite o bootloader (veja [`instalacao.md`](instalacao.md#2-kernel-acpi_enforce_resourceslax))
e reinicie. O pacote não altera o bootloader de propósito.

## Sensores da placa-mãe ausentes

```sh
lsmod | grep it87
sensors
```

O pacote instala `/usr/lib/modules-load.d/lumivent.conf` e
`/usr/lib/modprobe.d/lumivent.conf`. Se o módulo não carregar:

```sh
sudo modprobe it87 ignore_resource_conflict=1
```

Se o kernel não reconhecer o IT8689E, instale `it87-dkms-git` do AUR.

## Temperatura da memória ausente

```sh
ls /sys/class/hwmon/*/name | xargs grep -l spd5118
```

Sem `spd5118`, o cartão “Temperatura da memória” fica em aviso. O driver pode
ser carregado com `sudo modprobe spd5118`; se não existir no kernel, o alerta é
esperado.

## SMART dos SSDs não aparece

```sh
getcap /usr/lib/lumivent/lumivent-nvme-smart
/usr/lib/lumivent/lumivent-nvme-smart nvme0 nvme1
```

- Sem saída no `getcap`: o helper não tem capabilities. Reinstale o pacote ou
  aplique `sudo setcap cap_sys_admin,cap_dac_read_search+ep ...`.
- `open: Permission denied`: falta `cap_dac_read_search` ou a ACL do dispositivo.
- `error`: compare com `sudo nvme smart-log /dev/nvme0` (pacote `nvme-cli`).
- O helper só lê o log SMART; não é um problema de permissão do app.

Para usar um helper de desenvolvimento:

```sh
LUMIVENT_NVME_SMART=$PWD/build/lumivent-nvme-smart lumivent
```

## As fans não mudam de velocidade

Verifique, nesta ordem:

1. **Conflito**: OpenRGB, liquidctl, CoolerControl ou ckb-next estão rodando?
   Feche-os. O app só avisa; não encerra processos.
2. **Fonte de temperatura**: o grupo pode estar seguindo um sensor sem leitura.
   Em **Fans**, troque para CPU e veja se o status mostra temperatura.
3. **Sync da placa-mãe**: o app desliga o sync no início. Se o hub foi usado no
   Windows com o sync ligado, reinicie o app com o hub conectado.
4. **Curva**: confira o preset, o start/stop e o tamanho da fan (120/140 mm).
5. **Cabo/porta**: o grupo 0 é vazio nesta máquina; use os grupos 1–3.
6. **RPM**: o monitoramento mostra o RPM real; se o duty muda e o RPM não, o
   problema é físico (cabo, porta ou fan).

Traço por ciclo:

```sh
LUMIVENT_FANS_TRACE=1 lumivent
```

## As fans param quando o app fecha

É o comportamento esperado: o hub AL V2 não executa curvas sozinho. Ao sair, o
app envia o duty da própria curva na última temperatura. Se quiser que continuem
girando, mantenha o app aberto na bandeja ou use o início automático.

## O RGB não muda

1. O modo do dispositivo é **Hardware**? Nesse caso, o firmware manda; mude para
   **Canvas** ou **Cor fixa**.
2. “Desligar todos os ARGB” está ativo (topo/bandeja)?
3. O brilho global está em zero?
4. `autoHardware` está entregando o dispositivo ao firmware? Desative em
   **Iluminação** para forçar o canvas.
5. Há conflito com OpenRGB/liquidctl/ckb-next?
6. O dispositivo aparece como “bloqueado” no cartão? Veja o motivo (guarda de
   SSID, comandos proibidos ou barramento ausente).

## RGB da GPU recusado

O driver só libera a GPU após ler o SSID `0x2429`:

```sh
dart run tool/gpu_test.dart id
```

- SSID diferente: a placa não é suportada; não force.
- Barramento `AMDGPU DM i2c OEM bus` ausente: driver `amdgpu` não carregado ou
  GPU diferente.
- Sem permissão: confira a regra udev do I²C.
- O software do fabricante aberto no Windows com SYNC ON pode sobrescrever a
  cor.

## Efeitos HTML não rodam

- **Não suportado**: usa captura de tela ou leitura de pixels, que o runtime não
  implementa.
- **Parcial**: roda com áudio em silêncio ou imagens em branco.
- **Pausado**: o quadro passou de 250 ms três vezes seguidas (script travado).
  Troque o efeito ou reduza os FPS.
- **Não encontrado**: o efeito foi removido de
  `~/.local/share/lumivent/effects/`; importe de novo.

## Bandeja não aparece

- O ambiente precisa de suporte a system tray (KDE Plasma, Xfce, etc. com a
  extensão/indicador ativo).
- Em GNOME, instale uma extensão de AppIndicator.
- Sem bandeja, fechar a janela encerra o app (mesmo com “fechar para a bandeja”)
  e o início minimizado abre a janela.

## Início automático não funciona ou aponta para outro build

```sh
systemctl --user status lumivent.service
cat ~/.config/systemd/user/lumivent.service
```

Se a unidade apontar para outro executável, a tela mostra “unidade aponta para
outro executável”. Desative e ative de novo em **Configurações**. Para conferir:

```sh
systemctl --user restart lumivent.service
journalctl --user -u lumivent.service -n 50
```

## Configuração corrompida

Se o `config.json` não for um JSON válido, o app o renomeia para
`config.json.bad` e começa com os defaults. Para recuperar:

```sh
cd ~/.config/lumivent
python -m json.tool config.json.bad > /tmp/config.json   # veja o erro
# corrija /tmp/config.json e substitua:
mv config.json.bad config.json.bad.old
cp /tmp/config.json config.json
```

Prefira usar **Exportar/Importar** em **Configurações** para backups. Um arquivo
de versão de schema mais nova é recusado na importação.

## Importação de configuração falha

- “O arquivo não é um JSON válido.” — arquivo truncado ou com comentários.
- “O arquivo veio de uma versão mais nova do app.” — atualize o app.
- “O arquivo não tem preferências, iluminação nem fans.” — não é um
  `lumivent-config.json`.

A configuração anterior fica em `config.json.antes-import`.

## Uso alto de CPU

- Reduza `effectsFps` para 15 em **Configurações**.
- Efeitos HTML são scripts; alguns são pesados. O status mostra FPS e
  tempo de quadro.
- Desative traces (`LUMIVENT_FANS_TRACE`, `LUMIVENT_LIGHTING_TRACE`).
- O streaming de canvas para as fans é limitado a ~2 fps de propósito; não é
  bug.

## Coletando informações para uma issue

Inclua:

```sh
pacman -Q lumivent
uname -r
cat /proc/cmdline
i2cdetect -l
sensors
getfacl /dev/hidraw* /dev/i2c-* 2>/dev/null | grep -B2 -A4 "$USER"
getcap /usr/lib/lumivent/lumivent-nvme-smart
journalctl --user -u lumivent.service -n 100   # se usar autostart
```

e a saída do app rodando pelo terminal (`lumivent`), com os traces ativados se o
problema for de fans ou iluminação. **Remova dados pessoais** (números de série,
caminhos do home) antes de publicar.
