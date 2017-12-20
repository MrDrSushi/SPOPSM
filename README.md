# SPOPSM #

![release](https://img.shields.io/badge/release-v1.0.0-blue.svg)
![status](https://img.shields.io/badge/status-stable-green.svg)
![mit](https://img.shields.io/badge/license-MIT-blue.svg)

**SharePoint Online PowerShell Migrator**

SPOPSM is a little script utility to simplify the process of migrating local files and network shars to SharePoint Online, preservaing metadata, replacing invalid characters, ignoring invalid files, and dealing with large files up to 15GB. It can be used to migrate one or more sources and automate long migrations, and also helps users to test their migration by generating reports before making any changes to SharePoint.

Finally an easy and open source solution aimed to simplify long and tedious migration jobs to SharePoint Online!



## Using the Script ##

Given the following command line below:

**`.\SPOPSM.ps1 -UserName johndoe@adventureworks.com -SiteUrl https://adventureworks.sharepoint.com/sites/apac -LogName .\Finance -CSVFile .\finance.csv`**

It will run the script using the credentials from `johndoe@adventureworks.com` to migrate the specified files in the .csv file to `https://adventureworks.sharepoint.com/sites/apac`, and the operation will also record a log.





## The CSV File ##

On our previous example, we migrated to **https://adventureworks.sharepoint.com/sites/apac**, the instructions used for the migration were placed in a **.csv file** (comma separated values), which specified the source for the file and the destination (the web where the document library is residing or will be created)

![SPOPSM](./readme/finance-xlsx.png)

You can use any editor to create your own .csv files (Excel is probably the best when you want to deal with a lot of things), the columns are separated by commas, and yes, you can have values containing commas, just don't forget to match the exactly number of commas according to the columns, so a regular .csv files would look like the following:


**SourceName,SourceFolder,WebSiteName,TargetDocumentLibraryTitle,TargetDocumentLibraryURL**
**Samples,C:\Migrations\Samples\Miscelanea,/,Migration Samples,Samples**


The columns above are the following:

* **SourceName** = a friendly name for your source, it will be displayed during the migration

* **SourceFolder =** source folder containing your files and folders, it could be something like: **C:\Finance** - or a share like: **\\\wks01\ADMIN\Shared\FY17\Reports**

* **WebSiteName** = the destination on SharePoint Online for your migration, the script will look for a web named after this value, for example, if you specify "Finance" (no quotes needed) the script will look this web called **"Finance"** under https://adventureworks.sharepoint.com, if you want to import within the same the root web, just leave blank or use a backslash **(/)**

* **TargetDocumentLibraryTitle** = if the script can't find a document library matched by **"TargetDocumentLibraryURL"**, a new document library will be create and this value will be used for its Title, for example: **"Finance 2017 Docs"**

* **TargetDocumentLibraryURL** = the physical name for the document library, if an existing name is matched, the migration will reuse the library, otherwise a new document library will be created using this name for the URL, for example: **"FY2017DOCS"**






## Aditional Parameters ##


**`-Password`** You can supply a password by using the this parameter, for example: **`-Password 123XYZ`**, it will be sent as clear text and will expose your password for anybody, or you can use a variable with the encripted text, for example: **`-Password $ENCPASSWORD`**. This parameter allows you to automate the script execution skipping the prompt for your password, and should be used with caution to not expose your credential.

**`-LogName`** location and name of the log file, if not specified, no logs will be generated

**`-CSVFile`** location and name of the CSV FILE containing the instructions for the migration

**`-UserName`** SharePoint User Name

**`-SiteUrl`** URL of the Target WebSite (Top Level)



You can generate a soft upload (a preview of a migration):


In the example above, no document libraries, folder and files will be created on SharePoint, the screen output will show what an import will look like and the results are captured to a log file called **Finance.log** (another file called **Finance.html** is also generated, this is a copy of the console output in HTML format)


ignoring invalid files such as **.tmp, .ds_store, .aspx, .asmx, .ascx, .master, .xap, .swf, .jar, .xsf, .htc**, it will also replace invalid characters found in files and/or folders avoiding any interruptions during the migration, while supporting files up to 15GB.

SPOPSM can perform validations to the source you are planning to migrate without, I call this option **"soft upload"** mode, by combining the parameters **-DoNotCreateLibraries -DoNotCreateFolders -DoNotPerformUploads**


```PowerShell
.\SPOPSM.ps1 -LogName .\Finance -CSVFile C:\Jobs\finance.csv -UserName johndoe@adventureworks.com -SiteUrl https://adventureworks.sharepoint.com/sites/apac  -DoNotCreateLibraries -DoNotCreateFolders -DoNotPerformUploads
```






## Cloning the Repo

`git clone https://github.com/MrDrSushi/SPOPSM.git`