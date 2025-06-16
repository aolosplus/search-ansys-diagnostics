Okay, I will reformat the documentation with a line break after approximately 91 characters,
while trying to maintain readability and markdown integrity. Code blocks will not be
reformatted internally. The 
markers will be removed.

# Documentation: Search And Destroy  Script

**Version:** 3.12.7 - finale+ (as of 12.06.2025)
**Author:** AO (and Gemini 2.5 Bro)

## 1. Overview

The "Search And Destroy" script is a powerful  tool designed to automate the
process of searching for specific terms and patterns within files across a directory
structure. It performs a series of predefined search operations, aggregates all findings,
exports them to a consolidated CSV file, and presents them in an interactive GridView for
easy analysis. The script is particularly tailored for analyzing diagnostic files, with
specific configurations geared towards Ansys-related information, but can be adapted for
general-purpose log file analysis.

## 2. Purpose

The primary goal of this script is to:

1.  **Automate Repetitive Searches:** Define common search queries once and execute them in
    batch.
2.  **Centralize Findings:** Collect results from multiple search criteria and numerous files
    into a single dataset.
3.  **Standardize Output:** Provide results in a structured CSV format for record-keeping,
    sharing, or further processing.
4.  **Facilitate Analysis:** Offer an immediate, filterable, and sortable view of the
    findings using 's `Out-GridView` cmdlet.
5.  **Improve Efficiency:** Significantly reduce the manual effort required to sift through
    large volumes of text-based files for specific information.

## 3. Features

*   **Configurable Search Directory:** Specify a base folder for all search operations.
*   **Configurable Output Directory:** Define where the aggregated CSV report will be saved.
*   **Predefined Search Definitions:** A flexible array (`$Suchdefinitionen`) allows users to
    specify multiple search terms, associated tags (for categorization), and target file
    types.
*   **Selective Folder Skipping:** Option to exclude common, potentially noisy folders like
    'tomcat' or 'logs' from searches (customizable).
*   **Recursive Searching:** Scans through subdirectories of the base search folder.
*   **File Type Filtering:** Searches can be limited to specific file extensions (e.g.,
    `*.txt`, `*.log`, `*.ini`).
*   **Detailed Console Output:** Provides real-time feedback on search progress, number of
    hits, and specific matches found.
*   **Aggregated CSV Export:** All findings are compiled into a single CSV file, including:
    *   Timestamp of the search
    *   A unique ID for the overall script run
    *   Tag associated with the search definition
    *   The search term used
    *   Full path to the file containing the match
    *   Filename
    *   Line number of the match
    *   The content of the line containing the match (truncated for display/CSV if too
        long).
*   **Interactive GridView Display:** Presents the aggregated results in a user-friendly,
    sortable, and filterable window.
*   **Error Handling:** Includes basic error suppression for file access issues and a
    try-catch block for CSV export.
*   **Timestamped Results:** Both individual search hits (within the function, though not
    directly exposed in the final CSV's `SuchZeitstempel` which uses the main run's start)
    and the aggregated CSV file are timestamped for easy identification. The `SuchlaufID`
    in the CSV is actually the timestamp of when that specific search *within the loop*
    started, while the CSV filename uses `$steuerungsLaufId` which is the timestamp of the
    *entire script execution*.

## 4. Prerequisites

*   **:** Version 3.0 or higher (due to `[CmdletBinding()]`, `[PSCustomObject]`,
    and `Out-GridView`). Modern  (5.1 or 7+) is recommended.
*   **Permissions:** Read access to the `$BasisSuchordner` and its subdirectories. Write
    access to the `$AggregierterAusgabeordner` to create the CSV file.

## 5. Configuration

The script's behavior is primarily controlled by variables defined at the beginning:

### 5.1. Core Paths

