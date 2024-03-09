# -*- coding: utf-8 -*-
##############################################################################
#
#    Cybrosys Technologies Pvt. Ltd.
#    Copyright (C) 2019-TODAY Cybrosys Technologies(<https://www.cybrosys.com>).
#    Author: Kavya Raveendran (odoo@cybrosys.com)
#
#    You can modify it under the terms of the GNU LESSER
#    GENERAL PUBLIC LICENSE (LGPL v3), Version 3.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU LESSER GENERAL PUBLIC LICENSE (LGPL v3) for more details.
#
#    You should have received a copy of the GNU LESSER GENERAL PUBLIC LICENSE
#    GENERAL PUBLIC LICENSE (LGPL v3) along with this program.
#    If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################

import logging
import json
import re

from odoo import models, fields, api

_logger = logging.getLogger(__name__)

class ReportTimesheet(models.AbstractModel):
    _name = 'report.timesheets_by_employee.report_timesheets'

    def get_timesheets(self, docs):
        """input : name of employee and the starting date and ending date
        output: timesheets by that particular employee within that period and the total duration"""

        _logger.info(
            "Generating TimeSheet"
        )


        if docs.from_date and docs.to_date:
            rec = self.env['account.analytic.line'].search([('employee_id', '=', docs.employee[0].id),
                                                            ('date', '>=', docs.from_date),
                                                            ('date', '<=', docs.to_date)])

        elif docs.from_date:
            rec = self.env['account.analytic.line'].search([('employee_id', '=', docs.employee[0].id),
                                                            ('date', '>=', docs.from_date)])

        elif docs.to_date:
            rec = self.env['account.analytic.line'].search([('employee_id', '=', docs.employee[0].id),
                                                            ('date', '<=', docs.to_date)])

        else:
            rec = self.env['account.analytic.line'].search([('employee_id', '=', docs.employee[0].id)])

        records = {}
        total = 0
        for r in rec:
            if r.project_id and r.project_id.excl_from_printed_timesheets:
                continue
            reports = []
            hours = 0
            if r.project_id.name in records:
                reports = records[r.project_id.name]['reports']
                hours = records[r.project_id.name]['hours']
            vals = {'task': r.task_id.name,
                    'description': r.name,
                    'duration': r.unit_amount,
                    'date': r.date,
                    }
            total += r.unit_amount
            hours += r.unit_amount
            reports.append(vals)
            records[r.project_id.name] = {
                'reports': reports,
                'hours': hours
            }


        def convert(record_in):
            """We perform a group by on the task name,
            and add a subtotal line and a whiteline for every group

            We order on taskname, preferable on the WPnumber (to prevent WP10 is printed before WP1).
            """

            def calculate_total_duration(value_reports_grouped, task_name):
                return sum([record['duration'] for record in value_reports_grouped[task_name]])

            value_reports_grouped = {}
            tasks = []

            for report in record_in['reports']:
                if report['task'] is False:
                    report['task'] = ''

                value_reports_grouped.setdefault(report['task'], []).append(report)
                tasks.append(report['task'])

            tasks = list(set(tasks))

            if all([True if re.match('^WP([1-9][0-9]*):.*$', task) else False for task in tasks]):
                tasks.sort(key = lambda x: float(re.match('^WP([1-9][0-9]*):.*$', x).groups()[0]))
                tasks_names_ordered = tasks
            else:
                tasks_names_ordered = sorted(tasks)


            tasks_totals = {}
            for task_name in tasks_names_ordered:
                tasks_totals[task_name] = calculate_total_duration(value_reports_grouped, task_name)

            project_without_tasks = False
            if all([True if task == '' else False for task in tasks_names_ordered]):
                project_without_tasks = True

            value_reports_new = []
            for task_name in tasks_names_ordered:
                value_reports_new.extend(value_reports_grouped[task_name])


                subtotal_line = {'task': '' if project_without_tasks else ' ',
                                 'description': ' ',
                                 'duration': tasks_totals[task_name],
                                 'date': 'SubTotal'}
                value_reports_new.append(subtotal_line)

                empty_line = {'task': '' if project_without_tasks else ' ',
                              'description': 'WHITELINE',
                              'duration': -1,
                              'date': ''}
                value_reports_new.append(empty_line)


            record_in['reports'] = value_reports_new

            return record_in


        def group_and_order_tasks(records_in):

            for record_name in records_in:
                records_in[record_name] = convert(records_in[record_name])

            return records_in


        records = group_and_order_tasks(records)

        return [records, total]

    @api.model
    def _get_report_values(self, docids, data=None):
        """we are overwriting this function because we need to show values from other models in the report
        we pass the objects in the docargs dictionary"""
        docs = self.env['timesheet.wizard'].browse(self.env.context.get('active_id'))
        identification = []
        for i in self.env['hr.employee'].search([('id', '=', docs.employee[0].id)]):
            if i:
                identification.append({'id': i.id, 'name': i.name})
        timesheets = self.get_timesheets(docs)
        company_name = self.env['res.company'].search([('name', '=', docs.employee[0].company_id.name)])
        period = None
        if docs.from_date and docs.to_date:
            period = "From " + str(docs.from_date) + " To " + str(docs.to_date)
        elif docs.from_date:
            period = "From " + str(docs.from_date)
        elif docs.from_date:
            period = " To " + str(docs.to_date)
        if len(identification) > 1:
            return {
                'doc_ids': self.ids,
                # 'doc_model': self.model,
                'docs': docs,
                'timesheets': timesheets[0],
                'total': timesheets[1],
                'company': company_name,
                'identification': identification,
                'period': period,
            }
        else:
            return {
                'doc_ids': self.ids,
                # 'doc_model': self.model,
                'docs': docs,
                'timesheets': timesheets[0],
                'total': timesheets[1],
                'identification': identification,
                'company': company_name,
                'period': period,
            }
