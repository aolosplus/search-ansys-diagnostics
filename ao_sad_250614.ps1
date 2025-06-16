# ==================================================================================
# Konfiguration Manuell
# ==================================================================================
  $BasisSuchordner =           "C:\x\"
  $AggregierterAusgabeordner = "C:\x\logs"
# ==================================================================================
# ==================================================================================
# ==================================================================================























































<#
.NAME
    Search And Destroy :D
.SYNOPSIS
    Führt vordefinierte Suchläufe durch, fasst Ergebnisse zusammen, exportiert sie als CSV und zeigt sie an.
.DESCRIPTION
    Dieses Skript führt eine Reihe von zentral definierten Suchläufen durch. Alle gefundenen Ergebnisse 
    werden gesammelt, in eine aggregierte CSV-Datei exportiert und in einem interaktiven GridView angezeigt.
.NOTES
    Autor: AO (und Gemini 2.5 Bro)  ###   Version: 3.14.6 - finale++ - 15.06.2025                              
#>
# ==================================================================================
# Ordner mit den Namen 'tomcat' oder 'logs' können optional übersprungen werden
# >> sehr auf die Ansys-Diags angepasst
  [switch]$UeberspringeStandardOrdner = $false

# ==================================================================================
# Definition der Suchläufe
# ==================================================================================
$Suchdefinitionen = @(
    @{ Begriff = "OS Version:";      Tag = "Betriebssys";       Typen = "*.txt" },
    @{ Begriff = "hostname";         Tag = "Hostname";          Typen = "*.txt" },
    @{ Begriff = "build";            Tag = "SystemInfoBuild";   Typen = "*.txt" },
    @{ Begriff = " build ";          Tag = "SystemInfoBuild";   Typen = "*.nfo" },
# ==================================================================================	
    @{ Begriff = "Benutzername";     Tag = "System-User";       Typen = @("*.txt", "*.log") },
    @{ Begriff = "IPv4";             Tag = "System-IPv4";       Typen = @("*.txt", "*.log") },
# ==================================================================================	
    @{ Begriff = "1055@";            Tag = "PORT";              Typen = @("*.ini", "*.log", "*.txt", "*.itcl") },
    @{ Begriff = "1055";             Tag = "PORT";              Typen = @("*.ini", "*.itcl") },
# ==================================================================================	
    @{ Begriff = "1056@";            Tag = "PORT";              Typen = @("*.ini", "*.log", "*.txt", "*.itcl") },
    @{ Begriff = "1056";             Tag = "PORT";              Typen = @("*.ini", "*.itcl") },
# ==================================================================================	
    @{ Begriff = "2325@";            Tag = "PORT";              Typen = @("*.ini", "*.log", "*.txt") },
    @{ Begriff = "2325";             Tag = "PORT";              Typen = @("*.ini", "*.itcl") },
# ==================================================================================
    @{ Begriff = "ANS";              Tag = "Ansys-Info";        Typen = @("*.ini", "*.err") },
    @{ Begriff = "ANS_";             Tag = "Ansys-Info";        Typen = @("*.txt", "*.log") },
    @{ Begriff = '"ANSYS';           Tag = "Ansys-Info";        Typen = @("*.txt", "*.log") },
    @{ Begriff = "Revision: 202";    Tag = "Revision-Info";     Typen = @("*.txt", "*.log") },
# ==================================================================================	
    @{ Begriff = "VENDOR";           Tag = "Lizenz-Vendor";     Typen = @("*.ini", "*.log") },
    @{ Begriff = "FLEXLM";           Tag = "Lizenz-Flex";       Typen = @("*.txt", "*.log") },
    @{ Begriff = "FLEXLM";           Tag = "Lizenz-Flex";       Typen = "*.nfo" },
# ==================================================================================
# ==================================================================================
    @{ Begriff = "Error";            Tag = "Fehler-Log";        Typen = @("*.log", "*.txt") },
    @{ Begriff = "Warning";          Tag = "Warnungen-Log";     Typen = @("*.log", "*.txt") }
# ==================================================================================
)