```
$BasisSuchordner =           "C:\user\root\s\"
$AggregierterAusgabeordner = "C:\user\root\s\"




Markdown


$BasisSuchordner: (String) The root directory where the script will start
searching for files. All searches are recursive from this point.

Example: If set to "D:\Ansys_Diagnostics\", the script will look in this
folder and all its subfolders.

$AggregierterAusgabeordner: (String) The directory where the consolidated CSV
report (AggregierteErgebnisse_*.csv) will be saved. If the directory doesn't exist,
the script will attempt to create it.

Example: If set to "C:\Reports\Search_Results\".

5.2. Optional Folder Skipping
[switch]$UeberspringeStandardOrdner = $true







$UeberspringeStandardOrdner: (SwitchParameter) If set to $true (default in the
provided snippet), the script will skip searching files located in any directory whose
name is 'tomcat' or 'logs'. This is applied by checking if any segment of the file's
directory path matches these names.

To disable this, change to $UeberspringeStandardOrdner = $false or remove/comment
out the line.

The folders to skip ("tomcat", "logs") are hardcoded within the
Start-DateiSuche function.

5.3. Search Definitions ($Suchdefinitionen)

This is the most critical part of the configuration. It's an array of hashtables, where
each hashtable defines a specific search operation.

$Suchdefinitionen = @(
    @{ Begriff = "OS Version:";      Tag = "Betriebssys";       Typen = "*.txt" },
    @{ Begriff = "hostname";         Tag = "Hostname";          Typen = "*.txt" },
    # ... more definitions
)







Each hashtable within the array can have the following keys:

Begriff: (String) The actual text string or pattern to search for within files.
Select-String uses this with -SimpleMatch, meaning it's a literal string search,
not a regular expression by default in this script's usage.

Example: "Error", "ANSYS License Manager", "1055@".

Tag: (String) A descriptive label or category for this specific search. This tag
will appear in the output CSV and GridView, helping to group and identify the context
of the findings.

Example: "Betriebssys", "Lizenz-Flex", "Fehler-Log".

Typen: (String or String Array) Specifies the file extensions to include in this
particular search.

Can be a single string: Typen = "*.txt"

Can be an array of strings for multiple types: Typen = @("*.log", "*.txt", "*.ini")

If omitted for a definition, the Start-DateiSuche function defaults to *.ini, *.txt, *.lic, *.log, *.nfo, *.opt.

Example of a single search definition:

@{
    Begriff = "FLEXLM";         # Search for the literal string "FLEXLM"
    Tag     = "Lizenz-Flex";    # Categorize findings with this tag
    Typen   = @("*.txt", "*.log") # Search only in .txt and .log files
}







To add a new search, simply add a new hashtable entry to the $Suchdefinitionen array
following this structure.

6. Script Workflow and Components

The script operates in two main parts:

6.1. Part 1: Start-DateiSuche Function (Core Search Function)

This function is the workhorse responsible for performing a single, defined search
operation.

Parameters:

[string]$FolderPath: (Mandatory) The base directory for this specific search (passed
from $BasisSuchordner).

[string]$SearchTerm: (Mandatory) The string to search for (from $suche.Begriff).

[string[]]$FileTypes: The file extensions to include (from $suche.Typen). If not
provided, defaults to *.ini, *.txt, *.lic, *.log, *.nfo, *.opt.

[switch]$CaseSensitive: A switch to enable case-sensitive searching. Note: While
defined, this parameter is not explicitly used when Start-DateiSuche is called in
the main script, so searches are case-insensitive by default due to Select-String's
default behavior.

[switch]$SkipStandardFolders: If present, activates the logic to skip 'tomcat' and
'logs' folders.

[string]$Tag: The tag associated with this search (from $suche.Tag).

Logic:

Initialize: Creates an empty array $ergebnisseZumExport to store results.

Determine File Types: Sets $erlaubteErweiterungen based on the FileTypes
parameter or the default list.

Gather Files: Uses Get-ChildItem -Recurse -File -Include $erlaubteErweiterungen
to get all relevant files in the $FolderPath. Errors during file enumeration are
silently continued.

Filter Standard Folders (if $SkipStandardFolders is present):

It iterates through the gathered files.

For each file, it splits its DirectoryName (full path to the parent folder) into
individual folder name components.

It checks if any of these components match "tomcat" or "logs".

If no match is found in the path components, the file is kept for searching.

Verbose messages indicate the filtering process and counts.

Perform Search: If there are files to search, it pipes them to Select-String -Pattern $SearchTerm -SimpleMatch -ErrorAction SilentlyContinue.

-SimpleMatch ensures the $SearchTerm is treated as a literal string.

-CaseSensitive:$CaseSensitive would control case sensitivity if the switch was
actively passed and set.

Process Results: If Select-String finds matches:

It generates a suchlaufId (timestamp for this specific search instance) and a
human-readable timestamp.

It prints the number of hits and details for each hit (File Path, Line Number, Line
Content) to the console.

For each hit, it creates a PSCustomObject containing:

SuchZeitstempel: Human-readable timestamp of when this search was processed.

SuchlaufID: Timestamp-based ID for this specific call to Start-DateiSuche.

Tag: The provided tag.

Suchbegriff: The search term used.

Dateipfad: Full path to the matched file.

Dateiname: Name of the matched file.

Zeilennummer: Line number of the match.

Zeileninhalt: The full content of the matched line.

These objects are added to $ergebnisseZumExport.

Return: Returns the array of PSCustomObject results.

6.2. Part 2: Main Control Script and Aggregation

This part orchestrates the overall process.

Logic:

Initialization:

Generates a $steuerungsLaufId (timestamp for the entire script execution).

Initializes an empty array $alleGesammeltenErgebnisse to store results from all
search definitions.

Prints a script header and an informational message if standard folders are being
skipped.

Iterate Through Search Definitions:

It loops through each hashtable ($suche) in the $Suchdefinitionen array.

For each $suche:

Prints a message indicating the start of the search for $suche.Begriff with
its $suche.Tag.

Calls Start-DateiSuche with parameters derived from the current $suche
definition, $BasisSuchordner, and the global $UeberspringeStandardOrdner
switch.

If Start-DateiSuche returns any results, they are appended to the
$alleGesammeltenErgebnisse array.

Prints a success or "no hits" message for the current search.

Aggregated Reporting:

Prints a section header for result processing.

Check for Results: If $alleGesammeltenErgebnisse contains any items:

Prints the total number of hits across all searches.

Data Preparation for Display/Export:

Creates $ergebnisseFuerAnzeige by selecting specific properties from
$alleGesammeltenErgebnisse.

Crucially, it truncates the Zeileninhalt property: if a line's content is
longer than 220 characters, it's shortened to 220 characters followed by
"...". This is done to keep the CSV and GridView manageable.

CSV Export:

Checks if $AggregierterAusgabeordner exists; if not, creates it.

Constructs the CSV file path:
$AggregierterAusgabeordner\AggregierteErgebnisse_$steuerungsLaufId.csv.

Exports $ergebnisseFuerAnzeige to this CSV file using Export-Csv -NoTypeInformation -Encoding UTF8.

Includes a try-catch block to handle potential errors during CSV export.

GridView Display:

Pipes $ergebnisseFuerAnzeige to Out-GridView with a title that includes
the $steuerungsLaufId. This provides an interactive window to view, sort,
and filter the results.

No Results: If no hits were found in any search, an informational message is
displayed.

Completion: Prints a script footer.

7. Output

The script produces several forms of output:

Console Output:

Headers and footers for script start/end and sections.

Status messages for each search definition being processed.

If $UeberspringeStandardOrdner is $true, an info message is shown.

If $UeberspringeStandardOrdner is $true and verbose output is enabled (e.g., by
running the script with -Verbose), details about file filtering will be shown.

For each search term that yields results:

A count of treffers.

For each treffer:

File path (highlighted).

Line number and trimmed line content.

Status messages for CSV export (success or failure).

Message indicating the GridView is being displayed.

CSV File:

Naming: AggregierteErgebnisse_YYYYMMDD_HHMMSS.csv (e.g.,
AggregierteErgebnisse_20250612_153045.csv), where the timestamp is from
$steuerungsLaufId.

Location: Saved in the $AggregierterAusgabeordner.

Encoding: UTF-8.

Content: A table with the following columns (derived from
$ergebnisseFuerAnzeige):

Tag: The tag from the search definition.

Suchbegriff: The search term used.

Dateipfad: Full path to the file.

Zeilennummer: Line number of the match.

Zeileninhalt: The content of the matched line (truncated to 220 characters +
"..." if longer).

Out-GridView Window:

Title: "Gesamtergebnisse - Alle Läufe (ID: YYYYMMDD_HHMMSS)"

Content: An interactive table displaying the same data as in
$ergebnisseFuerAnzeige (and thus the CSV). Users can:

Sort by any column by clicking its header.

Filter results using the "Filter" box (supports simple text matching and
criteria like ColumnName:Value).

Select and copy rows.

8. How to Use

Save the Script: Save the code as a .ps1 file (e.g., SearchAndDestroy.ps1).

Configure:

Open the script in a text editor or  ISE.

Modify $BasisSuchordner to point to the directory you want to search.

Modify $AggregierterAusgabeordner to your desired output location for the CSV.

Adjust $UeberspringeStandardOrdner if needed ($true to skip 'tomcat'/'logs',
$false to include them).

Carefully review and customize the $Suchdefinitionen array to match your search
requirements. Add, remove, or modify entries as needed.

Run the Script:

Open a  console.

Navigate to the directory where you saved the script.

Execute the script: .\SearchAndDestroy.ps1

To enable verbose messages (e.g., for folder skipping details):
.\SearchAndDestroy.ps1 -Verbose

Review Results:

Observe the console output for real-time progress.

Once completed, check the $AggregierterAusgabeordner for the generated CSV file.

Interact with the Out-GridView window that appears to analyze the findings.

9. Customization and Extension

Adding New Searches: The primary way to customize is by adding new hashtable entries
to the $Suchdefinitionen array.

Modifying Skipped Folders: To change which folders are skipped by
$UeberspringeStandardOrdner, modify the hardcoded array $ordnerZumUeberspringen = @("tomcat", "logs") within the Start-DateiSuche function.

Case Sensitivity: To enable case-sensitive search for specific definitions, you
would need to:

Add a CaseSensitive = $true key-value pair to the relevant hashtable in
$Suchdefinitionen.

Modify the call to Start-DateiSuche to pass this:
... -CaseSensitive:$($suche.ContainsKey('CaseSensitive') -and $suche.CaseSensitive)

Regular Expressions: If you need more complex pattern matching, Select-String can
use regular expressions. You would remove -SimpleMatch from the Select-String
command in Start-DateiSuche. Ensure your Begriff values in $Suchdefinitionen are
then valid regex patterns.

Line Truncation Length: The 220-character limit for Zeileninhalt in the output is
hardcoded. If you need more or less context, change 220 in this section:

if ($_.Zeileninhalt.Length -gt 220) {
    $_.Zeileninhalt.Substring(0, 220) + '...'
} # ...







Default File Types: The default extensions used in Start-DateiSuche if
$FileTypes is not provided can be changed by editing $standardErweiterungen = @("*.ini", "*.txt", "*.lic", "*.log", "*.nfo", "*.opt").

10. Important Notes and Considerations

Performance: Searching through very large directories or a vast number of files can
be time-consuming and resource-intensive. The script's performance will depend on disk
speed, CPU, and the complexity/number of searches.

Error Handling: The script uses -ErrorAction SilentlyContinue for Get-ChildItem
and Select-String. This means that if it encounters files it cannot access or read,
it will skip them without halting the script. The CSV export has a basic try-catch
block. For more robust error logging, these would need to be expanded.

Memory Usage: Aggregating all results in memory ($alleGesammeltenErgebnisse) can
be memory-intensive if millions of hits are found. For extremely large datasets, a
streaming approach or database storage might be more appropriate.

$UeberspringeStandardOrdner Logic: The folder skipping logic checks if any part
of the directory path contains "tomcat" or "logs". For example,
C:\data\mytomcat_backup\file.txt would be skipped, not just files directly under a
folder named tomcat.

Specificity of "Ansys-Diags": The script mentions being "sehr auf die Ansys-Diags
angepasst." This is reflected in the default $Suchdefinitionen (e.g., "ANSYS",
"FLEXLM", specific ports). For general use, these definitions should be thoroughly
reviewed and adapted.

Select-String -SimpleMatch: This is used for performance and simplicity, treating
search terms literally. If regex is needed, this flag must be removed, and search
terms must be valid regex patterns.

No Case Sensitivity by Default in Main Loop: As noted, the -CaseSensitive
parameter of Start-DateiSuche is defined but not actively used by the main loop
calling it. Select-String is case-insensitive by default.

11. Troubleshooting

No Results Found:

Verify $BasisSuchordner is correct.

Check if the search terms (Begriff) exist in the files and match exactly
(considering case if Select-String were made case-sensitive).

Ensure the Typen (file extensions) are correct for the files you expect to find
matches in.

If $UeberspringeStandardOrdner is $true, ensure target files are not in folders
named 'tomcat' or 'logs' (or subfolders of such).

Access Denied Errors (if -ErrorAction SilentlyContinue was removed): Run
 as an Administrator, or ensure the user running the script has read
permissions for all target files/folders.

CSV File Not Created:

Check for error messages in the console regarding CSV export.

Ensure you have write permissions to $AggregierterAusgabeordner.

GridView Doesn't Appear: This is unlikely unless there's a fundamental 
issue or $alleGesammeltenErgebnisse is empty. Check console for errors.

This detailed documentation should provide a solid understanding of the "Search And Destroy"
script, its capabilities, configuration, and usage.



