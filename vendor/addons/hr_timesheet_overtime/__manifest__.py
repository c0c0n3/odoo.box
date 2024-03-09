# -*- coding: utf-8 -*-

##############################################################################
#
#    Clear Groups for Odoo
#    Copyright (C) 2016 Bytebrand GmbH (<http://www.bytebrand.net>).
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Lesser General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Lesser General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

{
    'name': "Timesheet Overtime",
    'author': "Martel Innovate",
    "version": "14.0.1.0.0",
    'summary': 'Track over- and under-time based on timesheets (no attendance required), generate timesheets',
    'website': "http://www.martel-innovate.com",
    'category': 'Human Resources',
    'depends': ['hr_timesheet_sheet', 'hr_contract', 'hr_holidays'],
    'images': ['images/overundertime.png'],
    'installable': True,
    'application': False,
    'data': [
        'security/ir.model.access.csv',
        'views/views.xml',
        # View file for the wizard
        'wizard/timesheet_tag.xml', 
    ]
}
