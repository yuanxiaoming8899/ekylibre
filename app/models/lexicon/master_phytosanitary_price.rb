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
# == Table: master_phytosanitary_prices
#
#  currency                 :string           not null
#  id                       :string           not null, primary key
#  reference_article_name   :integer(4)       not null
#  reference_name           :string           not null
#  reference_packaging_name :string           not null
#  started_on               :date             not null
#  unit_pretax_amount       :decimal(19, 4)   not null
#  usage                    :string           not null
#

class MasterPhytosanitaryPrice < LexiconRecord
  include Lexiconable

  belongs_to :master_variant, class_name: 'RegisteredPhytosanitaryProduct', foreign_key: :reference_article_name, primary_key: :id
  belongs_to :packaging, class_name: 'MasterPackaging'

end
