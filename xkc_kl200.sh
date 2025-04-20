#!/bin/bash

# XKC-KL200-2M-UART Laser-Abstandssensor Bash-Implementierung
# Basierend auf der C++ und Python-Implementierung

# Fehlercodes
XKC_SUCCESS=0
XKC_INVALID_PARAMETER=1
XKC_TIMEOUT=2
XKC_CHECKSUM_ERROR=3
XKC_RESPONSE_ERROR=4

# Standardwerte
DEFAULT_PORT="/dev/ttyUSB0"
DEFAULT_BAUDRATE=9600
DEFAULT_TIMEOUT=1

# Globale Variablen
SERIAL_PORT=""
AUTO_MODE=false
LAST_DISTANCE=0

# Hilfsfunktion: Zeigt Nutzung an
show_usage() {
    echo "XKC-KL200 Laser-Abstandssensor Bash-Tool"
    echo ""
    echo "Verwendung: \$0 [OPTIONEN] BEFEHL"
    echo ""
    echo "OPTIONEN:"
    echo "  -p, --port PORT       Serieller Port (Standard: $DEFAULT_PORT)"
    echo "  -b, --baudrate RATE   Baudrate (Standard: $DEFAULT_BAUDRATE)"
    echo "  -t, --timeout SEC     Timeout in Sekunden (Standard: $DEFAULT_TIMEOUT)"
    echo "  -h, --help            Diese Hilfe anzeigen"
    echo ""
    echo "BEFEHLE:"
    echo "  init                  Initialisiere den Sensor"
    echo "  read                  Distanz einmalig messen"
    echo "  monitor               Kontinuierlich Distanz messen"
    echo "  auto                  Automatischen Modus aktivieren"
    echo "  manual                Manuellen Modus aktivieren"
    echo "  set-led MODE          LED-Modus setzen (0-3)"
    echo "  set-interval VALUE    Upload-Intervall setzen (1-100)"
    echo "  set-comm-mode MODE    Kommunikationsmodus setzen (0=Relais, 1=UART)"
    echo "  reset                 Sensor auf Werkseinstellungen zurücksetzen"
    echo ""
    echo "Beispiel: \$0 -p /dev/ttyUSB0 read"
}

