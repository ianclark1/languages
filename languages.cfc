<cfcomponent output="false" hint="Sprach Plugin">

<cffunction name="init" returntype="languages" access="public" output="false" hint="Initialisiert das Sprachplugin">

	<cfset var local = structNew() />

	<cfset variables.instance = structNew() />

	<cfdirectory name="local.languages" action="list" directory="#expandPath('./languages/')#" filter="*.ini" />
	<cfloop query="local.languages">
		<cfset local.javaLocale	= listFirst(local.languages.name,".") />
		<cfset local.ini				= expandPath('./languages/#local.languages.name#') />
		<cfset local.sections		= getProfileCharSections(local.ini) />

		<cfset variables.instance[local.javaLocale] = structNew() />
		<cfloop collection="#local.sections#" item="local.section">
			<cfloop list="#local.sections[local.section]#" index="local.key">
					<cfset local.structItem = reReplaceNoCase(local.section,"[^a-z0-9_]","","all") />
					<cfset "variables.instance.#local.javaLocale#.#local.structItem#.#local.key#" = getProfileCharString(local.ini,local.section,local.key) />
			</cfloop>
		</cfloop>
	</cfloop>

	<cfreturn this />
</cffunction>


<cffunction name="setup" returntype="void" access="public" output="false" hint="Laedt eine Sprache">
	<cfargument name="language" type="string" required="false" default="" hint="Sprache die geladen werden soll" />

	<cfparam name="cookie.languages_current" type="string" default="de_DE" />

	<cfif compare("",arguments.language) AND compareNoCase(arguments.language,cookie.languages_current)>
		<cfset cookie.languages_current = arguments.language />
	</cfif>
</cffunction>


<cffunction name="translate" returntype="string" access="public" output="false" hint="Uebersetzt einen Schluessel">
	<cfargument name="key"		type="string"		required="true"		hint="Schluessel der uebersetzt wird" />
	<cfargument name="clean"	type="boolean"	required="false"	default="false"	hint="Falls der Schluessel ohne htmlEditFormat zurueckgeliefert werden soll = true" />

	<cfset var local = structNew() />
	<cfset local.templatePath	= "" />
	<cfset local.basePath			= expandPath("./") />
	<cfset local.translation	= arguments.key />

	<cftry>
		<cfthrow type="callingTemplatePath" detail="throws an exception to get the calling template path" />
		<cfcatch type="callingTemplatePath">
			<cfset local.templatePath = cfcatch.tagContext[2].template />
		</cfcatch>
	</cftry>

	<cfset local.viewPath		= listFirst(replace(local.templatePath,local.basePath,""),".") />
	<cfset local.structItem	= reReplaceNoCase(local.viewPath,"[^a-z0-9_]","","all") />

	<cfif structKeyExists(variables.instance[cookie.languages_current],local.structItem) AND structKeyExists(variables.instance[cookie.languages_current][local.structItem],arguments.key)>
		<cfset local.translation = variables.instance[cookie.languages_current][local.structItem][arguments.key] />
	</cfif>

	<cfif NOT arguments.clean>
		<cfset local.translation = htmlEditFormat(local.translation) />
	</cfif>

	<cfreturn local.translation />
</cffunction>


<!--- docu:reinhardjung/ 2010.07.13 15:49:52 PM  Profile ReWrite mit UTF-8 --->
<cffunction name="getProfileCharSections" returntype="struct" access="public" output="false" hint="">
	<cfargument name="path" type="string" required="true" hint="Pfad zur INI-Datei" />
	<cfargument name="charset" type="string" required="false" default="utf-8" hint="Zeichensatz" />

	<cfset var local = structNew() />
	<cfset local.sections = structNew() />

	<cfinvoke component="#this#" method="read" argumentcollection="#arguments#" returnvariable="local.INIfile" />
	<cfloop from="1" to="#listLen(local.inifile,chr(10))#" index="local.line">
		<cfset local.value = trim(listGetAt(local.inifile,local.line,chr(10))) />

		<cfif left(local.value,1) IS "[">
			<cfset local.newSection = mid(local.value,2,len(local.value)-2) />
			<cfset local.sections[local.newSection] = "">
		<cfelse>
			<cfset local.sections[local.newSection] = listAppend(local.sections[local.newSection],listFirst(local.value,'=')) />
		</cfif>
	</cfloop>

	<cfreturn local.sections />
</cffunction>


<cffunction name="getProfileCharString" returntype="string" access="public" output="false" hint="">
	<cfargument name="path"			type="string" required="true" hint="Pfad zur INI-Datei" />
	<cfargument name="section"	type="string" required="true" hint="Pfad zur INI-Datei" />
	<cfargument name="entry"		type="string" required="true" hint="Pfad zur INI-Datei" />
	<cfargument name="charset"	type="string" required="false" default="utf-8" hint="Zeichensatz" />

	<cfset var local = structNew() />

	<cfset arguments.section = replace(arguments.section,'/','_','all') />

	<cfinvoke component="#this#" method="ini2Struct" argumentcollection="#arguments#" returnvariable="local.struct" />

	<cfreturn evaluate('local.struct.#arguments.section#.#arguments.entry#') />
</cffunction>


<cffunction name="read" returntype="string" access="public" output="false" hint="liest die Datei in eine Struktur">
	<cfargument name="path" type="string" required="true" hint="Pfad zur INI-Datei" />
	<cfargument name="charset" type="string" required="false" default="utf-8" hint="Zeichensatz" />

	<cfset var local = structNew() />
	<cffile action="read" file="#arguments.path#" variable="local.iniFile" charset="#arguments.charset#" />

	<cfreturn local.iniFile />
</cffunction>


<cffunction name="ini2Struct" returntype="struct" access="public" output="false" hint="">
	<cfargument name="path"			type="string" required="true" hint="Pfad zur INI-Datei" />

	<cfset var local = structNew() />
	<cfset local.sections = structNew() />

	<cfinvoke component="#this#" method="read" argumentcollection="#arguments#" returnvariable="local.INIfile" />
	<cfloop from="1" to="#listLen(local.inifile,chr(10))#" index="local.line">
		<cfset local.value = trim(listGetAt(local.inifile,local.line,chr(10))) />

		<cfif left(local.value,1) IS "[">
			<cfset local.newSection = replace(mid(local.value,2,len(local.value)-2),'/','_','all') />
			<cfset local.sections[local.newSection] = "">
		<cfelse>
			<cfif NOT isValid('struct',local.sections[local.newSection])>
				<cfset local.sections[local.newSection] = structNew() />
			</cfif>
			<cfset local.sections[local.newSection][listFirst(local.value,'=')] = listLast(local.value,'=') />
		</cfif>
	</cfloop>

	<cfreturn local.sections />
</cffunction>

</cfcomponent>