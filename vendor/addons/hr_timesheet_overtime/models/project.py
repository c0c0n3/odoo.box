# -*- coding: utf-8 -*-

from odoo import fields, models




class Project(models.Model):
    _inherit = 'project.project'

    excl_from_printed_timesheets = fields.Boolean("Exclude from printed timesheets")


