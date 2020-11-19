class ez5.DetailLinkedMaskSplitter extends CustomMaskSplitter

	getOptions: ->
		options = [
			form:
				label: $$("detail.linked.mask.splitter.options.style")
			type: CUI.Select
			name: "style"
			options: [
				text: $$("detail.linked.mask.splitter.options.style.list")
				value: "list"
			,
				text: $$("detail.linked.mask.splitter.options.style.standard")
				value: "standard"
			]
		]
		return options

	renderField: (opts = {}) ->
		console.log(opts)

		globalObjectId = opts.top_level_data?._global_object_id
		if not globalObjectId
			return

		objecttype = opts.top_level_data._objecttype
		if not objecttype
			return

		content = CUI.dom.div()
		spinner = new LocaLabel(loca_key: "detail.linked.mask.splitter.detail.spinner")
		CUI.dom.append(content, spinner)

		idTable = ez5.schema.CURRENT._objecttype_by_name[objecttype].table_id
		@__findLinkedObjects(idTable, globalObjectId).done((data) =>
			CUI.dom.empty(content)
			console.log(data.objects)
			if data.objects.length == 0
				# TODO: What happens when there are no objects? Show a label? hide the splitter?
				return

			# TODO: Some some kind of title? Show some kind of container like nested?
			for object in data.objects
				resultObject = new ResultObject().setData(object)
				options = @getDataOptions()
				if options.style == "list"
					CUI.dom.append(content, resultObject.renderCardResultList())
				else if options.style == "standard"
					CUI.dom.append(content, resultObject.renderCardStandard()) # Needs some style
			return
		).fail(=>
			# TODO: What happens when there is an error? should we show an error message?
		)

		return content


	__findLinkedObjects: (idTable, globalObjectId) ->
		linkedFieldNames = []
		for table in ez5.schema.CURRENT.tables
			for column in table.columns
				if not (column.type == "link" and column._foreign_key.referenced_table.table_id == idTable)
					continue
				fieldName = "#{table.name}.#{column.name}._global_object_id"
				if table.owned_by
					fieldName = "#{table.owned_by.other_table_name_hint}._nested:#{fieldName}"
				linkedFieldNames.push(fieldName)

		return ez5.api.search
			json_data:
				format: "standard"
				search: [
					type: "in"
					fields: linkedFieldNames
					in: [globalObjectId]
				]

	isSimpleSplit: ->
		return true

	renderAsField: ->
		return true

	isEnabledForNested: ->
		return false

MaskSplitter.plugins.registerPlugin(ez5.DetailLinkedMaskSplitter)
