param (
        #===========================================================================================================================[ Input Parameters ]

            $LogName ,                         # location and name of the log file, if not specified, no logs will be generated

            $CSVFile ,                         # location and name of the CSV FILE containing the instructions for the migration

            $UserName ,                        # SharePoint User Name

            $Password ,                        # SharePoint Password

            $SiteUrl ,                         # URL of the Target WebSite (Top Level)

            [switch]$UseMFA ,                  # for MFA authenticated accounts, you WILL NEED to use this if you are account is not excluded from MFA authentication
                                               # a good practice for running automation scripts is to use Service Credential Accounts instead of your own user account,
                                               # yo may consider running your scripts without your own end user account to avoid MFA prompts and other issues, the second
                                               # and less recommended practice, is to modify the conditional access rules and add your own account to the list of
                                               # accounts being excluded from MFA prompts, this will will give you an easy to access cloud service but with less security

            [switch]$DoNotCreateLibraries ,    # will NOT CREATE SharePoint Document Libraries

            [switch]$DoNotCreateFolders ,      # will NOT CREATE SharePoint folders 

            [switch]$DoNotPerformUploads       # will NOT UPLOAD files to SharePoint (displays only the file name)

        #===========================================================================================================================[ End of the Input Parameters ]
)

<#
#  SPOPSM - SharePoint Online PowerShell Migrator
#  ==============================================
#
#  Version:       1.00
#
#  Author:   
#                 Alex Gonsales 
#                 agonsales@me.com
#                 19/Dec/2017
#
#  License:      
#                 MIT
#
#  Dependencies:
#
#                 1) Microsoft.Online.SharePoint.PowerShell - https://www.microsoft.com/en-us/download/details.aspx?id=35588
#                
#                 2) SharePointPnPPowerShell*  - https://github.com/SharePoint/PnP-PowerShell
#
#                 3) PSAlphaFS - https://github.com/v2kiran/PSAlphaFS
#
#  Notes:
#
#     The first dependency requires the manual download and installation of SharePoint Online PowerShell Module directly from Microsoft web site, the script 
#     will check for this dependency and report the requirement in case the module is not present on the machine where the script is being executed.
#
#     On the next version I will implement the capacity to have the script downloading and installing the SharePoint Online PowerShell Module, it is quite straigth-forward
#     and it shouldn't require a lot of time to implement this functionality, it is quite simple, I just can't afford the time right now :)
#
#     For the dependencies 2 and 3, the script will check and inform the user about the requirements, providing also the capacity to download and install the 
#     dependencies automatically after receving user confirmation.
#
#
#  Credits:
#
#
#	  * UploadFile()
#       ============
#
#       author: Microsoft SharePoint Team
#       source: https://docs.microsoft.com/en-us/sharepoint/dev/solution-guidance/upload-large-files-sample-app-for-sharepoint
#
#
#     * Get-ConsoleAsHtml()
#       ===================
#
#       author: Microsoft PowerShell Team
#       source:  https://blogs.msdn.microsoft.com/powershell/2009/01/11/colorized-capture-of-console-screen-in-html-and-rtf
#
#>

function Get-ConsoleAsHtml {

    # Check the host name and exit if the host is not the Windows PowerShell console host.

    if ($host.Name -ne 'ConsoleHost')
    {
      write-host -ForegroundColor Red "This script runs only in the console host. You cannot run this script in $($host.Name)."
      exit -1
    }

    # The Windows PowerShell console host redefines DarkYellow and DarkMagenta colors and uses them as defaults.
    # The redefined colors do not correspond to the color names used in HTML, so they need to be mapped to digital color codes.

    function Normalize-HtmlColor ($color)
    {
      if ($color -eq "DarkYellow") { $color = "#EEEDF0" }
      if ($color -eq "DarkMagenta") { $color = "#012456" }
      if ($color -eq "Green") { $color = "#00FF00" }
      return $color
    }

    # Create an HTML span from text using the named console colors.
    #
    function Make-HtmlSpan ($text, $forecolor = "DarkYellow", $backcolor = "DarkMagenta")
    {
      $forecolor = Normalize-HtmlColor $forecolor
      $backcolor = Normalize-HtmlColor $backcolor

      # You can also add font-weight:bold tag here if you want a bold font in output.
      return "<span style='font-family:Courier New;color:$forecolor;background:$backcolor'>$text</span>"
    }

    # Generate an HTML span and append it to HTML string builder
    #
    function Append-HtmlSpan
    {
      $spanText = $spanBuilder.ToString()
      $spanHtml = Make-HtmlSpan $spanText $currentForegroundColor $currentBackgroundColor
      $null = $htmlBuilder.Append($spanHtml)
    }

    # Append line break to HTML builder
    #
    function Append-HtmlBreak
    {
      $null = $htmlBuilder.Append("<br>")
    }

    # Initialize the HTML string builder.
    $htmlBuilder = new-object system.text.stringbuilder
    $null = $htmlBuilder.Append("<pre style='MARGIN: 0in 10pt 0in;line-height:normal';font-size:10pt>")

    # Grab the console screen buffer contents using the Host console API.
    $bufferWidth = $host.ui.rawui.BufferSize.Width
    $bufferHeight = $host.ui.rawui.CursorPosition.Y
    $rec = new-object System.Management.Automation.Host.Rectangle 0,0,($bufferWidth - 1),$bufferHeight
    $buffer = $host.ui.rawui.GetBufferContents($rec)

    # Iterate through the lines in the console buffer.
    for($i = 0; $i -lt $bufferHeight; $i++)
    {
      $spanBuilder = new-object system.text.stringbuilder

      # Track the colors to identify spans of text with the same formatting.
      $currentForegroundColor = $buffer[$i, 0].Foregroundcolor
      $currentBackgroundColor = $buffer[$i, 0].Backgroundcolor

      for($j = 0; $j -lt $bufferWidth; $j++)
      {
        $cell = $buffer[$i,$j]

        # If the colors change, generate an HTML span and append it to the HTML string builder.
        if (($cell.ForegroundColor -ne $currentForegroundColor) -or ($cell.BackgroundColor -ne $currentBackgroundColor))
        {
          Append-HtmlSpan

          # Reset the span builder and colors.
          $spanBuilder = new-object system.text.stringbuilder
          $currentForegroundColor = $cell.Foregroundcolor
          $currentBackgroundColor = $cell.Backgroundcolor
        }

        # Substitute characters which have special meaning in HTML.
        switch ($cell.Character)
        {
          '>' { $htmlChar = '&gt;' }
          '<' { $htmlChar = '&lt;' }
          '&' { $htmlChar = '&amp;' }
          default
          {
            $htmlChar = $cell.Character
          }
        }

        $null = $spanBuilder.Append($htmlChar)
      }

      Append-HtmlSpan
      Append-HtmlBreak
    }

    # Append HTML ending tag.
    $null = $htmlBuilder.Append("</pre>")

    return $htmlBuilder.ToString()

}

