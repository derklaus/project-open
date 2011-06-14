/**
 * intranet-sencha-ticket-tracker/www/TicketForm.js
 * Ticket form to allow modifying and creating new tickets.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: TicketFilterForm.js.adp,v 1.16 2011/06/14 09:01:16 po34demo Exp $
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

var ticketFilterForm = Ext.define('TicketBrowser.TicketFilterForm', {
	extend:		'Ext.form.Panel',	
	alias:		'widget.ticketFilterForm',
	title:		'#intranet-sencha-ticket-tracker.Ticket_Filters#',
	id:		'ticketFilterForm',
	bodyStyle:	'padding:5px 5px 0',
	defaultType:	'textfield',
	defaults:	{ anchor: '100%' },
	minWidth:	200,
	standardsubmit:	true,
	items: [
	{	name: 'assigned_queue_id', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Group#',
		xtype: 'combobox',
                valueField: 'group_id',
                displayField: 'group_name',
		emptyText: '#intranet-sencha-ticket-tracker.My_Groups#',
		forceSelection: true,
		queryMode: 'remote',
		store: profileStore,
		width: 300
	}, {
		name: 'assigned_user_id',
		fieldLabel: '#intranet-sencha-ticket-tracker.Assigned_to#',
                xtype:          'combobox',
                fieldLabel:     '#intranet-core.User#',
                value:          '#intranet-core.New_User#',
                valueField:     'user_id',
                displayField:   'name',
                store:          userStore
	}, {
		name: 'vat_number', 
		fieldLabel: '#intranet-core.VAT_Number#'
	}, {	
		name: 'company_name', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Company_Name#'
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Company_Type#',
		name: 'company_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: companyTypeStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Program#',
		name: 'ticket_area',
		xtype: 'combobox',
		displayField:	'pretty_name',
		valueField:	'category_id',
		store:		ticketAreaStore,
		queryMode:	'local',
        	triggerAction:  'all',
        	width: 		300,
        	editable:       false,
		forceSelection: true
	}, {
		name: 'ticket_file', 
		fieldLabel: '#intranet-sencha-ticket-tracker.Ticket_File_Number#'
	}, {
		fieldLabel: '#intranet-helpdesk.SLA#',
		name: 'parent_id',
		xtype: 'combobox',
                valueField: 'project_id',
                displayField: 'project_name',
		allowBlank: true,
		forceSelection: true,
		queryMode: 'remote',
		store: ticketSlaStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Ticket_Type#',
		name: 'ticket_type_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketTypeStore
	}, {
		fieldLabel: '#intranet-helpdesk.Ticket_Nr#',
		name: 'project_name',
		value: '636'
	}, {
		fieldLabel: '#intranet-helpdesk.Status#',
		name: 'ticket_status_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category_translated',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketStatusStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Incoming_Channel#',
		name: 'ticket_channel_id',
		xtype: 'combobox',
                valueField: 'category_id',
                displayField: 'category',
		forceSelection: true,
		queryMode: 'remote',
		store: ticketChannelStore
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Date_Since#',
		name: 'start_date',
		xtype: 'datefield',
		format: 'Y-m-d',
		submitFormat: 'Y-m-d'
	}, {
		fieldLabel: '#intranet-sencha-ticket-tracker.Date_Until#',
		name: 'end_date',
		xtype: 'datefield',
		format: 'Y-m-d',
		submitFormat: 'Y-m-d'
	}
	],

	buttons: [{
            text: '#intranet-sencha-ticket-tracker.Clear_Form#',
	    handler: function(){
		var form = this.up('form').getForm();
		form.reset();
	    }
	}, {
            text: '#intranet-sencha-ticket-tracker.button_Search#',
	    handler: function() {
		var form = this.up('form').getForm();
		var filterValues = form.getFieldValues();
		var grid = Ext.getCmp('ticketGrid');
	
		grid.filterTickets(filterValues);
	}

	}],

	afterRender: function() {
		var filterForm = Ext.getCmp('ticketFilterForm');
		var form = filterForm.getForm();
		var filterValues = form.getFieldValues();
		var grid = Ext.getCmp('ticketGrid');
		grid.filterTickets(filterValues);
		return true;
	}

});


