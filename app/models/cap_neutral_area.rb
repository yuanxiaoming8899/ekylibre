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
# == Table: cap_neutral_areas
#
#  cap_statement_id :integer(4)       not null
#  category         :string           not null
#  created_at       :datetime         not null
#  creator_id       :integer(4)
#  id               :integer(4)       not null, primary key
#  lock_version     :integer(4)       default(0), not null
#  nature           :string           not null
#  number           :string           not null
#  shape            :geometry({:srid=>4326, :type=>"geometry"}) not null
#  updated_at       :datetime         not null
#  updater_id       :integer(4)
#

class CapNeutralArea < ApplicationRecord
  belongs_to :cap_statement
  has_one :campaign, through: :cap_statement
  has_geometry :shape, type: :multi_polygon
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :category, :nature, :number, presence: true, length: { maximum: 500 }
  validates :cap_statement, :shape, presence: true
  # ]VALIDATORS]

  delegate :pacage_number, to: :cap_statement

  alias net_surface_area shape_area

  scope :of_campaign, lambda { |*campaigns|
    joins(:cap_statement).merge(CapStatement.of_campaign(*campaigns))
  }
end
