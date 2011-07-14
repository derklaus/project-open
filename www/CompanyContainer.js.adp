/**
 * intranet-sencha-company-tracker/www/CompanyContainer.js
 * Container for both CompanyGrid and CompanyForm.
 *
 * @author Frank Bergmann (frank.bergmann@project-open.com)
 * @creation-date 2011-05
 * @cvs-id $Id: CompanyContainer.js.adp,v 1.4 2011/07/14 16:01:33 po34demo Exp $
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


Ext.define('TicketBrowser.CompanyContainer', {
	extend: 'Ext.container.Container',
	alias: 'widget.companyContainer',
	title: '#intranet-sencha-ticket-tracker.Loading___#',

	layout: 'border',

	items: [{
		itemID:	'companyFilter',
		xtype:	'companyFilterForm',
		region:	'west',
		width:	300,
		title:	'#intranet-helpdesk.Filter_Companys#',
		split:	true,
		margins: '5 0 5 5'
	}, {
		itemId:	'main3',
		title:	'#intranet-sencha-ticket-tracker.Companies#',
		region:	'center',
		layout:	'border',
		split:	true,
		items:	[{
			itemId:	'companyGrid',
			xtype:	'companyGrid',
			region:	'center'
		}]
	}],

	initComponent: function(){
		this.callParent();
	},

	afterLayout: function() {
		this.callParent();
		// IE6 likes to make the content disappear, hack around it...
		if (Ext.isIE6) { this.el.repaint(); }
	},
	
	filterTickets: function(filterValues) {
		this.tab.setText('Filtered Tickets');
		this.child('#ticketGrid').filterTickets(filterValues);
	},
	
	togglePreview: function(show){
		var preview = this.child('#preview');
		if (show) {
			preview.show();
		} else {
			preview.hide();
		}
	},

	toggleGrid: function(show){
		var grid = this.child('#ticketGrid');
		if (show) {
			grid.show();
		} else {
			grid.hide();
		}
	}

});