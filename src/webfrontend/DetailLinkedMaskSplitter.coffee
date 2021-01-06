class ez5.DetailLinkedMaskSplitter extends CustomMaskSplitter

	@NAVIGATION_LIMIT = 10

	getOptions: ->
		objecttypes = @__getObjecttypesWithLinkToTable(@maskEditor.current_mask.table.table_id)
		objecttypeOptions = []
		for objecttype in objecttypes
			objecttypeOptions.push
				value: objecttype.name
				text: objecttype._name_localized

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
				label:  $$("detail.linked.mask.splitter.options.objecttypes")
			type: CUI.Options
			name: "objecttypes"
			options: objecttypeOptions
			onDataInit: (_, data) =>
				if not CUI.util.isUndef(data.objecttypes)
					return
				data.objecttypes = []
				objecttypes = @__getObjecttypesWithLinkToTable(@maskEditor.current_mask.table.table_id)
				for table in objecttypes
					data.objecttypes.push(table.name)
				return
		]
		return options

	getDefaultOptions: ->
		defaultOptions =
			mode: "standard"
		return defaultOptions

	renderField: (opts = {}) ->
		if opts.mode != "detail"
			return

		globalObjectId = opts.top_level_data?._global_object_id
		if not globalObjectId
			return

		objecttype = opts.top_level_data._objecttype
		if not objecttype
			return

		dataOptions = @getDataOptions()
		idTable = ez5.schema.CURRENT._objecttype_by_name[objecttype].table_id
		linkedFieldNames = @__getLinkedFieldNames(idTable, dataOptions.objecttypes)

		if linkedFieldNames.length == 0
			return

		mainContent = CUI.dom.div("ez5-detail-linked-mask-splitter-content")
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
				content = @__renderObjects(objecttype, resultObjects, dataOptions.mode, opts)
				CUI.dom.append(mainContent, content)
			return
		).fail((err) =>
			# Should we do something else when there is an error?
			console.error("DetailLinkedMaskSplitter :: Error when fetching objects.", err)
			CUI.dom.empty(mainContent)
		)

		return mainContent

	__renderObjects: (objecttype, resultObjects, mode, opts = {}) ->
		objecttypeHeader = CUI.dom.div("ez5-field-block-header")
		objectsContent = CUI.dom.div("ez5-field-block-content")

		label = new CUI.Label(text: $$("detail.linked.mask.splitter.header.objecttype.title", objecttype: objecttype))
		CUI.dom.append(objecttypeHeader, label)

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

			if mode == "short"
				# In short mode we add a container div like the nested does and add all objects in it.
				condensedContainer = CUI.dom.div("ez5-nested--condensed ez5-nested--single-column")
				CUI.dom.append(objectsContent, condensedContainer)

			for index in [offset...toIndex]
				resultObject = resultObjects[index]

				div = switch mode
					when "short"
						resultObject.renderCardLinkedObjectShort()
					when "text"
						resultObject.renderTextDetail()
					when "standard"
						resultObject.renderCardLinkedObjectStandard()

				# It is necessary to add some classes to make them look like they are linked objects.
				if mode == "short"
					itemDiv = CUI.dom.div("ez5-nested-fields")
					itemField = CUI.dom.div("ez5-field")
					CUI.dom.append(itemDiv, itemField)
					CUI.dom.append(itemField, div)
					CUI.dom.append(condensedContainer, itemDiv)
				else
					horizontalLayout = new CUI.HorizontalLayout
						maximize_horizontal: true
						maximize_vertical: false
						class: "ez5-linked-object-detail ez5-linked-object linked-object-popover"
						right: {}
					horizontalLayout.replace(div, "center")

					if opts.detail
						detailTools = resultObject.getDetailTools
							detail: opts.detail
							getElement: => horizontalLayout
						horizontalLayout.replace(Toolbox.getFlyoutButtonbar(detailTools, appearance: "flat"), "right")

					CUI.dom.append(objectsContent, horizontalLayout)

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

	__getLinkedFieldNames: (idTable, objecttypes = []) ->
		linkedFieldNames = []
		for table in ez5.schema.CURRENT.tables
			for column in table.columns
				if table.owned_by
					objecttype = table.owned_by.other_table_name_hint
				else
					objecttype = table.name

				if objecttype not in objecttypes
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

	__getObjecttypesWithLinkToTable: (idTable) ->
		objecttypes = []
		for table in ez5.schema.HEAD.tables
			for column in table.columns
				if @__hasColumnLinkToTable(column, idTable)
					if table.owned_by
						objecttypeName = table.owned_by.other_table_name_hint
					else
						objecttypeName = table.name

					objecttype = ez5.schema.HEAD._objecttype_by_name[objecttypeName]
					if objecttype in objecttypes
						break
					objecttypes.push(objecttype)
					break
		return objecttypes

	__hasColumnLinkToTable: (column, idTable) ->
		return column.type == "link" and column._foreign_key.referenced_table.table_id == idTable

	isSimpleSplit: ->
		return true

	renderAsField: ->
		return true

	isEnabledForNested: ->
		return false

MaskSplitter.plugins.registerPlugin(ez5.DetailLinkedMaskSplitter)
