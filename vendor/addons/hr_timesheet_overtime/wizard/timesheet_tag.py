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


import time
from odoo import fields, models, api, _
from odoo.exceptions import ValidationError

class CreateTimesheetWithTag(models.TransientModel):
    _name = "hr_timesheet.generate_wizard"
    _description = 'Create Timesheet With Employee Tag'

    # Added below fields on the wizard
    category_id = fields.Many2one(
        string="Employee Tag",
        comodel_name="hr.employee.category",
    )
    date_start = fields.Date(string='Start Date')
    date_end = fields.Date(string='End Date')


    @api.onchange('date_start', 'date_end')
    def change_date(self, date_start=None, date_end=None):
        if date_end and date_start and date_start > date_end:
            raise ValidationError(
                _('You added wrong date period.'))


    @api.model
    def create(self, values):
        if values.get('date_end') and values.get('date_start') \
                and values.get('date_start') > values.get('date_end'):
            raise ValidationError(
                _('You added wrong date period.'))
        return super(CreateTimesheetWithTag, self).create(values)


    def open_timesheet(self):
        employee_obj = self.env['hr.employee']
        ts = self.env['hr_timesheet.sheet']

        #set up view to be generated
        value = {
            'type': 'ir.actions.act_window',
            'name': 'Generated Timesheets',
            'res_model': 'hr_timesheet.sheet',
            'view_mode': 'tree,form',
            'target': 'current',
        }

        if not self.category_id:
            return {}
        category_id = self.category_id.id
        company_id = self.env.company.id
        # First: Search all employees of selected Tag
        employee_objects = employee_obj.search([
            ('category_ids', 'in', [category_id]),
            ('company_id', 'in', [company_id])])

        user_ids = []
        ts_ids = []
        date_start = self.date_start or time.strftime('%Y-%m-%d')
        date_end = self.date_end or time.strftime('%Y-%m-%d')
        # Second: Create for all fetched employees.
        for emp in employee_objects:

            if emp.user_id:
                user_ids.append(emp.user_id.id)
                ts_id = ts.search([
                    ('user_id', '=', emp.user_id.id),
                    ('state', 'in', ('draft', 'new')),
                    ('date_start', '<=', date_start),
                    ('date_end', '>=', date_end),
                    ('company_id', 'in', [company_id])
                ])
                if ts_id:
                    raise ValidationError(
                        _('Timesheet already exists for {name}.'.format(
                                name=emp.name)))
                if not ts_id:
                    values = {'employee_id': emp.id}
                    if self.date_start and self.date_end:
                        values.update({
                            'date_start': date_start,
                            'date_end': date_end})
                    if emp.department_id:
                        values.update({
                            'department_id': emp.department_id.id
                        })

                    if emp.company_id:
                        values.update({
                            'company_id': emp.company_id.id
                        })
                    ts_id = ts.create(values)

                ts_ids.append(ts_id.id)

        # Third: Add it to dictionary to be returned
        domain = "[('id','in',%s),('user_id', 'in', %s)]" % (ts_ids, user_ids)
        value.update(domain=domain)
        value.update(view_mode='tree,form')
        return value

# END