function Create-FolderHierarchy() {

    param
    (
      [Parameter(Mandatory=$true)] [Microsoft.SharePoint.Client.Folder]$TopFolder, 
      [Parameter(Mandatory=$true)] [String]$FolderUrl
    )

    $folderNames = $folderUrl.Trim().Split("/",[ System.StringSplitOptions]::RemoveEmptyEntries)
    $folderName = $folderNames[0]
    $currentFolder = $TopFolder.Folders.Add($folderName)
    
    $TopFolder.Context.Load($currentFolder)

    try {
        $TopFolder.Context.ExecuteQuery()
    }
    catch {
        return $false
    }

    if ($folderNames.Length -gt 1)
    {
        $currentFolderUrl = [System.String]::Join("/", $folderNames, 1, $folderNames.Length - 1)
        return Create-FolderHierarchy -TopFolder $currentFolder -FolderUrl $currentFolderUrl
    }

    try {
        $TopFolder.Context.ExecuteQuery()
        return $true
    }
    catch {
        return $false
    }
}

function ValidateName () {

    param
    (
      [Parameter(Mandatory=$true)] [string]$Value
      #[Parameter(Mandatory=$true)] [String]$Char     # -- future implementation
    )          
    return $Value -replace '(%20)|["?<>#%]', '_'      # -- for now I will replace the invalid CHARACTERS by an underline
}

function ValidateDocumentLibraryName () {

    param
    (
      [Parameter(Mandatory=$true)] [String]$Value 
      #[Parameter(Mandatory=$true)] [String]$Char     # -- future implementation
    )

    # differently from ValidateFileName(), we are including " " (space) in the search exppression,
    # you can ignore this function if you want Document Libraries and Folders with spaces
    # this function will is reserved for future additions and will be expanded

    return $Value -replace '(%20)|[ "?<>#%]', ''      # -- for now I will simply remove the invalid CHARACTERS (I prefer folders without spaces to minimize the length of the URL
}

