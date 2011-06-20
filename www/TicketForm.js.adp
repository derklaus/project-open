/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id$
 *
 * Copyright (C) 2011, ]project-open[
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


var ticketInfoPanel = Ext.define('TicketBrowser.TicketForm', {
	extend: 	'Ext.form.Panel',	
	alias: 		'widget.ticketForm',
	id:		'ticketForm',
	standardsubmit:	false,
	frame:		true,
	title: 		'#intranet-core.Ticket#',
	bodyStyle:	'padding:5px 5px 0',
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 75
	},
	defaultType:	'textfield',
	defaults: {
	        mode:           'local',
	        queryMode:      'local',
	        value:          '',
	        displayField:   'pretty_name',
	        valueField:     'id'
	},
	items: [

	// Variables for the new.tcl page to recognize an ad_form
	{ name: 'ticket_id',		xtype: 'hiddenfield' },
	{ name: 'ticket_creation_date', xtype: 'hiddenfield' },
	{ name: 'ticket_status_id',	xtype: 'hiddenfield', value: 30000 },	// Open by default
	{ name: 'ticket_queue_id',	xtype: 'hiddenfield', value: 463 },	// Assign to Employees by default
	{ name: 'fs_folder_id',		xtype: 'textfield', disabled: true },	// Assign to Employees by default
	{ name: 'project_nr',		xtype: 'hiddenfield' },
	{ 	// Anonimous User
		name: 'ticket_customer_contact_id',
		xtype: 'hiddenfield',
		value: <%= [db_string anon "select user_id from users where username = 'anonimo'" -default 624] %>
	},
	{ 	// Anonimous SLA
		name: 'parent_id',
		xtype: 'hiddenfield',
		value: <%= [db_string anon "select project_id from im_projects where project_nr = 'anonimo'" -default 0] %>
	},
	{ 	// Anonimous Company
		name: 'company_id',
		xtype: 'hiddenfield',
		value: <%= [db_string anon "select company_id from im_companies where company_path = 'anonimo'" -default 0] %>
	},

	// Main ticket fields
	{
		name:		'project_name', 
		itemId:		'project_name',
		fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_Name#',
		disabled:	false,
        	width: 		300
	}, {
	        fieldLabel:	'#intranet-helpdesk.Ticket_type#',
		name:		'ticket_type_id',
		xtype:		'combobox',
        	width: 		300,
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		queryMode: 	'remote',
		store: 		ticketTypeStore,
		allowBlank:	false,			// Require a value for this one
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		}
	}, {
		name:		'ticket_area_id',
		itemId:		'ticket_area_id',
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Area#',
		xtype:		'combobox',
        	width: 		300,
                valueField:	'category_id',
                displayField:	'category_translated',
		forceSelection: true,
		queryMode: 	'remote',
		store: 		ticketAreaStore,
		listConfig: {
			getInnerTpl: function() {
                		return '<div class={indent_class}>{category_translated}</div>';
			}
		},
		listeners:{
		    // The user has selected a program/area from the drop-down box.
		    // Now construct a new ProgramGroupStore based on this information
		    // with only those groups/profiles that are assigned to the program
		    'change': function() {

			// Set the default code for the new ticket
			var programId = this.getValue();
			if (null != programId) {
				var programModel = ticketAreaStore.findRecord('category_id', programId);
				var programName = programModel.get('category');
				var programFile = programModel.get('aux_string1');
				var fileField = this.ownerCt.child('#ticket_file');
				fileField.setValue(programFile);

				// Remove all elements from the store
				programGroupStore = new Ext.data.ArrayStore({
					model:		'TicketBrowser.Profile',
					autoDestroy:	true
				});
	
				// Get the row with the list of groups enabled for this area:
	                        var mapRow = SPRIProgramGroupMap.findRecord('Programa', programName);
				if (null == mapRow) {
					alert('Configuration Error:\nProgram "'+programName+'" not found');
					return;
				}
	
				// loop through the groups in the profile store and add them
				// to the programGroupStore IF it's enabled for this program.
				for (var i = 0; i < profileStore.getCount(); i++) {
					var profileModel = profileStore.getAt(i);
					var profileName = profileModel.get('group_name');
					var enabled = mapRow.get(profileName);
					if (enabled != null && enabled != '') {
						programGroupStore.insert(0, profileModel);
					}
				}
			}
		    }
		}


	}, {
		name:		'ticket_file',
		itemId:		'ticket_file',
	        fieldLabel:	'#intranet-sencha-ticket-tracker.Ticket_File_Number#',
        	width: 		300,
	        xtype:		'textfield'
	}],

	buttons: [{
	    itemId:	'saveButton',
            text:	'#intranet-sencha-ticket-tracker.button_Save#',
            disabled:	false,
            formBind:	true,
	    handler: function(){

		// get the form and all of its values
		var form = this.up('form').getForm();
		var values = form.getFieldValues();
		var value;

		// find out the ticket_id
		var ticket_id_field = form.findField('ticket_id');
		var ticket_id = ticket_id_field.getValue();

		if ('' == ticket_id) {

			// Disable the form until the ticket_id has arrived
			this.setDisabled(true);

			// create a new ticket
			var ticket_record = Ext.ModelManager.create(values, 'TicketBrowser.Ticket');
			ticket_record.phantom = true;
			ticket_record.save({
				scope: Ext.getCmp('ticketForm'),
				success: function(record, operation) {
					// This code is called once the reply from the server has arrived.
					// The server response includes data.object_id for the new object.
					try {
						var resp = Ext.decode(operation.response.responseText);
						var ticket_id = resp.data[0].object_id + '';
					} catch (ex) {
						alert('Error creating object.\nThe server returned:\n' + operation.response.responseText);
						return;
					}

					if (null == ticket_id) { alert('Creating the object completely failed'); return; }	

					// Extract all fields of the new object, including the ones in this form.
					var ticketForm = Ext.getCmp('ticketForm').getForm();
					var form_values = ticketForm.getFieldValues();
					form_values.ticket_id = ticket_id;
					form_values.ticket_creation_date = '<%= [db_string today "select to_char(now(), 'YYYY-MM-DD')"] %>';

					// The ticket_id has arrived, so we can show the rest
					this.setDisabled(false);

					// Tell all panels to load the data of the newly created object
					var ticket_model= Ext.ModelManager.create(form_values, 'TicketBrowser.Ticket');
					ticketStore.add(ticket_model);
					var compoundPanel = Ext.getCmp('ticketCompoundPanel');
					compoundPanel.loadTicket(ticket_model);	
				}
			});

		} else {

			// Update an existing ticket
			// Loop through all form fields and store into the ticket store
			var ticket_record = ticketStore.findRecord('ticket_id',ticket_id);
			for(var field in values) {
				if (values.hasOwnProperty(field)) {
					value = values[field];
					ticket_record.set(field, value);
				}
			}
	
			// Tell the store to update the server via it's REST proxy
			ticketStore.sync();

			// Update this and the other ticket forms
			var compoundPanel = Ext.getCmp('ticketCompoundPanel');
			compoundPanel.loadTicket(ticket_record);

		}
	    }
	}],

	loadTicket: function(rec){
		this.loadRecord(rec);
	},

	// Somebody pressed the "New Ticket" button:
	// Prepare the form for entering a new ticket
	newTicket: function() {
	        var form = this.getForm();
	        form.reset();

		// Ask the server to provide a new ticket name
		this.setNewTicketName();
	},
	
	// Determine the new of the new ticket. Send an async AJAX request 
	// to the server and tell the callback to insert the new ticket number
	// into the project_name field in this form.
	setNewTicketName: function() {
	    Ext.Ajax.request({
		scope:	this,
		url:	'/intranet-sencha-ticket-tracker/ticket-next-nr',
		success: function(response) {
		    // ticket-next-nr just returns a string which represents the name
		    var ticket_nr = response.responseText;
		    var form = this.getForm();
		    form.findField('project_nr').setValue(ticket_nr);
		    var ticket_name = '#intranet-sencha-ticket-tracker.New_Ticket_Prefix#' + ticket_nr;
		    form.findField('project_name').setValue(ticket_name);
		},
		failure: function(response) {
		    alert('#intranet-sencha-ticket-tracker.Failed_to_get_new_ticket_nr#');
		}
	    });
	}
});