# Hilfsfunktion: Berechnet XOR-Prüfsumme
calculate_checksum() {
    local data="\$1"
    local checksum=0
    
    for ((i=0; i<${#data}; i+=2)); do
        byte=$(printf "%d" "0x${data:$i:2}")
        checksum=$((checksum ^ byte))
    done
    
    printf "%02X" $checksum
}

# Hilfsfunktion: Sendet Befehl an den Sensor
send_command() {
    local command="\$1"
    local expected_cmd="\$2"
    local timeout="${3:-$DEFAULT_TIMEOUT}"
    
    # Befehl senden
    echo -n -e "$command" > "$SERIAL_PORT"
    
    # Auf Antwort warten
    local start_time=$(date +%s)
    local response=""
    local timeout_seconds=$timeout
    
    # Timeout-Schleife für die Antwort
    while true; do
        # Prüfen, ob Timeout erreicht wurde
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge $timeout_seconds ]; then
            echo "Timeout beim Warten auf Antwort" >&2
            return $XKC_TIMEOUT
        fi
        
        # Versuchen, Daten zu lesen
        if read -t 0.1 -N 9 response < "$SERIAL_PORT"; then
            break
        fi
    done
    
    # Antwort in Hex konvertieren für die Analyse
    local hex_response=$(hexdump -v -e '/1 "%02X"' <<< "$response")
    
    # Prüfen, ob die Antwort zum gesendeten Befehl passt
    local resp_cmd="${hex_response:2:2}"
    
    if [ "${hex_response:0:2}" == "62" ] && [ "$resp_cmd" == "$expected_cmd" ]; then
        # Prüfsumme berechnen und vergleichen
        local received_checksum="${hex_response:16:2}"
        local calculated_checksum=$(calculate_checksum "${hex_response:0:16}")
        
        if [ "$received_checksum" == "$calculated_checksum" ]; then
            # Prüfen, ob die Antwort eine erfolgreiche Ausführung anzeigt (0x66)
            if [ "${hex_response:14:2}" == "66" ]; then
                return $XKC_SUCCESS
            fi
        else
            return $XKC_CHECKSUM_ERROR
        fi
    fi
    
    return $XKC_RESPONSE_ERROR
}

# Hilfsfunktion: Liest Distanz vom Sensor
read_distance() {
    local timeout="${1:-$DEFAULT_TIMEOUT}"
    
    # Befehl zum Lesen der Distanz
    local command=$(echo -e "\x62\x33\x09\xFF\xFF\x00\x00\x00\x$(printf "\x%02X" $((0x62 ^ 0x33 ^ 0x09 ^ 0xFF ^ 0xFF ^ 0x00 ^ 0x00 ^ 0x00)))")
    
    # Befehl senden
    echo -n -e "$command" > "$SERIAL_PORT"
    
    # Auf Antwort warten
    local start_time=$(date +%s)
    local response=""
    local timeout_seconds=$timeout
    
    # Timeout-Schleife für die Antwort
    while true; do
        # Prüfen, ob Timeout erreicht wurde
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge $timeout_seconds ]; then
            echo "Timeout beim Warten auf Antwort" >&2
            return $LAST_DISTANCE
        fi
        
        # Versuchen, Daten zu lesen
        if read -t 0.1 -N 9 response < "$SERIAL_PORT"; then
            break
        fi
    done
    
    # Antwort in Hex konvertieren für die Analyse
    local hex_response=$(hexdump -v -e '/1 "%02X"' <<< "$response")
    
    # Prüfen, ob es sich um eine gültige Distanzmeldung handelt
    if [ "${hex_response:0:2}" == "62" ] && [ "${hex_response:2:2}" == "33" ]; then
        # Prüfsumme berechnen und vergleichen
        local received_checksum="${hex_response:16:2}"
        local calculated_checksum=$(calculate_checksum "${hex_response:0:16}")
        
        if [ "$received_checksum" == "$calculated_checksum" ]; then
            # Distanz aus der Antwort extrahieren (Bytes 5-6)
            local distance_high="${hex_response:10:2}"
            local distance_low="${hex_response:12:2}"
            local distance=$((0x$distance_high * 256 + 0x$distance_low))
            
            LAST_DISTANCE=$distance
            echo $distance
            return 0
        fi
    fi
    
    # Bei Fehler letzte bekannte Distanz zurückgeben
    echo $LAST_DISTANCE
    return 1
}

# Hilfsfunktion: Initialisiert den seriellen Port
init_serial_port() {
    # Prüfen, ob der Port existiert
    if [ ! -e "$SERIAL_PORT" ]; then
        echo "Fehler: Serieller Port $SERIAL_PORT existiert nicht" >&2
        exit 1
    fi
    
    # Serielle Schnittstelle konfigurieren
    stty -F "$SERIAL_PORT" $DEFAULT_BAUDRATE cs8 -cstopb -parenb -echo
    
    # Puffer leeren
    cat < "$SERIAL_PORT" > /dev/null &
    CLEAR_PID=$!
    sleep 0.1
    kill $CLEAR_PID 2>/dev/null
    wait $CLEAR_PID 2>/dev/null
    
    echo "Serieller Port $SERIAL_PORT initialisiert mit Baudrate $DEFAULT_BAUDRATE"
}

# Funktion: Setzt den Upload-Modus
set_upload_mode() {
    local mode=\$1
    
    if [ "$mode" != "0" ] && [ "$mode" != "1" ]; then
        echo "Fehler: Ungültiger Upload-Modus. Verwende 0 (manuell) oder 1 (automatisch)" >&2
        return $XKC_INVALID_PARAMETER
    fi
    
    # Befehl zum Setzen des Upload-Modus
    local checksum=$((0x62 ^ 0x34 ^ 0x09 ^ 0xFF ^ 0xFF ^ 0x00 ^ 0x$mode ^ 0x00))
    local command=$(echo -e "\x62\x34\x09\xFF\xFF\x00\x$mode\x00\x$(printf "\x%02X" $checksum)")
    
    # Befehl senden und auf Antwort warten
    send_command "$command" "34"
    local result=$?
    
    if [ $result -eq $XKC_SUCCESS ]; then
        if [ "$mode" -eq 1 ]; then
            AUTO_MODE=true
            echo "Automatischer Upload-Modus aktiviert"
        else
            AUTO_MODE=false
            echo "Manueller Abfragemodus aktiviert"
        fi
    else
        echo "Fehler beim Setzen des Upload-Modus: $result" >&2
    fi
    
    return $result
}

# Funktion: Setzt das Upload-Intervall
set_upload_interval() {
    local interval=\$1
    
    if [ $interval -lt 1 ] || [ $interval -gt 100 ]; then
        echo "Fehler: Ungültiges Intervall. Verwende 1-100 (100ms-10s)" >&2
        return $XKC_INVALID_PARAMETER
    fi
    
    # Befehl zum Setzen des Upload-Intervalls
    local checksum=$((0x62 ^ 0x35 ^ 0x09 ^ 0xFF ^ 0xFF ^ 0x00 ^ interval ^ 0x00))
    local command=$(echo -e "\x62\x35\x09\xFF\xFF\x00\x$(printf "\x%02X" $interval)\x00\x$(printf "\x%02X" $checksum)")
    
    # Befehl senden und auf Antwort warten
    send_command "$command" "35"
    local result=$?
    
    if [ $result -eq $XKC_SUCCESS ]; then
        echo "Upload-Intervall auf $interval gesetzt ($(($interval * 100))ms)"
    else
        echo "Fehler beim Setzen des Upload-Intervalls: $result" >&2
    fi
    
    return $result
}

# Funktion: Setzt den LED-Modus
set_led_mode() {
    local mode=\$1
    
    if [ $mode -lt 0 ] || [ $mode -gt 3 ]; then
        echo "Fehler: Ungültiger LED-Modus. Verwende 0-3" >&2
        return $XKC_INVALID_PARAMETER
    fi
    
    # Befehl zum Setzen des LED-Modus
    local checksum=$((0x62 ^ 0x37 ^ 0x09 ^ 0xFF ^ 0xFF ^ 0x00 ^ mode ^ 0x00))
    local command=$(echo -e "\x62\x37\x09\xFF\xFF\x00\x$(printf "\x%02X" $mode)\x00\x$(printf "\x%02X" $checksum)")
    
    # Befehl senden und auf Antwort warten
    send_command "$command" "37"
    local result=$?
    
    if [ $result -eq $XKC_SUCCESS ]; then
        echo "LED-Modus auf $mode gesetzt"
    else
        echo "Fehler beim Setzen des LED-Modus: $result" >&2
    fi
    
    return $result
}

# Funktion: Setzt den Kommunikationsmodus
set_communication_mode() {
    local mode=\$1
    
    if [ $mode -lt 0 ] || [ $mode -gt 1 ]; then
        echo "Fehler: Ungültiger Kommunikationsmodus. Verwende 0 (Relais) oder 1 (UART)" >&2
        return $XKC_INVALID_PARAMETER
    fi
    
    # Befehl zum Setzen des Kommunikationsmodus
    local checksum=$((0x61 ^ 0x30 ^ 0x09 ^ 0xFF ^ 0xFF ^ 0x00 ^ mode ^ 0x00))
    local command=$(echo -e "\x61\x30\x09\xFF\xFF\x00\x$(printf "\x%02X" $mode)\x00\x$(printf "\x%02X" $checksum)")
    
    # Befehl senden und auf Antwort warten
    send_command "$command" "30"
    local result=$?
    
    if [ $result -eq $XKC_SUCCESS ]; then
        if [ "$mode" -eq 1 ]; then
            echo "UART-Kommunikationsmodus aktiviert"
        else
            echo "Relais-Kommunikationsmodus aktiviert"
        fi
    else
        echo "Fehler beim Setzen des Kommunikationsmodus: $result" >&2
    fi
    
    return $result
}

# Funktion: Setzt den Sensor auf Werkseinstellungen zurück
reset_sensor() {
    # Befehl zum Zurücksetzen auf Werkseinstellungen
    local checksum=$((0x62 ^ 0x39 ^ 0x09 ^ 0xFF ^ 0xFF ^ 0xFF ^ 0xFF ^ 0xFE))
    local command=$(echo -e "\x62\x39\x09\xFF\xFF\xFF\xFF\xFE\x$(printf "\x%02X" $checksum)")
    
    # Befehl senden und auf Antwort warten
    send_command "$command" "39"
    local result=$?
    
    if [ $result -eq $XKC_SUCCESS ]; then
        echo "Sensor erfolgreich auf Werkseinstellungen zurückgesetzt"
    else
        echo "Fehler beim Zurücksetzen des Sensors: $result" >&2
    fi
    
    return $result
}

# Funktion: Kontinuierlich Distanz messen
monitor_distance() {
    echo "Starte kontinuierliche Distanzmessung (Strg+C zum Beenden)"
    echo "----------------------------------------"
    
    trap 'echo -e "\nMessung beendet."; exit 0' INT
    
    while true; do
        local distance=$(read_distance)
        local result=$?
        
        if [ $result -eq 0 ]; then
            echo "$(date +"%H:%M:%S") - Distanz: ${distance} mm"
        else
            echo "$(date +"%H:%M:%S") - Fehler bei der Messung"
        fi
        
        sleep 0.5
    done
}

# Funktion: Automatischen Modus überwachen
monitor_auto_mode() {
    echo "Starte Überwachung im automatischen Modus (Strg+C zum Beenden)"
    echo "----------------------------------------"
    
    trap 'echo -e "\nÜberwachung beendet."; exit 0' INT
    
    # Puffer leeren
    cat < "$SERIAL_PORT" > /dev/null &
    CLEAR_PID=$!
    sleep 0.1
    kill $CLEAR_PID 2>/dev/null
    wait $CLEAR_PID 2>/dev/null
    
    # Endlosschleife zum Empfangen der Daten
    while true; do
        # Auf 9 Bytes warten (Größe eines Datenpakets)
        if read -t 1 -N 9 response < "$SERIAL_PORT"; then
            # Antwort in Hex konvertieren für die Analyse
            local hex_response=$(hexdump -v -e '/1 "%02X"' <<< "$response")
            
            # Prüfen, ob es sich um eine gültige Distanzmeldung handelt
            if [ "${hex_response:0:2}" == "62" ] && [ "${hex_response:2:2}" == "33" ]; then
                # Prüfsumme berechnen und vergleichen
                local received_checksum="${hex_response:16:2}"
                local calculated_checksum=$(calculate_checksum "${hex_response:0:16}")
                
                if [ "$received_checksum" == "$calculated_checksum" ]; then
                    # Distanz aus der Antwort extrahieren (Bytes 5-6)
                    local distance_high="${hex_response:10:2}"
                    local distance_low="${hex_response:12:2}"
                    local distance=$((0x$distance_high * 256 + 0x$distance_low))
                    
                    LAST_DISTANCE=$distance
                    echo "$(date +"%H:%M:%S") - Distanz: ${distance} mm"
                else
                    echo "$(date +"%H:%M:%S") - Prüfsummenfehler"
                fi
            else
                # Ungültige Daten - einen Byte verwerfen und neu versuchen
                dd if="$SERIAL_PORT" of=/dev/null bs=1 count=1 2>/dev/null
            fi
        fi
    done
}

# Hauptfunktion
main() {
    # Parameter verarbeiten
    SERIAL_PORT="$DEFAULT_PORT"
    COMMAND=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                SERIAL_PORT="$2"
                shift 2
                ;;
            -b|--baudrate)
                DEFAULT_BAUDRATE="$2"
                shift 2
                ;;
            -t|--timeout)
                DEFAULT_TIMEOUT="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                if [ -z "$COMMAND" ]; then
                    COMMAND="$1"
                    shift
                else
                    COMMAND_ARGS+=("$1")
                    shift
                fi
                ;;
        esac
    done
    
    # Prüfen, ob ein Befehl angegeben wurde
    if [ -z "$COMMAND" ]; then
        echo "Fehler: Kein Befehl angegeben" >&2
        show_usage
        exit 1
    fi
    
    # Befehl ausführen
    case "$COMMAND" in
        init)
            init_serial_port
            ;;
        read)
            init_serial_port
            echo "Messe Distanz..."
            distance=$(read_distance)
            echo "Distanz: ${distance} mm"
            ;;
        monitor)
            init_serial_port
            monitor_distance
            ;;
        auto)
            init_serial_port
            set_upload_mode 1
            if [ $? -eq $XKC_SUCCESS ]; then
                # Optional: Intervall setzen, wenn als Parameter angegeben
                if [ ${#COMMAND_ARGS[@]} -gt 0 ]; then
                    set_upload_interval ${COMMAND_ARGS[0]}
                fi
                monitor_auto_mode
            fi
            ;;
        manual)
            init_serial_port
            set_upload_mode 0
            ;;
        set-led)
            init_serial_port
            if [ ${#COMMAND_ARGS[@]} -eq 0 ]; then
                echo "Fehler: LED-Modus nicht angegeben" >&2
                exit 1
            fi
            set_led_mode ${COMMAND_ARGS[0]}
            ;;
        set-interval)
            init_serial_port
            if [ ${#COMMAND_ARGS[@]} -eq 0 ]; then
                echo "Fehler: Intervall nicht angegeben" >&2
                exit 1
            fi
            set_upload_interval ${COMMAND_ARGS[0]}
            ;;
        set-comm-mode)
            init_serial_port
            if [ ${#COMMAND_ARGS[@]} -eq 0 ]; then
                echo "Fehler: Kommunikationsmodus nicht angegeben" >&2
                exit 1
            fi
            set_communication_mode ${COMMAND_ARGS[0]}
            ;;
        reset)
            init_serial_port
            reset_sensor
            ;;
        *)
            echo "Fehler: Unbekannter Befehl '$COMMAND'" >&2
            show_usage
            exit 1
            ;;
    esac
}

# Prüfen, ob das Skript direkt ausgeführt wird
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Array für Befehlsargumente
    declare -a COMMAND_ARGS=()
    
    # Hauptfunktion aufrufen
    main "$@"
fi
