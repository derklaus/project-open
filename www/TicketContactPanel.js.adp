/**
 * intranet-sencha-ticket-tracker/www/TicketContainer.js
 * Container for both TicketGrid and TicketForm.
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


Ext.define('TicketBrowser.TicketContactPanel', {
	extend: 'Ext.form.Panel',
        alias: 'widget.ticketContact',
	title: 'Ticket Contact',
	frame:true,
	height: 400,
	fieldDefaults: {
		msgTarget: 'side',
		labelWidth: 125
	},
        items: [{
                name:           'user_id',
                xtype:          'combobox',
                fieldLabel:     '#intranet-core.User#',
                value:          '#intranet-core.New_User#',
		valueNotFoundText: 'Create a new User',
                valueField:     'user_id',
                displayField:   'name',
                store:          userStore,
		listeners:{
		    // The user has selected a user from the drop-down box.
		    // Lookup the user and fill the form with the fields.
		    'select': function() {
			var user_id = this.getValue();
			var user_record = userStore.findRecord('user_id',user_id);
		        if (user_record == null || typeof user_record == "undefined") { return; }
			this.ownerCt.loadRecord(user_record);
		    }
		}
        }, {
            xtype:	'fieldset',
            title:	'User Information',
            checkboxToggle: false,
            defaultType: 'textfield',
            collapsed:	false,
	    frame:	false,
            layout: 	'hbox',
            defaults:	{ anchor: '50%'  },
            items :[{
	                name:           'first_names',
	                xtype:          'textfield',
	                fieldLabel:     '#intranet-core.First_names#',
	                allowBlank:     false
	        }, {
	                name:           'last_name',
	                xtype:          'textfield',
	                fieldLabel:     '#intranet-core.Last_name#'
	    }]
	}, {
                name:           'ticket_sex',
                xtype:          'radiofield',
                fieldLabel:     '#intranet-core.Gender#',
                boxLabel:       '#intranet-core.Male#',
                value:          '1'
        }, {
                name:           'ticket_sex',
                xtype:          'radiofield',
                boxLabel:       '#intranet-core.Female#',
                value:          '0',
                fieldLabel:     '',
                labelSeparator: '',
                hideEmptyLabel: false
        }],
        buttons: [{
        	text: 'New Contact',
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			form.reset();			// empty fields to allow for entry of new contact
			var combo = form.findField('user_id');
		}
	}, {
        	text: 'Save Changes',
        	handler: function(){
			// Get the values of this form into the "values" object
			var form = this.ownerCt.ownerCt.getForm();
			var user_id = form.findField('user_id').getValue();
			var values = form.getFieldValues();

			// Search for previous row in the store
			var rec = userStore.findRecord('user_id',user_id);

			// overwrite the store data with the new data
			rec.set(values);
			// now the store should automatically update the values
			// using it's REST proxy
                }
	}, {
        	text: 'Create New Contact',
        	handler: function(){
			var form = this.ownerCt.ownerCt.getForm();
			var values = form.getFieldValues();

			// add the form values to the store.
			userStore.add(values);
			// the store should create a new object now (does he?)
                }
        }],

	loadTicket: function(rec){

		// Customer contact ID, may be NULL
		var contact_id = rec.data.ticket_customer_contact_id;
		var contact_record = userStore.findRecord('user_id',contact_id);
	        if (contact_record == null || typeof contact_record == "undefined") { return; }

		// load the information from the record into the form
		this.loadRecord(contact_record);
	}

});

