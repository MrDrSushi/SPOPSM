# SPOPSM
SharePoint Online PowerShell Migrator

Finally a PowerShell script simplify migration of network shares and local folder structures to SharePoint Online.

If you have to migrate one or several network shares and/or local folders to SharePoint Online, this little script might be the answer for your problems :)

The script will use a custom .csv file which will contain the list of sources to be imported into SharePoint Online, in your .csv file you will specify a name to the source and its location, the target website to where it will go, and the name of the document library where the files and folders will be 




# How to Use the Script


Let's say we want to migrate the folder C:\Migrations\Samples\Miscelanea to a document library called "Migration Samples" to our tenant web at https://adventureworks.sharepoint.com - we would create a .csv file pointing to the following values:


Where:

    SourceName = Samples 

    SourceFolder = C:\Migrations\Samples\Miscelanea

    WebSiteName = /

    TargetDocumentLibraryTitle = Migration Samples

    TargetDocumentLibraryURL = Samples


The .CSV file would look like the following:

SourceName,SourceFolder,WebSiteName,TargetDocumentLibraryTitle,TargetDocumentLibraryURL
Samples,C:\Migrations\Samples\Miscelanea,/,Migration Samples,Samples


The columns above are the following:

    - SourceName = it is a friendly name used for each line in the .csv to refer to the source you are importing,
    it will be displayed while the script is importing the files

    - SourceFolder = it points to the source folder from where the script will import the files, it could be 
    something like: C:\Finance - or a share like: \\ADMIN\FY17\Reports

    - WebSiteName = the destination on SharePoint Online for your migration, the script will look for a web 
    named after this value, for example, if you specify "Finance" (no quotes needed) the script will look this
    web called "Finance" under https://adventureworks.sharepoint.com, if you want to import within the same the
    root web, just leave blank or use "/"

    - TargetDocumentLibraryTitle = this is the name of the new document library to be created on SharePoint, if 
    the script can't find one matched by the column "TargetDocumentLibraryURL"

    - TargetDocumentLibraryURL = the physical name for the document library, it cannot contain any special 
    characters, for example: FY2018





# Cloning the Repo
git clone https://github.com/MrDrSushi/SPOPSM.git

