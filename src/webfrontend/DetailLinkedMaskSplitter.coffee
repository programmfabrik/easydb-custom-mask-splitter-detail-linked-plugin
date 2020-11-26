class ez5.DetailLinkedMaskSplitter extends CustomMaskSplitter

	@NAVIGATION_LIMIT = 10

	getOptions: ->
		tables = @__getTablesWithLinkToTable(@maskEditor.current_mask.table.table_id)
		tablesOptions = []
		for table in tables
			tablesOptions.push
				value: table.name
				text: table._name_localized

		options = [
			form:
				label: $$("detail.linked.mask.splitter.options.mode")
			type: CUI.Select
			name: "mode"
			options: [
				text: $$("detail.linked.mask.splitter.options.mode.standard")
				value: "standard"
			,
				text: $$("detail.linked.mask.splitter.options.mode.short")
				value: "short"
			,
				text: $$("detail.linked.mask.splitter.options.mode.text")
				value: "text"
			]
		,
			form:
				label:  $$("detail.linked.mask.splitter.options.tables")
			type: CUI.Options
			name: "tables"
			options: tablesOptions
			onDataInit: (_, data) =>
				if not CUI.util.isUndef(data.tables)
					return
				data.tables = []
				tables = @__getTablesWithLinkToTable(@maskEditor.current_mask.table.table_id)
				for table in tables
					data.tables.push(table.name)
				return
		]
		return options

	getDefaultOptions: ->
		defaultOptions =
			mode: "standard"
		return defaultOptions

	renderField: (opts = {}) ->
		globalObjectId = opts.top_level_data?._global_object_id
		if not globalObjectId
			return

		objecttype = opts.top_level_data._objecttype
		if not objecttype
			return

		dataOptions = @getDataOptions()
		idTable = ez5.schema.CURRENT._objecttype_by_name[objecttype].table_id
		linkedFieldNames = @__getLinkedFieldNames(idTable, dataOptions.tables)

		if linkedFieldNames.length == 0
			return

		mainContent = CUI.dom.div()
		spinner = new LocaLabel(loca_key: "detail.linked.mask.splitter.detail.spinner")
		CUI.dom.append(mainContent, spinner)

		@__searchByLinkedFieldNames(linkedFieldNames, globalObjectId, dataOptions.mode).done((data) =>
			CUI.dom.empty(mainContent)
			if data.objects.length == 0
				return

			objectsByObjecttype = {}
			for object in data.objects
				resultObject = new ResultObject().setData(object)
				objecttype = resultObject.objecttypeLocalized()
				if not objectsByObjecttype[objecttype]
					objectsByObjecttype[objecttype] = []
				objectsByObjecttype[objecttype].push(resultObject)

			for objecttype, resultObjects of objectsByObjecttype
				content = @__renderObjects(objecttype, resultObjects, dataOptions.mode)
				CUI.dom.append(mainContent, content)
			return
		).fail(=>
			# TODO: What happens when there is an error? should we show an error message?
		)

		return mainContent

	__renderObjects: (objecttype, resultObjects, mode) ->
		objecttypeHeader = CUI.dom.div("ez5-field-block-header")
		objectsContent = CUI.dom.div("ez5-field-block-content")
		CUI.dom.append(objecttypeHeader, $$("detail.linked.mask.splitter.header.objecttype.title", objecttype: objecttype))

		limit = ez5.DetailLinkedMaskSplitter.NAVIGATION_LIMIT
		length = resultObjects.length
		currentPage = 0

		renderObjects = (page = currentPage) ->
			CUI.dom.empty(objectsContent)

			currentPage = page
			offset = page * limit
			toIndex = offset + limit

			if toIndex > length
				toIndex = length

			for index in [offset...toIndex]
				resultObject = resultObjects[index]
				div = switch mode
					when "short"
						resultObject.renderCardLinkedObjectShort()
					when "text"
						resultObject.renderTextDetail()
					when "standard"
						resultObject.renderCardLinkedObjectStandard()
				CUI.dom.append(objectsContent, div)

			if navigationToolbar
				navigationToolbar.update(count: length, offset: offset, limit: limit)
			return

		content = [objecttypeHeader, objectsContent]
		if length > limit
			navigationToolbar = new NavigationToolbar
				size: "mini"
				append_count_label: false
				onLoadPage: renderObjects
			content.push(navigationToolbar)

		renderObjects()

		return content

	__getLinkedFieldNames: (idTable, tables = []) ->
		linkedFieldNames = []
		for table in ez5.schema.CURRENT.tables
			for column in table.columns
				if table.name not in tables
					continue
				if not @__hasColumnLinkToTable(column, idTable)
					continue
				fieldName = "#{table.name}.#{column.name}._global_object_id"
				if table.owned_by
					fieldName = "#{table.owned_by.other_table_name_hint}._nested:#{fieldName}"
				linkedFieldNames.push(fieldName)
		return linkedFieldNames

	__searchByLinkedFieldNames: (linkedFieldNames, globalObjectId, mode) ->
		mode = if mode == "text" then "long" else mode
		return ez5.api.search
			json_data:
				format: mode
				search: [
					type: "in"
					fields: linkedFieldNames
					in: [globalObjectId]
				]

	__getTablesWithLinkToTable: (idTable) ->
		tables = []
		for table in ez5.schema.CURRENT.tables
			for column in table.columns
				if @__hasColumnLinkToTable(column, idTable)
					tables.push(table)
					break
		return tables

	__hasColumnLinkToTable: (column, idTable) ->
		return column.type == "link" and column._foreign_key.referenced_table.table_id == idTable

	isSimpleSplit: ->
		return true

	renderAsField: ->
		return true

	isEnabledForNested: ->
		return false

MaskSplitter.plugins.registerPlugin(ez5.DetailLinkedMaskSplitter)
