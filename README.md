# SPOPSM

![release](https://img.shields.io/badge/release-v1.0.0-blue.svg)
![status](https://img.shields.io/badge/status-stable-green.svg)
![mit](https://img.shields.io/badge/license-MIT-blue.svg)

**SharePoint Online PowerShell Migrator**

Finally a PowerShell script aimed to simplify the migration of network shares and local folders to SharePoint Online!

Use this solution to migrate files while preserving their metadata along with its original folder structure to SharePoint, the SPOPSM will validate the source, skipping invalid files such as .tmp, .ds_store, .aspx, .asmx, .ascx, .master, .xap, .swf, .jar, .xsf, .htc, will also replace invalid characters found in files and folders avoiding any interruptions on your migration, recreating on SharePoint the same structure from your source into a new or using an exisiting document library.

The solution will handle files over 10MB, supporting files up to 15GB, 

It also provides a "soft upload" mode, displaying a visual report of which files and folders will be renamed for containing invalid characters and what will be their new names in their new locations, and the total amount of items handled by the migration (items skipped due to invalid extensions, items renamed, totals of folders, total  number of files migrated, etc.), this option helps users understand how their data will get to SharePoint and provides an answers for the portofolio migrated mapping SOURCE -> TARGET, and also it is the option to check everything before commiting to changes on your SharePoint.

The script will use a custom .csv file which will contain the list of sources to be imported into SharePoint Online, in your .csv file you will specify a name to the source and its location, the target website to where all the files and folders will go, and the name of the document library where everything should be placed, the script supports also a couple of handy parameters that will provide.

Using the script:

```PS
.\SPOPSM.ps1 -LogName .\Finance -CSVFile C:\Jobs\finance.csv -UserName johndoe@adventureworks.com -SiteUrl https://adventureworks.sharepoint.com 
```

Once you hit enter, the script will prompt yout the password (you can supply a password by using the **-Password**, parameter, for example: **-Password 123**, or you can use a variable with the encripted text, for example: **-Password $ENCPASSWORD**), the parameter **-Password** allows you to automate the script execution skipping the prompt for your password, and allowing the script to scheduled.

You can generate a soft upload (a preview of a migration):

```PS
.\SPOPSM.ps1 -LogName .\Finance -CSVFile C:\Jobs\finance.csv -UserName johndoe@adventureworks.com -SiteUrl https://adventureworks.sharepoint.com  -DoNotCreateLibraries -DoNotCreateFolders -DoNotPerformUploads
```

In the example above, no document libraries, folder and files will be created on SharePoint, the screen output will show what an import will look like and the results are captured to a log file called **Finance.log** (another file called **Finance.html** is also generated, this is a copy of the console output in HTML format)

### How to Use the Script

Let's say we want to migrate the folder **C:\Finance\Docs** to a document library called **"Finance 2017"** to our tenant web at https://adventureworks.sharepoint.com - we need to create a .csv file and include a line like in the example below, this will instruct the script to import the contents associated with the line **Finance Files** into SharePoint to a root web into a document library called **"Finance 2017"**, along with the other lines to their respective destinations.

In the example below we are importing three different sources but you can simply import one line at a time if you want to work in smaller import projects. I would recommend to take the example below for your migration projects, 

|SourceName|SourceFolder|WebSiteName|TargetDocumentLibraryTitle|TargetDocumentLibraryURL|
|----------|------------|-----------|--------------------------|------------------------|
**Finance Files**    |**C:\Finance\Docs**|/|**Finance 2017**|**Finance**
Dev Team (Legacy)|\\\Works\DevTeam\Projects|Dev|Projects|Projects
Sales (Old Stuff)|\\\Customers\Bids|Commercial|Sales (Archived)|Sales2016


### CSV File

The .CSV file can contain one or more lines, where each line will contain the a source and a destination to be imported to SharePoint.


SourceName,SourceFolder,WebSiteName,TargetDocumentLibraryTitle,TargetDocumentLibraryURL
Samples,C:\Migrations\Samples\Miscelanea,/,Migration Samples,Samples


The columns above are the following:

* **SourceName** = a friendly name for your source, it will be displayed during the migration

* **SourceFolder =** source folder containing your files and folders, it could be something like: **C:\Finance** - or a share like: **\\\wks01\ADMIN\Shared\FY17\Reports**

* **WebSiteName** = the destination on SharePoint Online for your migration, the script will look for a web named after this value, for example, if you specify "Finance" (no quotes needed) the script will look this web called **"Finance"** under https://adventureworks.sharepoint.com, if you want to import within the same the root web, just leave blank or use a backslash **(/)**

* **TargetDocumentLibraryTitle** = if the script can't find a document library matched by **"TargetDocumentLibraryURL"**, a new document library will be create and this value will be used for its Title, for example: **"Finance 2017 Docs"**

* **TargetDocumentLibraryURL** = the physical name for the document library, if an existing name is matched, the migration will reuse the library, otherwise a new document library will be created using this name for the URL, for example: **"FY2017DOCS"**


### Cloning the Repo
git clone https://github.com/MrDrSushi/SPOPSM.git

