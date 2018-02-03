React = require "react"
{Modal,Nav,NavItem} = require("react-bootstrap")

State = require "../state"
SchemaUtils = require "../helpers/schema-utils"
BundleUtils = require "../helpers/bundle-utils"


class ExportDialog extends React.Component

	shouldComponentUpdate: (nextProps) ->
		nextProps.show isnt @props.show

	handleClose: (e) ->
		State.trigger "set_ui", "ready"

	buildJson: ->
		[resource, errCount] = SchemaUtils.toFhir @props.resource, true
		if @props.bundle then resource = 
			BundleUtils.generateBundle @props.bundle.resources, @props.bundle.pos, resource 		
		jsonString = JSON.stringify resource, null, 3
		{jsonString:jsonString, errCount:errCount, resourceType:resource.resourceType}

	handleDownload: (e) ->
		e.preventDefault()
		{jsonString, resourceType} = @buildJson()
		fileName = resourceType.toLowerCase() + ".json"
		blob = new Blob [jsonString], {type: "text/plain;charset=utf-8"}
		saveAs blob, fileName

	handleUpdate: (e) ->
		e.preventDefault()
		resid = $('#resource_id').val()
		posturl = '/fhir/fhir/' + $('#resource_type').val() + '/' + resid
		#postdata = JSON.stringify( { "resource-create-body": jsonString, "resource-create-id": resid } )
		{jsonString, resourceType} = @buildJson()
		$.ajax posturl,

            type: 'PUT'
            #dataType: 'json'
            contentType: 'application/json+fhir'
            data: jsonString
            error: (jqXHR, textStatus, errorThrown) ->
        	    $('body').append "AJAX Error: #{textStatus}"
            success: (data, textStatus, jqXHR) ->
        	    $('body').append "Successful AJAX call: #{data}"

	#help the user with a select all if they hit the
	#control key with nothing selected
	handleKeyDown: (e) ->
		if e.ctrlKey or e.metaKey
			domNode = @refs.jsonOutput
			domNode.focus()
			if domNode.selectionStart is domNode.selectionEnd and
				domNode.setSelectionRange
					domNode.setSelectionRange(0, domNode.value.length)
					@copying = true

	handleKeyUp: (e) ->
		if @copying
			@copying = false
			@refs.jsonOutput.setSelectionRange(0, 0)

	render: ->
		return null unless @props.show

		{jsonString, errCount} = @buildJson()

		errNotice = if errCount > 0
			<div className="alert alert-danger">Note that the current resource has unresolved data entry errors</div>

		<Modal show={true} onHide={@handleClose.bind(@)} 
			onKeyDown={@handleKeyDown.bind(@)} onKeyUp={@handleKeyUp.bind(@)}
		>
			<Modal.Header closeButton>
				<Modal.Title>Export JSON</Modal.Title>
			</Modal.Header>
			<Modal.Body>
				{errNotice}
				<textarea readOnly ref="jsonOutput"
					className="form-control"
					style={height:"300px"}
					value={jsonString}
				/><br/>
				<input id="resource_id" type="text"/>
				<select id="resource_type">
				<option value="Questionnaire">Questionnaire</option>
				<option value="DataElement">DataElement</option>
				</select>
				<p className="small">*Press Ctrl+C / Command+C to copy json text to system clipboard</p>
			</Modal.Body>
			<Modal.Footer>
				<button className="btn btn-default" onClick={@handleDownload.bind(@)}>
					Download
				</button>
				<button className="btn btn-default" onClick={@handleUpdate.bind(@)}>
					Update
				</button>
			</Modal.Footer>
		</Modal>



module.exports = ExportDialog