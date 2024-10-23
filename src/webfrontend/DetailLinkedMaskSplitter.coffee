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
		if ez5.version("6")
			options.push
				form:
					label: $$("detail.linked.mask.splitter.options.include_inherited")
				type: CUI.Checkbox
				name: "include_inherited"
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

		if CUI.util.isEmpty(linkedFieldNames)
			return

		mainContent = CUI.dom.div("ez5-detail-linked-mask-splitter-content")
		spinner = new LocaLabel(loca_key: "detail.linked.mask.splitter.detail.spinner")
		CUI.dom.append(mainContent, spinner)

		@__searchByLinkedFieldNames(linkedFieldNames, globalObjectId, dataOptions.mode).done((dataByObjecttype) =>
			CUI.dom.empty(mainContent)

			for data in dataByObjecttype
				if data.objects.length == 0
					continue

				# Order the objects alphabetically by the standard text.
				data.objects.sort( (a,b) =>
					standardNameA = ez5.loca.getBestFrontendValue(a._standard?["1"]?.text)
					standardNameB = ez5.loca.getBestFrontendValue(b._standard?["1"]?.text)
					if standardNameA and standardNameB
						return standardNameA.localeCompare(standardNameB)
					return 0
				)

				objecttype = data.objecttypes[0]
				resultObjects = []
				for object in data.objects
					resultObjects.push(new ResultObject().setData(object))

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
		linkedFieldNames = {}

		objecttypeManager = new ObjecttypeManager()
		objecttypeManager.addObjecttypes((table, mask) =>
			if table.name() not in objecttypes
				return false
			return mask.schema.is_preferred
		)

		for field in objecttypeManager.getAllFields()
			columnSchema = field.ColumnSchema

			if not @__hasColumnLinkToTable(columnSchema, idTable)
				continue

			if not @__isFieldSearchable(field)
				continue

			table = field.table.schema
			table_name = table.name
			fieldName = "#{table_name}.#{columnSchema.name}._global_object_id"
			if table.owned_by
				nestedName = @__getNestedLinkedFieldName(table)
				fieldName = "#{nestedName}#{fieldName}"

			objecttype = fieldName.split(".")[0] # The first string on the field name is the objecttype

			if ez5.version("6") and not @getDataOptions().include_inherited and field.isInherited()
				# On Fylr we have inheritance on fields, so we add the fields name that support inheritance to the list.
				# We only need this when we dont want to include inherited fields. Because we need to do a complex search
				# to exclude the inherited fields.
				# If we want to include inherited fields we dont need to do a complex search. Because the normal search will
				# return the inherited fields.
				fn = fieldName.replace("._global_object_id", "")
				linkedFieldNames[objecttype] ?= []
				linkedFieldNames[objecttype].push("#{fn}:inherited")

			linkedFieldNames[objecttype] ?= []
			linkedFieldNames[objecttype].push(fieldName)
		return linkedFieldNames

	__searchByLinkedFieldNames: (linkedFieldNamesPerObjecttype, globalObjectId, mode) ->
		dfr = new CUI.Deferred()
		searches = []
		results = []
		mode = if mode == "text" then "long" else mode

		for objecttype, linkedFieldNames of linkedFieldNamesPerObjecttype

			inheritedLinkeds = []
			for linkedFieldName in linkedFieldNames
				if ez5.version("6") and linkedFieldName.indexOf(":inherited") > -1
					inheritedLinkeds.push(linkedFieldName)

			if inheritedLinkeds.length > 0
				for inheritedLinked in inheritedLinkeds
					# Remove the inheritedLinked element from linkedFieldName
					linkedFieldNames.splice(linkedFieldNames.indexOf(inheritedLinked), 1)
				# If we have inherited linked fields we need to do a complex search.
				# We need to search for the globalObjectId in the linkedFieldNames and
				# exclude the linkedFields that the value is inherited.
				searchPromise = ez5.api.search
					data:
						debug: "DetailMaskSplitterSearch"
					json_data:
						limit: 1000
						format: mode
						objecttypes: [objecttype]
						search: [
							type: "complex"
							bool: "must"
							search: [
								type: "in"
								fields: linkedFieldNames
								in: [globalObjectId]
							,
								type: "in"
								fields: inheritedLinkeds
								in: [false]
							]
						]
				searchPromise.done( (result) =>
					results.push(result)
				)
			else
				searchPromise = ez5.api.search
					data:
						debug: "DetailMaskSplitterSearch"
					json_data:
						limit: 1000
						format: mode
						objecttypes: [objecttype]
						search: [
							type: "in"
							fields: linkedFieldNames
							in: [globalObjectId]
						]
				searchPromise.done( (result) =>
					results.push(result)
				)

			searches.push(searchPromise)

		CUI.when(searches).done( =>
			dfr.resolve(results)
		).fail((err) =>
			dfr.reject(err)
		)

		return dfr.promise()

	__getObjecttypesWithLinkToTable: (idTable) ->
		objecttypes = []

		objecttypeManager = new ObjecttypeManager(version: "HEAD")
		objecttypeManager.addObjecttypes((table, mask) =>
			return mask.schema.is_preferred
		)

		for field in objecttypeManager.getAllFields()
			columnSchema = field.ColumnSchema
			if @__hasColumnLinkToTable(columnSchema, idTable) and @__isFieldSearchable(field)
				objecttype = field.getMainMask().table.schema
				if objecttype in objecttypes
					continue
				objecttypes.push(objecttype)

		return objecttypes

	__getNestedLinkedFieldName: (table) ->
		if not table
			return

		if not table.owned_by
			return ""

		ownerTable = ez5.schema.CURRENT._table_by_id[table.owned_by.other_table_id]
		return @__getNestedLinkedFieldName(ownerTable) + ownerTable.name + "._nested:"

	hasContent: () ->
		return true

	__hasColumnLinkToTable: (column, idTable) ->
		return column and column.type == "link" and column._foreign_key.referenced_table.table_id == idTable

	__isFieldSearchable: (field) ->
		if not field
			return true

		fatherField = field.getFatherField()
		return @__isFieldSearchable(fatherField) and field.isVisible("expert")

	isSimpleSplit: ->
		return true

	renderAsField: ->
		return true

	isEnabledForNested: ->
		return false

MaskSplitter.plugins.registerPlugin(ez5.DetailLinkedMaskSplitter)
