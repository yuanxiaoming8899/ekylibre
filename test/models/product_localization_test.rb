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
# == Table: product_localizations
#
#  container_id    :integer(4)
#  created_at      :datetime         not null
#  creator_id      :integer(4)
#  id              :integer(4)       not null, primary key
#  intervention_id :integer(4)
#  lock_version    :integer(4)       default(0), not null
#  nature          :string           not null
#  originator_id   :integer(4)
#  originator_type :string
#  product_id      :integer(4)       not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer(4)
#
require 'test_helper'

class ProductLocalizationTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'localization is interior if a container is provided' do
    zone = create :building_division
    product = create :fertilizer_product

    localization = ProductLocalization.create!(
      product: product,
      container: zone
    )
    assert localization.interior?
  end

  test 'localization is interior if a container is provided even if it does not belong to the company' do
    zone = create :building_division, initial_owner: create(:entity)
    product = create :fertilizer_product

    localization = ProductLocalization.create!(
      product: product,
      container: zone
    )
    assert localization.interior?
  end

  test 'localization is exterior if no container are provided' do
    product = create :fertilizer_product

    localization = ProductLocalization.create!(
      product: product,
      container: nil
    )
    assert localization.exterior?
  end
end
