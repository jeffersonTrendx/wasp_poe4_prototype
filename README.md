# 🛰️ WasP BLE Multicast Listener (Flutter)

Este projeto Flutter escuta pacotes BLE no formato **WasP** enviados via **multicast UDP** e extrai informações de dispositivos como o **MyBeat**. Ele interpreta os dados brutos de broadcast para mostrar **ID do dispositivo**, **frequência cardíaca (HR)** e **número da sala**.

## 📦 Recursos

- Escuta pacotes via `RawDatagramSocket` (UDP Multicast)
- Interpreta pacotes WasP BLE com prefixo `0x42 0x4C`
- Extrai:
  - MAC Address
  - RSSI
  - Dados do Fabricante
  - Nome do dispositivo (Advertising Data)
  - UUIDs (quando presentes)
- Filtra e exibe apenas dispositivos com `id == 22` (MyBeat)

## 📱 Exemplo de UI

Lista dos dispositivos em tempo real:
ID: 22 • HR: 77
Room: 4

🧠 Estrutura de Pacotes WasP
Um pacote válido começa com 42 4C e possui subpacotes iniciando com 4E. Os dados de advertisement seguem o formato TLV (Type-Length-Value).

Tipos comuns:
0x09: Nome do dispositivo (ex: "mybeat")

0xFF: Dados do fabricante (contém ID do dispositivo e HR)

0x03: Lista de UUIDs 16-bit

Mais exemplos na documentação : https://docs.google.com/document/d/1ZTQOB274DlDegy2i069ZyXQMfnbx-V6M/edit?usp=sharing&ouid=109016576676281329142&rtpof=true&sd=true

📌 Observações
Apenas pacotes com prefixo 0x42 0x4C são processados

ANT+ (0x41 0x4E) são ignorados

O MAC Address é extraído dos bytes [3..8], invertido (little-endian → big-endian)

🛠️ Tecnologias
Flutter 3.7.1

Dart

Android UDP Socket

BLE Advertising Parsing

📚 Referência
Este projeto segue o protocolo WasP utilizado pela Goper Group com adaptações para dispositivos MyBeat.



