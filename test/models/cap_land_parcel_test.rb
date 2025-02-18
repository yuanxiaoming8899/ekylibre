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
# == Table: cap_land_parcels
#
#  cap_islet_id                :integer(4)       not null
#  created_at                  :datetime         not null
#  creator_id                  :integer(4)
#  id                          :integer(4)       not null, primary key
#  land_parcel_number          :string           not null
#  lock_version                :integer(4)       default(0), not null
#  main_crop_code              :string           not null
#  main_crop_commercialisation :boolean          default(FALSE), not null
#  main_crop_precision         :string
#  main_crop_seed_production   :boolean          default(FALSE), not null
#  shape                       :geometry({:srid=>4326, :type=>"multi_polygon"}) not null
#  support_id                  :integer(4)
#  updated_at                  :datetime         not null
#  updater_id                  :integer(4)
#
require 'test_helper'

class CapLandParcelTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Add tests here...
end
