<cfcomponent output="false" hint="Plugin Erweiterung fuer das Framework One">

<cffunction name="init" returntype="any" access="public" output="false" hint="Laedt alle Plugins">
	<cfargument name="fw"			type="any"			required="true"		hint="Framework One Instanz" />
	<cfargument name="reload"	type="boolean"	required="false"	default="false"	hint="Sollen alle Plugins neu geladen werden?" />

	<cfset var local = structNew() />

	<cfset variables.fw					= arguments.fw />
	<cfset variables.fw.inject	= inject />

	<cfif NOT structKeyExists(application,"pluginCache") OR arguments.reload OR variables.fw.isFrameworkReloadRequest()>
		<cfset application.pluginCache = structNew() />

		<cfdirectory name="local.plugins" action="list" directory="#expandPath('./plugins')#" filter="*.cfc" />
		<cfloop query="local.plugins">
			<cfset local.pluginName = listFirst(local.plugins.name,".") />

			<cfif NOT listFindNoCase("plugin",local.pluginName)>
				<cfset local.plugin = createObject("component",local.pluginName) />

				<cfif structKeyExists(local.plugin,"init")>
					<cfset local.plugin.init() />
				</cfif>

				<cfset application.pluginCache[local.pluginName] = local.plugin />
			</cfif>
		</cfloop>
	</cfif>

	<cfloop collection="#application.pluginCache#" item="local.pluginName">
		<cfset variables.fw.inject(local.pluginName,application.pluginCache[local.pluginName]) />
	</cfloop>

	<cfset structDelete(variables.fw,"inject") />

	<cfreturn this />
</cffunction>


<cffunction name="inject" returntype="void" access="private" output="false" hint="Iniziiert Objekte in die Application.cfc">
	<cfargument name="name"	type="string"	required="true"		hint="Name des Objekts das iniziiert wird" />
	<cfargument name="data"	type="any"		required="true" 	hint="Objekt das iniziiert wird" />

	<cfset "variables.#arguments.name#"	= arguments.data />
	<cfset "this.#arguments.name#"			= arguments.data />

</cffunction>

</cfcomponent>