# ----------------------------------------------------------------------------------
# TEIL 1: KERN-SUCHFUNKTION
# ----------------------------------------------------------------------------------

function Start-DateiSuche {
<#
.SYNOPSIS
    Führt einen einzelnen, definierten Suchlauf durch und gibt die Ergebnisse zurück.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string]$FolderPath,
        [Parameter(Mandatory)] [string]$SearchTerm,
        [string[]]$FileTypes,
        [switch]$CaseSensitive,
        [switch]$SkipStandardFolders,
        [string]$Tag
    )

    $ergebnisseZumExport = @()

    # Hole alle Dateien, die den Dateitypen entsprechen
    $standardErweiterungen = @("*.ini", "*.txt", "*.lic", "*.log", "*.nfo", "*.opt", "*.itcl")
    $erlaubteErweiterungen = if ($FileTypes) { $FileTypes } else { $standardErweiterungen }
    $alleDateien = Get-ChildItem -Path $FolderPath -Recurse -File -Include $erlaubteErweiterungen -ErrorAction SilentlyContinue

    $dateienZumDurchsuchen = $alleDateien
    # Wenn der Schalter gesetzt ist, filtere die Liste der Dateien zuverlässig
    if ($SkipStandardFolders.IsPresent) {
        $ordnerZumUeberspringen = @("tomcat", "logs")
        Write-Verbose "Filtere Ergebnisliste. Schließe Ordner aus: $($ordnerZumUeberspringen -join ', ')"
        $dateienVorFilter = $alleDateien.Count
        
        $dateienZumDurchsuchen = $alleDateien | Where-Object {
            $pfadTeile = $_.DirectoryName.Split([System.IO.Path]::DirectorySeparatorChar)
            $treffer = $pfadTeile | Where-Object { $ordnerZumUeberspringen -contains $_ }
            $treffer -eq $null
        }
        $dateienNachFilter = $dateienZumDurchsuchen.Count
        Write-Verbose "Dateien gefiltert: $dateienVorFilter -> $dateienNachFilter. ($($dateienVorFilter - $dateienNachFilter) Dateien entfernt)"
    }

    if (-not $dateienZumDurchsuchen) { return $ergebnisseZumExport }
    
    # Durchsuche nur die bereinigte Liste
    $ergebnisse = $dateienZumDurchsuchen | Select-String -Pattern $SearchTerm -CaseSensitive:$CaseSensitive -SimpleMatch -ErrorAction SilentlyContinue

    if ($ergebnisse) {
        $suchlaufId = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $aktuellerZeitstempelLesbar = (Get-Date).ToString("dd.MM.yyyy HH:mm:ss")
        
        Write-Host "`n$($ergebnisse.Count) Treffer für '$SearchTerm' gefunden:" -ForegroundColor Green

        foreach ($treffer in $ergebnisse) {
            Write-Host "  Datei: " -NoNewline; Write-Host $treffer.Path -ForegroundColor DarkYellow
            Write-Host "  Zeile $($treffer.LineNumber): " -ForegroundColor Cyan -NoNewline
            Write-Host $treffer.Line.Trim()
            
            $ergebnisseZumExport += [PSCustomObject]@{
                SuchZeitstempel = $aktuellerZeitstempelLesbar
                SuchlaufID      = $suchlaufId
                Tag             = $Tag
                Suchbegriff     = $SearchTerm
                Dateipfad       = $treffer.Path
                Dateiname       = $treffer.FileName
                Zeilennummer    = $treffer.LineNumber
                Zeileninhalt    = $treffer.Line
            }
        }
    }
    return $ergebnisseZumExport
}

# ----------------------------------------------------------------------------------
# TEIL 2: STEUERUNGSSKRIPT UND AGGREGIERUNG
# ----------------------------------------------------------------------------------

$steuerungsLaufId = (Get-Date).ToString("yyyyMMdd_HHmmss")
$alleGesammeltenErgebnisse = @()

