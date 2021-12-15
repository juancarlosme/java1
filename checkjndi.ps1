<#

.Description
Scans filesystem for .jar, war, and ear files that contains log4j code that may be vulnerable to CVE-2021-44228
Supply a top-level directory to begin searching, or default to the current directory.

.PARAMETER Toplevel
Top-level directory to begin search for jar files.

.EXAMPLE
PS> .\checkjindi.ps1
Scan the current directory and subdirectory for jar files.

.EXAMPLE
PS> .\checkjindi.ps1 c:\
Scan the entire c:\ drive for jar files.

.SYNOPSIS
Scans filesystem for .jar files that contains log4j code that may be vulnerable to CVE-2021-44228.
#>

param ([string]$toplevel)
Add-Type -Assembly 'System.IO.Compression.FileSystem'

function Get-JARs {
    param (
        [string]$topdir
    )

    $jars = Get-ChildItem -Path $topdir -Recurse -Force -Include "*.jar","*.war","*.ear" -ErrorAction Ignore;

    return $jars
}

function Process-JAR {
    param (
        [Object]$jarfile,
        [String]$origfile = "",
        [String]$subjarfile = ""
    )
    $jar = [System.IO.Compression.ZipFile]::Open($jarfile, 'read');

    ForEach ($entry in $jar.Entries) {
        #Write-Output $entry.Name;
        if($entry.Name -like "*JndiLookup.class"){
            if($origfile -eq "")
            {
                Write-Output "$jarfile contains $entry";
            }
            else
            {
                Write-Output "$origfile contains $subjarfile contains $entry";
            }
        }
        elseif (($entry.Name -like "*.jar") -or ($entry.Name -like "*.war") -or ($entry.Name -like "*.ear")) {
            if($origfile -eq "")
            {
                $origfile = $jarfile.FullName
            }
            $TempFile = New-TemporaryFile
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $TempFile, $true);
            Process-JAR $TempFile $origfile $entry.FullName;
            Remove-Item $TempFile;

        }
    }
    $jar.Dispose();
}



$jarfiles = Get-JARs $toplevel;
ForEach ($jarfile In $jarfiles) {
    Process-JAR $jarfile;
}
