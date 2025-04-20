Dieses Repository enthält ein Bash-Skript zur Steuerung und Auslese des XKC-KL200-2M-UART Laser-Abstandssensors unter Linux. Das Skript bietet eine einfache Kommandozeilen-Schnittstelle für alle wichtigen Funktionen des Sensors.

Inhaltsverzeichnis
Funktionen
Voraussetzungen
Installation
Verwendung des Bash-Skripts
Grundlegende Syntax
Verfügbare Optionen
Verfügbare Befehle
Beispiele
Konfigurationsparameter
LED-Modi
Upload-Intervall
Kommunikationsmodi
Fehlerbehebung
Technische Details
Lizenz
Funktionen
Einmalige und kontinuierliche Distanzmessung
Unterstützung für manuellen und automatischen Modus
Konfiguration aller Sensorparameter (LED-Modus, Upload-Intervall, Kommunikationsmodus)
Zurücksetzen auf Werkseinstellungen
Robuste Fehlerbehandlung und Timeout-Mechanismen
Voraussetzungen
Linux-Betriebssystem
Bash-Shell (Version 4.0 oder höher)
Standard-Linux-Tools: stty, cat, dd, hexdump
Serielle Schnittstelle (z.B. USB-zu-UART-Adapter)
Berechtigungen zum Zugriff auf serielle Ports
Installation
Klonen Sie das Repository:

BASH
git clone https://github.com/username/xkc-kl200-bash.git
cd xkc-kl200-bash
Machen Sie das Skript ausführbar:

BASH
chmod +x xkc_kl200.sh
Stellen Sie sicher, dass Ihr Benutzer Zugriff auf serielle Ports hat:

BASH
sudo usermod -a -G dialout $USER
(Neuanmeldung erforderlich, damit die Änderung wirksam wird)

Verwendung des Bash-Skripts
Grundlegende Syntax
BASH
./xkc_kl200.sh [OPTIONEN] BEFEHL [PARAMETER]
Verfügbare Optionen
Option	Beschreibung	Standardwert
-p, --port PORT	Serieller Port	/dev/ttyUSB0
-b, --baudrate RATE	Baudrate	9600
-t, --timeout SEC	Timeout in Sekunden	1
-h, --help	Hilfe anzeigen	-
Verfügbare Befehle
Befehl	Beschreibung	Parameter
init	Initialisiert den Sensor	-
read	Führt eine einmalige Distanzmessung durch	-
monitor	Kontinuierliche Distanzmessung im manuellen Modus	-
auto	Aktiviert den automatischen Modus und überwacht die Messwerte	[Intervall]
manual	Aktiviert den manuellen Modus	-
set-led	Setzt den LED-Modus	0-3
set-interval	Setzt das Upload-Intervall	1-100
set-comm-mode	Setzt den Kommunikationsmodus	0 (Relais) oder 1 (UART)
reset	Setzt den Sensor auf Werkseinstellungen zurück	-
Beispiele
Sensor initialisieren
BASH
./xkc_kl200.sh -p /dev/ttyUSB0 init
Einmalige Distanzmessung
BASH
./xkc_kl200.sh read
Kontinuierliche Distanzmessung
BASH
./xkc_kl200.sh monitor
Drücken Sie Strg+C, um die Messung zu beenden.

Automatischen Modus aktivieren
BASH
./xkc_kl200.sh auto
Der Sensor sendet automatisch Messwerte, die vom Skript angezeigt werden.

Automatischen Modus mit bestimmtem Intervall aktivieren
BASH
./xkc_kl200.sh auto 5  # 500ms Intervall
Manuellen Modus aktivieren
BASH
./xkc_kl200.sh manual
LED-Modus konfigurieren
BASH
./xkc_kl200.sh set-led 0  # LED leuchtet bei Erkennung
Upload-Intervall setzen
BASH
./xkc_kl200.sh set-interval 10  # 1 Sekunde (10 × 100ms)
Kommunikationsmodus setzen
BASH
./xkc_kl200.sh set-comm-mode 1  # UART-Modus
Sensor zurücksetzen
BASH
./xkc_kl200.sh reset
Konfigurationsparameter
LED-Modi
Modus	Beschreibung
0	LED leuchtet bei Erkennung eines Objekts
1	LED leuchtet, wenn kein Objekt erkannt wird
2	LED immer an
3	LED immer aus
Upload-Intervall
Das Upload-Intervall im automatischen Modus wird in Einheiten von 100ms angegeben:

Wert 1: 100ms
Wert 10: 1 Sekunde
Wert 100: 10 Sekunden
Kommunikationsmodi
Modus	Beschreibung
0	Relais-Modus (Sensor schaltet Relais bei Erkennung)
1	UART-Modus (Sensor sendet Messwerte über serielle Schnittstelle)
Fehlerbehebung
Keine Verbindung zum Sensor
Überprüfen Sie, ob der richtige serielle Port angegeben ist:

BASH
ls -l /dev/tty*
Prüfen Sie die Berechtigungen für den seriellen Port:

BASH
ls -l /dev/ttyUSB0
Stellen Sie sicher, dass Ihr Benutzer in der Gruppe dialout ist:

BASH
groups $USER
Überprüfen Sie die Verkabelung:

TX des Sensors an RX des Adapters
RX des Sensors an TX des Adapters
GND des Sensors an GND des Adapters
VCC des Sensors an 5V/3.3V (je nach Modell)
Kommunikationsprobleme
Stellen Sie sicher, dass die richtige Baudrate verwendet wird (standardmäßig 9600).

Führen Sie das Skript mit Debugging aus:

BASH
bash -x ./xkc_kl200.sh read
Überprüfen Sie, ob der Sensor im richtigen Kommunikationsmodus ist:

BASH
./xkc_kl200.sh set-comm-mode 1
Setzen Sie den Sensor auf Werkseinstellungen zurück:

BASH
./xkc_kl200.sh reset
Technische Details
Protokoll
Der XKC-KL200 verwendet ein einfaches serielles Protokoll mit 9-Byte-Paketen:

Byte 1: Header (0x62)
Byte 2: Befehlscode
Byte 3: Paketlänge (0x09)
Byte 4-5: Adresse (0xFF, 0xFF)
Byte 6-8: Daten
Byte 9: XOR-Prüfsumme
Befehlscodes
Code	Beschreibung
0x33	Distanz lesen
0x34	Upload-Modus setzen
0x35	Upload-Intervall setzen
0x37	LED-Modus setzen
0x39	Zurücksetzen
0x30	Kommunikationsmodus setzen
Abhängigkeiten
Das Skript verwendet Standard-Linux-Tools:

stty für die Konfiguration der seriellen Schnittstelle
cat und dd für die Kommunikation
hexdump für die Analyse der Antworten
Lizenz
Dieses Projekt steht unter der MIT-Lizenz - siehe die LICENSE Datei für Details.