function UploadFile() {

    param
    (
        [Parameter(Mandatory=$true)]  $ctx,
        [Parameter(Mandatory=$true)]  [String]$TargetLibraryName,
        [Parameter(Mandatory=$false)] [String]$TargetFolderName,
        [Parameter(Mandatory=$true)]  [String]$SourceFileName,
        [Parameter(Mandatory=$true)]  [String]$NewFileName
    )
    
    $fileChunkSizeInMB = 10
        
    $uploadID = [GUID]::NewGuid()    

    $uniqueFileName = [System.IO.Path]::GetFileName($NewFileName)   #$uniqueFileName = [System.IO.Path]::GetFileName($SourceFileName)

    #
    # Get the folder to upload into. 
    #

    $targetList = $ctx.Web.Lists.GetByTitle($TargetLibraryName)
    $ctx.Load($targetList.RootFolder)

    try{
        $ctx.ExecuteQuery()
    }
    catch {
        Write-Host "`n`n- Error in UploadFile(): "  ($_.Exception.Message -replace 'Exception calling \"ExecuteQuery\" with \"0\" argument\(s\)\: ','') `n         -ForegroundColor Red
    }

    if ($TargetFolderName.Length -eq 0) 
    {
        $destination = $ctx.Web.GetFolderByServerRelativeUrl($targetList.RootFolder.ServerRelativeUrl)
    }
    else
    {
        #if ($TargetFolderName.Length -gt 0)
        #{
        #    if ($TargetFolderName.Substring(0,1) -eq '/')
        #    {
        #        $TargetFolderName = $TargetFolderName.Remove(0,1)
        #    }
        #}
        $destination = $ctx.Web.GetFolderByServerRelativeUrl($TargetFolderName)   # $targetList.RootFolder.ServerRelativeUrl + '/' + $TargetFolderName
    }    

    $ctx.Load($destination)
    $ctx.ExecuteQuery()

    # File object

    [Microsoft.SharePoint.Client.File] $uploadOperation

    $blockSize = $fileChunkSizeInMB * 1024 * 1024

    $fileSize = (Get-LongItem $SourceFileName).length

    if ($fileSize -le $blockSize)
    {
        try
        {
            # -- let's process a file smaller than $fileChunkSizeInMB (right now 10MB)

            $fileSourceStream_Small = New-Object IO.FileStream($SourceFileName, [System.IO.FileMode]::Open)

            $fileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
            $fileCreationInfo.ContentStream = $fileSourceStream_Small
            $fileCreationInfo.Overwrite = $true        
            $fileCreationInfo.URL = $uniqueFileName

            $uploadOperation = $destination.Files.Add($fileCreationInfo)

            $ctx.Load($uploadOperation)
            $ctx.ExecuteQuery()
        }
        catch
        {
            Write-Host "`n- Error opening '$SourceFile'" -ForegroundColor Red
            Write-Host "- Possible cause: UNC Path is too long and FileStream() function can't handle. `n" -ForegroundColor Red
            $fileStream.Close()
            $fileStream.Dispose()
        }

        return $uploadOperation
    }
    else
    {
        $bytesUploaded = $null
        $fileSourceStream = $null

        $lastBuffer = $null
        $fileOffset = 0
        $totalBytesRead = 0

        $bytesRead = $null
        $first = $true
        $last = $false

        $temp_CurrentBytes = 0
        $temp_TotalToGo = 0

        try
        {
            $fileSourceStream = [System.IO.File]::Open($SourceFileName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)

            $binaryReader = New-Object System.IO.BinaryReader($fileSourceStream)
            $buffer = New-Object System.Byte[]($blockSize)

            while(($bytesRead = $binaryReader.Read($buffer, 0, $buffer.Length)) -gt 0) 
            {
                $totalBytesRead = $totalBytesRead + $bytesRead

                $temp_CurrentBytes = [math]::Round($totalBytesRead / 1048576, 1)
                $temp_TotalToGo = [math]::Round($fileSize / 1048576, 1)

                Write-Progress -Activity "Uploading: $uniqueFileName" -Status "Current: $temp_CurrentBytes MB of $temp_TotalToGo MB" -PercentComplete ($totalBytesRead / $fileSize * 100) -Id 2

                if($totalBytesRead -eq $fileSize) 
                {
                    $last = $true
                    $lastBuffer = New-Object System.Byte[]($bytesRead)

                    [array]::Copy($buffer, 0, $lastBuffer, 0, $bytesRead)
                }

                If($first)
                {
                    $ContentStream = New-Object System.IO.MemoryStream

                    $fileInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation

                    $fileInfo.ContentStream = $ContentStream                    
                    $fileInfo.Overwrite = $true
                    $fileInfo.Url = $uniqueFileName

                    $uploadOperation = $destination.Files.Add($fileInfo)
                    $ctx.Load($uploadOperation)

                    $stream = [System.IO.MemoryStream]::new($buffer) 

                    $bytesUploaded = $uploadOperation.StartUpload($uploadID, $stream)
                    $ctx.ExecuteQuery()

                    $fileOffset = $bytesUploaded.Value
                    $first = $false
                }
                else
                {
                    $uploadOperation = $ctx.Web.GetFileByServerRelativeUrl($destination.ServerRelativeUrl + '/' + $uniqueFileName)

                    If($last) 
                    {
                        $stream = [System.IO.MemoryStream]::new($lastBuffer)

                        $uploadOperation = $uploadOperation.FinishUpload($uploadID, $fileOffset, $stream)
                        $ctx.ExecuteQuery()

                        $uploadOperation = $null
                        $uploadOperation = $ctx.Web.GetFileByServerRelativeUrl($destination.ServerRelativeUrl + '/' + $uniqueFileName)
                        $ctx.Load($uploadOperation)
                        $ctx.ExecuteQuery()

                        # File upload complete

                        Write-Progress -Activity "Uploading: $uniqueFileName" -Status "Done" -PercentComplete 100 -Id 2 -Completed

                        return $uploadOperation
                    }
                    else 
                    {
                        $stream = [System.IO.MemoryStream]::new($buffer)

                        $bytesUploaded = $uploadOperation.ContinueUpload($uploadID, $fileOffset, $stream)
                        $ctx.ExecuteQuery()

                        $fileOffset = $bytesUploaded.Value
                    }
                }

            }
        }

        catch 
        {
            Write-Host ""
            Write-Host "- Upload error: "  ($_.Exception.Message -replace 'Exception calling \"ExecuteQuery\" with \"0\" argument\(s\)\: ','') `n  -ForegroundColor Red
            #$fileSourceStream.Dispose()
            #$fileSourceStream.Close()
        }

        finally 
        {
            if ($fileSourceStream -ne $null)
            {
                Write-Progress -Activity "Uploading: $uniqueFileName" -Status "Done" -PercentComplete 100 -Id 2 -Completed
                #$fileSourceStream.Dispose()
                #$fileSourceStream.Close()
            }
        }

    }

    return $null
}

function OperationReport() {

    param
    (
        [Parameter(Mandatory=$true)] $TimeStart,

        [Parameter(Mandatory=$true)] $SourceName,
        [Parameter(Mandatory=$true)] $SourceFolder,
        [Parameter(Mandatory=$true)] $WebSiteName,
        [Parameter(Mandatory=$true)] $DocumentLibrary,

        [Parameter(Mandatory=$false)] $FilesTotal = 0,
        [Parameter(Mandatory=$false)] $FoldersTotal = 0,
        
        [Parameter(Mandatory=$false)] $FilesFailures = 0,
        [Parameter(Mandatory=$false)] $FoldersFailures = 0,

        [Parameter(Mandatory=$false)] $FilesRenamed = 0,
        [Parameter(Mandatory=$false)] $FoldersRenamed = 0,

        [Parameter(Mandatory=$false)] $FilesSkipped = 0
    )

    $timeEnd = (Get-Date)

    $timeDiff = New-TimeSpan $timeStart $timeEnd

    if ($timeDiff.Seconds -lt 0) 
    {
	    $hrs  = ($timeDiff.Hours) + 23
	    $mins = ($timeDiff.Minutes) + 59
	    $secs = ($timeDiff.Seconds) + 59 
    }
    else 
    {
	    $hrs  = $timeDiff.Hours
	    $mins = $timeDiff.Minutes
	    $secs = $timeDiff.Seconds 
    }

    $difference = '{0:00}:{1:00}:{2:00}' -f $hrs,$mins,$secs

    $a = "{0,31}" -f "Completed operation for: "    
    $b = "{0,31}" -f           "Source Folder: "    
    $c = "{0,31}" -f                 "WebSite: "    
    $d = "{0,31}" -f        "Document Library: "   
    
    $e = "{0,31}" -f             "Total Files: "
    $f = "{0,31}" -f           "Total Folders: "
    
    $g = "{0,31}" -f          "Files Failures: "
    $h = "{0,31}" -f        "Folders Failures: "
    
    $i = "{0,31}" -f           "Files Renamed: "
    $j = "{0,31}" -f         "Folders Renamed: "
    
    $k = "{0,31}" -f           "Files Skipped: "

    $l = "{0,31}" -f  "Operation completed at: "
    $m = "{0,31}" -f        "Total time spent: "

    "`n `n"

    Write-Host $a                   -ForegroundColor Green -NoNewline 
    Write-Host $SourceName          -ForegroundColor Yellow

    Write-Host $b                   -ForegroundColor Green -NoNewline 
    Write-Host $SourceFolder        -ForegroundColor Yellow

    Write-Host $c                   -ForegroundColor Green -NoNewline 
    Write-Host $WebSiteName         -ForegroundColor Yellow

    Write-Host $d                   -ForegroundColor Green -NoNewline 
    Write-Host $DocumentLibrary `n  -ForegroundColor Yellow
    
    Write-Host $e                   -ForegroundColor Green -NoNewline 
    Write-Host $FilesTotal          -ForegroundColor Yellow

    Write-Host $f                   -ForegroundColor Green -NoNewline 
    Write-Host $FoldersTotal `n     -ForegroundColor Yellow
    
    Write-Host $g                   -ForegroundColor Green -NoNewline 
    Write-Host $FilesFailures       -ForegroundColor Yellow

    Write-Host $h                   -ForegroundColor Green -NoNewline 
    Write-Host $FoldersFailures `n  -ForegroundColor Yellow
    
    Write-Host $i                   -ForegroundColor Green -NoNewline 
    Write-Host $FilesRenamed        -ForegroundColor Yellow

    Write-Host $j                   -ForegroundColor Green -NoNewline 
    Write-Host $FoldersRenamed `n   -ForegroundColor Yellow
    
    Write-Host $k                   -ForegroundColor Green -NoNewline 
    Write-Host $FilesSkipped `n     -ForegroundColor Yellow
   
    Write-Host $l                   -ForegroundColor Green -NoNewline 
    Write-Host $timeEnd             -ForegroundColor Yellow

    Write-Host $m                   -ForegroundColor Green -NoNewline 
    Write-Host $difference          -ForegroundColor Yellow


    " "
    "_"*$Host.UI.RawUI.BufferSize.Width    
    " "
}


# ================================================================================================
# ==========================================================================[ STARTING POINT ]====
# ================================================================================================

cls


#
#   Check module dependencies
#


# ======================  Microsoft.Online.SharePoint.PowerShell


if ( (Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable).Name.Length -eq 0 )
{
    Write-Host "SharePoint Online Management Shell not found!"
    Write-Host "Download and install the SharePoint Online Management Shell from https://www.microsoft.com/en-us/download/details.aspx?id=35588"
    Write-Host "It might be necessary to restart your computer once you have completed the installation. `n"
    exit
}
else
{
    Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking 
}


# ======================  SharePointPnPPowerShellOnline


if ( (Get-Module -Name SharePointPnPPowerShellOnline -ListAvailable | ? Version -eq "2.23.1802.0").Name.Length -eq 0 )
{
    try 
    {
        Write-Host "PowerShell module 'SharePointPnPPowerShellOnline' version 2.23.1802.0  not found!"
        Write-Host "The module is available at https://github.com/SharePoint/PnP-PowerShell/releases/tag/2.23.1802.0"  
        Write-Host "The script will try to install this module, once installed, the script will continue.`n"

        Write-Host "- Trying to install PowerShell module 'SharePointPnPPowerShellOnline' version 2.23.1802.0  ... `n " -ForegroundColor Yellow
             
        Install-Module SharePointPnPPowerShellOnline -RequiredVersion 2.23.1802.0 -SkipPublisherCheck -AllowClobber -Force        
        Write-Host "- Module succesfully intalled! `n " -ForegroundColor Yellow

        Write-Host "- Loading module ... `n " -ForegroundColor Yellow
        Import-Module SharePointPnPPowerShellOnline -RequiredVersion 2.23.1802.0 -DisableNameChecking -ErrorAction Stop
    }
    catch 
    {
        Write-Host "Error while trying to install PowerShell module 'SharePointPnPPowerShellOnline'!"
        Write-Host "The module is also available at https://github.com/SharePoint/PnP-PowerShell/releases/tag/2.23.1802.0  `n"
        exit
    }    
}
else 
{
    try 
    {
        Import-Module SharePointPnPPowerShellOnline -RequiredVersion 2.23.1802.0 -DisableNameChecking -ErrorAction Stop
    }
    catch
    {
        Write-Host "`nPowerShell module 'SharePointPnPPowerShellOnline' not loaded!"
        Write-Host "Check if your computer has the correct PowerShell module properly installed before running the script."
        Write-Host "The script requires SharePointPnPPowerShellOnline version 2.23.1802.0 "  
        Write-Host "The module is available at https://github.com/SharePoint/PnP-PowerShell/releases/tag/2.23.1802.0  `n"  
        exit
    }
}


# ======================  PSAlphaFS 


if ( (Get-Module -Name PSAlphaFS -ListAvailable | ? Version -eq "2.0.0.1").Name.Length -eq 0 )
{
    try 
    {
        Write-Host "PowerShell module PSAlphaFS version 2.0.0.1  not found!"
        Write-Host "The module is available at https://www.powershellgallery.com/packages/PSAlphaFS/2.0.0.1 "  
        Write-Host "The script will try to install this module, once installed, the script will continue.`n"

        Write-Host "- Trying to install PowerShell module 'PSAlphaFS version 2.0.0.1' ... `n " -ForegroundColor Yellow
             
        Install-Module -Name PSAlphaFS -RequiredVersion 2.0.0.1 -SkipPublisherCheck -AllowClobber -Force
        Write-Host "- Module succesfully intalled! `n " -ForegroundColor Yellow

        Write-Host "- Loading module ... `n " -ForegroundColor Yellow
        Import-Module -Name PSAlphaFS -RequiredVersion 2.0.0.1 -Force -ErrorAction Stop
    }
    catch 
    {
        Write-Host "`nError while trying to install PowerShell module 'PSAlphaFS'!"
        Write-Host "Check your connectivity to the Internet, this script is trying to connect to the PowerShell Online Gallery "
        Write-Host "The module is available at https://www.powershellgallery.com/packages/PSAlphaFS/2.0.0.1  `n"  
        break
    }
}


#
#  Input Parameters Validation
#

if ($SiteUrl -eq $null) 
{
    Write-Host "`n- Error, no URL provided!" -ForegroundColor Red
    Write-Host "- You need to specify the parameter '-SiteUrl' along with a valid URL, example: -SiteUrl https://domainname.sharepoint.com/sites/XYZ `n" -ForegroundColor Red
    break
}
else
{
    if ($SiteUrl.EndsWith('/')) 
    {
        $SiteUrl = $SiteUrl.Substring(0,$SiteUrl.Length-1)
    }
}

#
#  Defining the logging system
#

try {

    if ($LogName -ne $null)
    {
        $LogName += " " + (Get-Date -Format dd.MM.yyyy) + " @ " + (Get-Date -Format HH.mm.ss) + ".log"
        $null = Start-Transcript -Path $LogName -Force
    }

    #
    #  Opens the CSV MASTER FILE (the INPUT parameters for the migration)
    #

    if ($CSVFile -eq $null) 
    {
        Write-Host "`n- Error, no CSV Import file provided!" -ForegroundColor Red
        Write-Host "- You need to specify the parameter '-CSVFile' along with a valid file name, example: -CSVFile C:\Docs\Files\Migration.csv `n" -ForegroundColor Red
        break
    }
    
    if ( (Test-Path $CSVFile) -eq $false ) 
    {
        Write-Host "`n- File not found!" -ForegroundColor Red
        Write-Host "- Cannot open the file specified by the the parameter -CSVFile!" -ForegroundColor Red
        Write-Host "- Execution aborted `n" -ForegroundColor Red
        break
    }

    try {
        $lines = Import-CSV $CSVFile -ErrorAction Stop
    }
    catch {
        Write-Host "`n- Error opening the file specified by the the parameter -CSVFile!" -ForegroundColor Red
        Write-Host "-" $_.Exception.Message `n          -ForegroundColor Red
        break
    }    

    # 
    #  Connect to SPO
    #


    #
    #  Checks the User Name
    #

    if ($UserName -eq $null)
    {
        $UserName = Read-Host "User Name"

        if ($UserName.Length -eq 0)
        {
            Write-Host "`n- The UserName cannot cannot be blank!" -ForegroundColor Red
            Write-Host "- You can also provide valid value for -UserName parameter, example:  -UserName john.doe@company.com `n" -ForegroundColor Red
            break
        }
    }

    #
    #  Checks the User Name
    #

    if ($Password -eq $null)
    { 
        $Password = Read-Host "Password for $userName" -AsSecureString
    }
    else
    {
        if (($Password.GetType()).Name -ne "SecureString")
        {
            $Password = $Password | ConvertTo-SecureString -AsPlainText -Force
        }
    }

    #
    #  Creation of the credentials 
    #

    $credentials = if ($credentials.length -eq 0) { New-Object System.Management.Automation.PSCredential ($UserName, $Password) } else { $credentials }


    #
    #  MFA authentication is now an official part of this script and future improvements should be considered for the whole
    #  authentication optiosn, I will revisit this script and modify how credentials are being passed and required, probably removing them all
    #

    if ($UseMFA)
    {
        try 
        {    
            #TODO  I need to work on the improvement to capture connection failures for connect-pnponline, this command does not use -ErrorAction

            Connect-PnPOnline -Url $SiteUrl -UseWebLogin -ErrorAction Stop             
        }
        catch {
            Write-Host "`n- Error connecting to the SharePoint site!"  -ForegroundColor Red
            Write-Host "- Check the values provided for your MFA enabled account: username, password, and authentication token." -ForegroundColor Red
            Write-Host "-" $_.Exception.Message `n  -ForegroundColor Red
            break
        }
    }
    else
    {        
        try 
        {    
            Connect-PnPOnline -Url $SiteUrl -Credentials $credentials -ErrorAction Stop 
        }
        catch {
            Write-Host "`n- Error connecting to the SharePoint site!"  -ForegroundColor Red
            Write-Host "- Check the values provided for your username, password and to the site url you are trying to connect to." -ForegroundColor Red
            Write-Host "-" $_.Exception.Message `n  -ForegroundColor Red        

            $Password = $null
            $credentials = $null

            break
        }
    }   
    
    #
    #  Process each line from the CSV File 
    #
    #    - where each line means 1 SOOURCE to 1 DESTINATION
    # 
    #  we need to manually count the number of lines from IMPORT-CSV, the cmdlet will return NO array for a file containing only 1 record,
    #  so the property ".Count" has no use and we will need to manually set "1" to the total of lines, on the other hand, for files containing
    #  more than 1 record, the property ".Count" will return the expected result for the total number of lines from the CSV file
    #

    

    # if there is only one LINE in the .CSV file, the .Count property will always return $null (because there is nothing to be counted)
    # once there is more than 1 LINE, PowerShell creates an array and the property .Count stores the length of the array and .Count can be used

    if ($lines -eq $null)   
    {
        Write-Host "`n- It seems your .CSV file doesn't contain any valid information."
        Write-Host "- Please check the contents of your .CSV file and try again. `n"
        exit
    }
    elseif ($lines.Count -eq $null)
        {
            $linesTotal = 1            
        }
        else
        {
            $linesTotal = $lines.Count
        }

    #
    #  Process each line from the CSV Master File
    #

    cls

    for($iLoop = 0; $iLoop -lt $linesTotal; $iLoop++)
    {
        $processingSourceStarted = Get-Date

        # to avoid any gaps in columns that are empty or misconfigured, 
        # we will reset the variables on each new row in the loop

        $line_SourceName                 = $null
        $line_SourceFolder               = $null
        $line_WebSiteName                = $null
        $line_TargetDocumentLibraryTitle = $null
        $line_TargetDocumentLibraryURL   = $null
    
        try {

            #
            #   to save processing time and avoiding repetitions, 
            #   we willl save the query: 
            # 
            #        Get-PnPWeb -Identity "ID"
            #

            if (("/","").Contains($lines[$iLoop].WebSiteName))
            {
                $webSiteName = Get-PnPWeb -ErrorAction Stop
            }
            else
            {
                $webSiteName = Get-PnPWeb $lines[$iLoop].WebSiteName -ErrorAction Stop
            }
        }
        catch {
            Write-Host "`n- Error trying to access web " -ForegroundColor Red -NoNewline
            Write-Host $webSiteName.ServerRelativeUrl -ForegroundColor Yellow 
            Write-Host "- Skipping this record, check the .CSV file and try again! `n" -ForegroundColor Red

            OperationReport -TimeStart $processingSourceStarted -SourceName $lines[$iLoop].SourceName -SourceFolder $lines[$iLoop].SourceFolder -DocumentLibrary $lines[$iLoop].TargetDocumentLibraryTitle -WebSiteName $lines[$iLoop].WebSiteName
            continue
        }

        # loads each field into a temporary variable

        $line_SourceName                 = $lines[$iLoop].SourceName
        $line_SourceFolder               = $lines[$iLoop].SourceFolder
        $line_WebSiteName                = $webSiteName.ServerRelativeUrl #  if (("/","").Contains($lines[$iLoop].WebSiteName)){ "/"} else {$lines[$iLoop].WebSiteName}
        $line_TargetDocumentLibraryTitle = $lines[$iLoop].TargetDocumentLibraryTitle
        $line_TargetDocumentLibraryURL   = $lines[$iLoop].TargetDocumentLibraryURL

        #
        # issues a feedback to the user about the current "Source"
        #

        "=" * " Processing: $line_SourceName  ($line_WebSiteName) ".Length

        Write-Host " Processing: " -NoNewline

        Write-Host $line_SourceName -ForegroundColor Yellow -NoNewline
        Write-Host "  ($line_WebSiteName)" -ForegroundColor Green 

        "=" * " Processing: $line_SourceName  ($line_WebSiteName) ".Length
    
        Write-Host `n         
        Write-Host "- Started at: $processingSourceStarted"

        if (!$DoNotCreateLibraries.IsPresent)
        {
            #
            #  Document Library
            #  ================
            #
            #  It will try to find a match, otherwise a new DOCUMENT LIBRARY will be created
            #

            Write-Host "`n- Checking for Document Library: " -NoNewline
            Write-Host $line_TargetDocumentLibraryTitle -ForegroundColor Yellow
                        
            if ( (Get-PnPList -Identity $line_TargetDocumentLibraryURL -Web $webSiteName).Title.Length -eq 0 )
            {
                Write-Host " `n`t creating document library ... `n" -ForegroundColor Green
    
                try {
                    $result = New-PnPList -Title $line_TargetDocumentLibraryTitle -Url $line_TargetDocumentLibraryURL -Template DocumentLibrary -Web $webSiteName -ErrorAction Stop
                }
                catch {
                    Write-Host "`n- Error creating Document Library: " -ForegroundColor Red -NoNewline
                    Write-Host $line_TargetDocumentLibraryTitle `n  -ForegroundColor Yellow

                    OperationReport -TimeStart $processingSourceStarted -SourceName $line_SourceName -SourceFolder $line_SourceFolder -DocumentLibrary $line_TargetDocumentLibraryTitle -WebSiteName $line_WebSiteName
                    continue
                }
            }
        }

        # ============================================
        #
        #    Import files into the Document Library
        #
        # ============================================

        Write-Host "- Importing files ... `n"

        #
        #   Gets the current 'Context', it will be passed to the following functions:
        #
        #   - UploadFile()
        #   - Create-FolderHierarchy()
        #
    
        $CSOM_credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($credentials.UserName, $credentials.Password)
        $CSOM_context = New-Object Microsoft.SharePoint.Client.ClientContext($webSiteName.Url)
        
        # The AuthenticationMode is now a mandatory part of the script to solve issues around HTTP 403
        # Since Microsoft has made changes to enforce authentication control on SPO it becomes an important part of all scripts

        $CSOM_context.AuthenticationMode = [Microsoft.SharePoint.Client.ClientAuthenticationMode]::

        $CSOM_context.Credentials = $CSOM_credentials
        $CSOM_context.RequestTimeout = 300000

        try 
        {
            $DocumentLibrary = $CSOM_context.Web.Lists.GetByTitle($line_TargetDocumentLibraryTitle).RootFolder
            $CSOM_context.Load($DocumentLibrary)
            $CSOM_context.ExecuteQuery()
        }
        catch 
        {
            if (!$DoNotCreateLibraries.IsPresent)
            {
                Write-Host "`n- Couldn't find the document library '$line_TargetDocumentLibraryTitle' " -ForegroundColor Red
                Write-Host "- Something went wrong while trying to upload the files to the '$line_TargetDocumentLibraryTitle'. `n" -ForegroundColor Red

                Write-Host $_.Exception.Message `n -ForegroundColor Yellow

                OperationReport -TimeStart $processingSourceStarted -SourceName $line_SourceName -SourceFolder $line_SourceFolder -DocumentLibrary $line_TargetDocumentLibraryTitle -WebSiteName $line_WebSiteName
                continue
            }
        }

        try 
        {
            $fileNames = Get-LongChildItem -Path $line_SourceFolder -Recurse | Sort-Object FullName
            $fileNames_Count = $fileNames.Count
        }
        catch 
        {
            Write-Host "- Invalid 'SourceFolder' referenced in the CSV file, could not locate this path." -ForegroundColor Red
            Write-Host "- This 'SourceFolder' will not be imported to SharePoint, check your CSV file and try again. `n" -ForegroundColor Red

            OperationReport -TimeStart $processingSourceStarted -SourceName $line_SourceName -SourceFolder $line_SourceFolder -DocumentLibrary $line_TargetDocumentLibraryTitle -WebSiteName $line_WebSiteName
            continue
        }

        #
        #  Reset the report counters
        #
    
        $reporting_Position = 0
        $reporting_FileErrors = 0
        $reporting_FoldersErrors = 0
        $reporting_TotalDirs = 0
        $reporting_Ignored = 0 
        $reporting_RenamedFiles = 0 
        $reporting_RenamedFolders = 0 
        $reporting_FilesSkipped = 0

        #
        #  Process the files and folders
        #

        foreach($currentFile in $fileNames)
        {
            $reporting_Position += 1

            Write-Progress -Activity "Migrating Items ($reporting_Position of $fileNames_Count)" -Status "File: $currentFile" -PercentComplete ($reporting_Position / $fileNames.Count * 100) -Id 1

            $validFileName = $null
            $cleanFileName = $null
            $validFolderName = $null
            $cleanFolderName = $null

            if ($currentFile.Mode -eq "Directory")
            {
                Write-Host `n`n $currentFile.FullName  -ForegroundColor Green  -NoNewline

                if ($DoNotCreateFolders.IsPresent) 
                {                    
                    $cleanFolderName = "/"
                }
                else
                {
                    $cleanFolderName = ValidateName -Value $currentFile.FullName.Replace($line_SourceFolder,'').Replace('\','/')  
                }

                if (!$DoNotCreateFolders.IsPresent -and $DocumentLibrary.Name.Length -gt 0) 
                {                    
                    $result = Create-FolderHierarchy -TopFolder $DocumentLibrary -FolderUrl $cleanFolderName
                }
                else
                {                    
                    $result = $true
                }

                $reporting_TotalDirs += 1

                if ($result -eq $false) 
                {
                    Write-Host "   (ERROR!)"  -ForegroundColor Red
                    $reporting_FoldersErrors += 1
                }

                if ( ($currentFile.FullName.Replace($line_SourceFolder,'').Replace('\','/')) -ne $cleanFolderName )
                {
                    Write-Host "   ==>  " $cleanFolderName  -NoNewline -ForegroundColor Yellow
                    $reporting_RenamedFolders += 1
                }

                Write-Host ""
            }
            else
            {
                Write-Host `n " " $currentFile.FullName  -NoNewline -ForegroundColor Gray

                $validFileName = ValidateName -Value $currentFile.FullName.Replace($line_SourceFolder,'')  
                $cleanFileName = [System.IO.Path]::GetFileName($validFileName)

                if ($DoNotCreateFolders.IsPresent) 
                {                    
                    $cleanFolderName = "/"
                }
                else
                {
                    $cleanFolderName = ([System.IO.Path]::GetDirectoryName($validFileName).Replace('\','/'))  # + '/'
                }        
                

                if (!$cleanFolderName.EndsWith('/'))
                {
                    $cleanFolderName += '/'
                }

                #
                #   Additional validations
                #

                $valid = $true

                # --- URL can't be bigger than 400 chars:  URL = website address + document library + folder/file

                if ( ($DocumentLibrary.Url + '/'+ $line_TargetDocumentLibraryURL + $cleanFolderName + $cleanFileName).Length -gt 400 )   
                {
                    Write-Host "   [INVALID: URL over 400 chars]" -NoNewline -ForegroundColor Cyan
                    $reporting_FileErrors += 1
                    $valid = $false
                }

                # --- Filters out junk files from OS

                if ( ("desktop.ini", "thumbs.db", "ehthumbs.db").Contains($currentFile.Name.ToLower()) ) 
                {                
                    Write-Host "   [Skipping]" -NoNewline -ForegroundColor Cyan
                    $reporting_Ignored += 1
                    $valid = $false
                }

                # --- Filters out junk files based on their extension (.tmp and .ds_store), the rest are not allowed in SharePoint anyways

                if ( (".tmp", ".ds_store", ".aspx", ".asmx", ".ascx", ".master", ".xap", ".swf", ".jar", ".xsf", ".htc" ).Contains([System.IO.Path]::GetExtension($currentFile.Name.ToLower())) ) 
                {
                    Write-Host "   [Skipping: extension not allowed]" -NoNewline -ForegroundColor Cyan 
                    $reporting_Ignored += 1
                    $valid = $false
                }

                if ($valid)
                {
                    if ($currentFile.Name -ne $cleanFileName) 
                    {
                        Write-Host "   ==>  " $cleanFileName  -NoNewline -ForegroundColor Yellow
                        $reporting_RenamedFiles += 1
                    }

                    try {

                        if (!$DoNotPerformUploads.IsPresent)
                        {
                            $url_TargetFolder = $DocumentLibrary.ServerRelativeUrl + $cleanFolderName
                            $up = UploadFile -ctx $CSOM_context -TargetLibraryName $line_TargetDocumentLibraryTitle -TargetFolderName $url_TargetFolder -SourceFileName $currentFile.FullName -NewFileName $cleanFileName

                            if ($up -ne $null)
                            {
                                $up_Properties = $up.ListItemAllFields

                                $own = ($currentFile.GetAccessControl().owner) -replace "\\","/"
                                $user = ([ADSI]"WinNT://$own,user").FullName
	                            $who = Get-PnPUser | ? {$_.Title -match $user} | select id

                                $up_Properties["Author"]   = $who.id
                                $up_Properties["Editor"]   = $who.id
                                $up_Properties["Modified"] = $currentFile.LastWriteTimeUtc
                                $up_Properties["Created"]  = $currentFile.CreationTimeUtc

                                $up_Properties.Update()

                                $CSOM_context.Load($up_Properties)

                                try  {
                                    $CSOM_context.ExecuteQuery()
                                }
                                catch {
                                    Write-Host "`n`n- Error updating the metadata properties for the file: " -NoNewline -ForegroundColor Red 
                                    Write-Host $currentFile.Name  -ForegroundColor Yellow

                                    Write-Host ($_.Exception.Message -replace 'Exception calling \"ExecuteQuery\" with \"0\" argument\(s\)\: ','') `n  -ForegroundColor Red 

                                    $reporting_FileErrors += 1
                                }
                            }
                        }
                    }
                    catch {
                        Write-Host "`n`n- File: " -NoNewline -ForegroundColor Red
                        Write-Host $currentFile.Name  -ForegroundColor Yellow

                        Write-Host "- Folder: "  -NoNewline -ForegroundColor Red 
                        Write-Host $cleanFolderName  -ForegroundColor Yellow

                        Write-Host ($_.Exception.Message -replace 'Exception calling \"ExecuteQuery\" with \"0\" argument\(s\)\: ','') `n  -ForegroundColor Red 

                        $reporting_FileErrors += 1
                    }                            
                }
                else
                {
                    $reporting_FilesSkipped += 1
                }
            }
        }

        Write-Progress -Activity "Migrating Items" -Status "Completed" -PercentComplete 100 -Id 1 -Completed

        #
        #  completes the processing of the current line and issues feedback
        #
        #  1 - captures the datetime of completion
        #  2 - time difference (total of hours, minutes and seconds spent), good feedback for future migrations
        #

        OperationReport -TimeStart $processingSourceStarted -SourceName $line_SourceName -SourceFolder $line_SourceFolder -DocumentLibrary $line_TargetDocumentLibraryTitle -WebSiteName $line_WebSiteName -FilesTotal ($fileNames.Count - $reporting_TotalDirs) -FoldersTotal $reporting_TotalDirs -FilesFailures $reporting_FileErrors -FoldersFailures $reporting_FoldersErrors -FilesRenamed $reporting_RenamedFiles -FoldersRenamed $reporting_RenamedFolders -FilesSkipped $reporting_FilesSkipped
    }

    Write-Host `n 

}
finally {

    if ($LogName -ne $null)
    {
        $htmlOutput = $LogName -replace ".log", ".html"
        Get-ConsoleAsHtml | out-file $htmlOutput -encoding UTF8
        $null = Stop-Transcript
    }

    if ($CSOM_context -ne $null) 
    {
        $CSOM_context.Dispose()
    }
}