# Bunter Header
Write-Host "===========================================================" -ForegroundColor DarkYellow
Write-Host "                Batch-Suchlauf Control by AO" -ForegroundColor DarkCyan
Write-Host "===========================================================" -ForegroundColor DarkYellow
if ($UeberspringeStandardOrdner) { Write-Host "[INFO] Standardordner ('tomcat', 'logs') werden übersprungen." -ForegroundColor Yellow }
Write-Host "-----------------------------------------------------------" -ForegroundColor DarkYellow

# Die kompakte Suchschleife
foreach ($suche in $Suchdefinitionen) {
    Write-Host "`n[SUCHE] Starte Suche nach '$($suche.Begriff)' (Tag: $($suche.Tag))..." -ForegroundColor DarkCyan
    
    $aktuelleErgebnisse = Start-DateiSuche -FolderPath $BasisSuchordner -SearchTerm $suche.Begriff -FileTypes $suche.Typen -Tag $suche.Tag -SkipStandardFolders:$UeberspringeStandardOrdner -ErrorAction SilentlyContinue
    
    if ($aktuelleErgebnisse.Count -gt 0) {
        $alleGesammeltenErgebnisse += $aktuelleErgebnisse
        Write-Host "  [ERFOLG] $($aktuelleErgebnisse.Count) Treffer gefunden und hinzugefügt." -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Keine Treffer gefunden." -ForegroundColor Gray
    }
}

# Aggregierte Berichterstellung
Write-Host "===========================================================" -ForegroundColor DarkYellow
Write-Host "            Verarbeitung der Gesamtergebnisse" -ForegroundColor DarkCyan
Write-Host "===========================================================" -ForegroundColor DarkYellow

if ($alleGesammeltenErgebnisse.Count -gt 0) {
    Write-Host "Insgesamt $($alleGesammeltenErgebnisse.Count) Treffer aus allen Läufen gesammelt." -ForegroundColor DarkCyan

    # NEU: Zentrale Aufbereitung der Daten für den Export und die Anzeige
    Write-Host "Bereite Daten für Export und Anzeige vor (kürze lange Zeilen)..." -ForegroundColor DarkCyan
    $ergebnisseFuerAnzeige = $alleGesammeltenErgebnisse | Select-Object Tag, Suchbegriff, Dateipfad, Zeilennummer, @{
        Name       = 'Zeileninhalt'
        Expression = {
            if ($_.Zeileninhalt.Length -gt 220) { 
                $_.Zeileninhalt.Substring(0, 220) + '...' 
            } else { 
                $_.Zeileninhalt 
            }
        }
    }

    # CSV-Export mit den gekürzten Daten
    if (-not (Test-Path $AggregierterAusgabeordner -PathType Container)) { 
        New-Item -Path $AggregierterAusgabeordner -ItemType Directory -Force | Out-Null
    }
    $aggCsvPfad = Join-Path -Path $AggregierterAusgabeordner -ChildPath "AggregierteErgebnisse_$($steuerungsLaufId).csv"
    Write-Host "Exportiere aggregierte Ergebnisse nach CSV: '$aggCsvPfad'" -ForegroundColor DarkCyan
    try {
        $ergebnisseFuerAnzeige | Export-Csv -Path $aggCsvPfad -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-Host "[ERFOLG] CSV-Export abgeschlossen." -ForegroundColor Green
    } catch {
        Write-Host "[FEHLER] CSV-Export fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Finale GridView-Anzeige mit den gekürzten Daten
    Write-Host "Zeige alle $($ergebnisseFuerAnzeige.Count) Treffer in einem finalen GridView an..." -ForegroundColor DarkCyan
    $ergebnisseFuerAnzeige | Out-GridView -Title "Gesamtergebnisse - Alle Läufe (ID: $steuerungsLaufId)"

} else {
    Write-Host "[INFO] In keinem der Suchläufe wurden Treffer gefunden." -ForegroundColor Yellow
}

Write-Host "===========================================================" -ForegroundColor DarkYellow
Write-Host "                    over and out" -ForegroundColor DarkCyan
Write-Host "===========================================================" -ForegroundColor DarkYellow


































































































