// Kingston Fury DDR5 memory on PIIX4 SMBus (protocol notes §4).

/// Adapter containing the memory. The `/dev/i2c-N` number changes between
/// boots, so it is found by this name.
const furyBusName = 'SMBus PIIX4 adapter port 0 at 0b00';

/// Only addresses already validated on this machine (phase 0). No scanning.
const furyAddresses = [0x61, 0x63];

/// Guard register: read before any write.
const furyGuardRegister = 0xDD;

/// `0xDD` values that indicate an RT3678/RT3672 PWM controller in place of
/// for the LED: the address must be skipped.
const furyGuardBlocked = {0x72, 0x78};

/// Does the guard allow the address?
bool furyGuardAllows(int dd) => !furyGuardBlocked.contains(dd);

// --- Fury lighting protocol (§4) ---

/// Session register: `0x53` opens, `0x44` closes.
const furyRegSession = 0x08;
const furySessionBegin = 0x53;
const furySessionEnd = 0x44;

/// Mode register: `0x10` direct (per-LED color), `0x00` single color.
const furyRegMode = 0x09;
const furyModeDirect = 0x10;
const furyModeSingle = 0x00;

/// Direct mode enable registers (plugin values).
const furyRegDirectB = 0x0B;
const furyRegDirectC = 0x0C;

/// Brightness; the plugin uses `0x50` (80).
const furyRegBrightness = 0x20;
const furyBrightness = 0x50;

/// Single color: `0x30 = 01` and `0x31..0x33 = R,G,B`.
const furyRegSingleEnable = 0x30;
const furyRegSingleColor = 0x31;

/// Per-LED color: `0x50 + 3·led + channel` (12 LEDs × R,G,B = 36 registers).
const furyRegLedBase = 0x50;
const furyLedCount = 12;
const furyColorBytes = furyLedCount * 3;

/// Register of LED [led] (0..11), channel [channel] (0 R, 1 G, 2 B).
int furyLedRegister(int led, int channel) => furyRegLedBase + 3 * led + channel;

/// Registers whose high byte (of the WORD) forms the identity.
const furyIdRegisters = [1, 2, 3, 4];

/// Accepted identities (high byte of WORDs from registers 1..4): "FURY" and plugin variants.
const furyIdSignatures = [
  [0x46, 0x55, 0x52, 0x59],
  [0x06, 0x55, 0x52, 0x59],
  [0x07, 0xE0, 0xFF, 0xFF],
];

/// Is [highBytes] the identity of a FURY module?
bool furyIdMatches(List<int> highBytes) {
  for (final sig in furyIdSignatures) {
    if (sig.length == highBytes.length &&
        [for (var i = 0; i < sig.length; i++) sig[i] == highBytes[i]]
            .every((b) => b)) {
      return true;
    }
  }
  return false;
}
