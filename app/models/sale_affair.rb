# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: affairs
#
#  accounted_at           :datetime
#  cash_session_id        :integer(4)
#  closed                 :boolean          default(FALSE), not null
#  closed_at              :datetime
#  created_at             :datetime         not null
#  creator_id             :integer(4)
#  credit                 :decimal(19, 4)   default(0.0), not null
#  currency               :string           not null
#  dead_line_at           :datetime
#  deals_count            :integer(4)       default(0), not null
#  debit                  :decimal(19, 4)   default(0.0), not null
#  description            :text
#  id                     :integer(4)       not null, primary key
#  journal_entry_id       :integer(4)
#  letter                 :string
#  lock_version           :integer(4)       default(0), not null
#  name                   :string
#  number                 :string
#  origin                 :string
#  pretax_amount          :decimal(19, 4)   default(0.0)
#  probability_percentage :decimal(19, 4)   default(0.0)
#  responsible_id         :integer(4)
#  state                  :string
#  third_id               :integer(4)       not null
#  type                   :string
#  updated_at             :datetime         not null
#  updater_id             :integer(4)
#
class SaleAffair < Affair
  belongs_to :client, class_name: 'Entity', foreign_key: :third_id

  # Permit to attach a deal from affair
  def attach(deal)
    unless deal.deal_third == client
      raise "Cannot deal with a different client in this SaleAffair (ID=#{id})"
    end

    deal.deal_with!(self)
  end

  def gap_class
    SaleGap
  end

  def third_role
    :client
  end
end
