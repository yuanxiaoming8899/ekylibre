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
# == Table: registered_phytosanitary_usages
#
#  applications_count                :integer(4)
#  applications_frequency            :interval
#  crop                              :jsonb
#  crop_label_fra                    :string
#  decision_date                     :date
#  description                       :jsonb
#  development_stage_max             :integer(4)
#  development_stage_min             :integer(4)
#  dose_quantity                     :decimal(19, 4)
#  dose_unit                         :string
#  dose_unit_factor                  :float
#  dose_unit_name                    :string
#  ephy_usage_phrase                 :string           not null
#  extract_spray_volume_max_quantity :string
#  extract_spray_volume_max_unit     :string
#  id                                :string           not null, primary key
#  lib_court                         :integer(4)
#  pre_harvest_delay                 :interval
#  pre_harvest_delay_bbch            :integer(4)
#  product_id                        :integer(4)       not null
#  record_checksum                   :integer(4)
#  species                           Array<:text>
#  spray_volume_max_dose_quantity    :decimal(19, 4)
#  spray_volume_max_dose_unit        :string
#  spray_volume_max_dose_unit_name   :string
#  spray_volume_max_quantity         :decimal(19, 4)
#  spray_volume_max_unit             :string
#  spray_volume_max_unit_name        :string
#  state                             :string           not null
#  target_name                       :jsonb
#  target_name_label_fra             :string
#  treatment                         :jsonb
#  untreated_buffer_aquatic          :integer(4)
#  untreated_buffer_arthropod        :integer(4)
#  untreated_buffer_plants           :integer(4)
#  usage_conditions                  :string
#
class RegisteredPhytosanitaryUsage < LexiconRecord
  include Lexiconable
  extend Enumerize
  include HasInterval
  include Dimensionable
  include ScopeIntrospection

  UNTREATED_BUFFER_AQUATIC_VALUES = [5, 20, 30, 50, 100].freeze

  belongs_to :product, class_name: 'RegisteredPhytosanitaryProduct'

  enumerize :state, in: %w[authorized provisional withdrawn provisional], predicates: true
  has_interval :pre_harvest_delay, :applications_frequency

  scope :of_product, ->(*ids) { where(product_id: ids) }

  # Matches at least one of the given varieties
  scope :of_variety, ->(*varieties) do
    with_ancestors = [*varieties, *varieties.flat_map { |v| Onoma::Variety.ancestors(Onoma::Variety.find(v)).map(&:name) }].uniq.join('", "')

    joins('LEFT OUTER JOIN registered_phytosanitary_cropsets ON registered_phytosanitary_usages.species[1] = registered_phytosanitary_cropsets.name')
      .where("registered_phytosanitary_usages.species && '{\"#{with_ancestors}\"}' OR registered_phytosanitary_cropsets.crop_names && '{\"#{with_ancestors}\"}'")
      .order(:state)
  end

  # Matches all the given varieties
  scope :of_varieties, ->(*varieties) { varieties.reduce(self) { |acc, v| acc.of_variety(v) } }

  scope :of_specie, ->(specie) { where(specie: specie.to_s) }
  scope :with_conditions, -> { where.not(usage_conditions: nil) }

  delegate :in_field_reentry_delay, :france_maaid, :decorated_reentry_delay, to: :product

  %i[dose_quantity development_stage_min usage_conditions pre_harvest_delay].each do |col|
    define_method "decorated_#{col}" do
      decorate.send(col)
    end
  end

  %i[untreated_buffer_aquatic untreated_buffer_arthropod untreated_buffer_plants].each do |col|
    define_method "decorated_#{col}" do
      decorate.value_in_meters(col)
    end
  end

  %i[lib_court ephy_usage_phrase].each do |col|
    define_method "decorated_#{col}" do
      decorate.link_to_ephy(col)
    end
  end

  def decorated_applications_frequency
    decorate.applications_frequency
  end

  def status
    if authorized?
      :go
    elsif provisional?
      :caution
    elsif withdrawn?
      :stop
    else
      :stop
    end
  end

  def human_status
    I18n.t("tooltips.models.registered_phytosanitary_usage.#{status}")
  end

  # @return [Measure]
  def max_dose_measure
    Measure.new(dose_quantity * dose_unit_factor, dose_unit)
  end

  def pfi_target
    RegisteredPhytosanitaryTargetNameToPfiTarget.find_by(ephy_name: target_name_label_fra)
  end
end
