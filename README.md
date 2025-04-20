XKC-KL200 Laser-Abstandssensor Bash-Tool
Ein Bash-Skript zur Steuerung und Auslese des XKC-KL200-2M-UART Laser-Abstandssensors unter Linux.

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
Einmalige Distanzmessung
BASH
./xkc_kl200.sh read
Kontinuierliche Distanzmessung
BASH
./xkc_kl200.sh monitor
Automatischen Modus aktivieren
BASH
./xkc_kl200.sh auto
LED-Modus konfigurieren
BASH
./xkc_kl200.sh set-led 0  # LED leuchtet bei Erkennung
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
Kommunikationsprobleme
Stellen Sie sicher, dass die richtige Baudrate verwendet wird (standardmäßig 9600).

Führen Sie das Skript mit Debugging aus:

BASH
bash -x ./xkc_kl200.sh read
Setzen Sie den Sensor auf Werkseinstellungen zurück:

BASH
./xkc_kl200.sh reset
Technische Details
Protokoll
Der XKC-KL200 verwendet ein serielles Protokoll mit 9-Byte-Paketen:

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
Lizenz
Dieses Projekt steht unter der MIT-Lizenz - siehe die LICENSE Datei für Details.
