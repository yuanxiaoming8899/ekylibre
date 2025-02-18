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
# == Table: products
#
#  activity_production_id       :integer(4)
#  address_id                   :integer(4)
#  birth_date_completeness      :string
#  birth_farm_number            :string
#  born_at                      :datetime
#  category_id                  :integer(4)       not null
#  codes                        :jsonb
#  conditioning_unit_id         :integer(4)
#  country                      :string
#  created_at                   :datetime         not null
#  creator_id                   :integer(4)
#  custom_fields                :jsonb
#  dead_at                      :datetime
#  default_storage_id           :integer(4)
#  derivative_of                :string
#  description                  :text
#  end_of_life_reason           :string
#  father_country               :string
#  father_identification_number :string
#  father_variety               :string
#  filiation_status             :string
#  first_calving_on             :datetime
#  fixed_asset_id               :integer(4)
#  id                           :integer(4)       not null, primary key
#  identification_number        :string
#  initial_born_at              :datetime
#  initial_container_id         :integer(4)
#  initial_dead_at              :datetime
#  initial_enjoyer_id           :integer(4)
#  initial_father_id            :integer(4)
#  initial_geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  initial_mother_id            :integer(4)
#  initial_movement_id          :integer(4)
#  initial_owner_id             :integer(4)
#  initial_population           :decimal(19, 4)   default(0.0)
#  initial_shape                :geometry({:srid=>4326, :type=>"multi_polygon"})
#  isacompta_analytic_code      :string(2)
#  lock_version                 :integer(4)       default(0), not null
#  member_variant_id            :integer(4)
#  mother_country               :string
#  mother_identification_number :string
#  mother_variety               :string
#  name                         :string           not null
#  nature_id                    :integer(4)       not null
#  number                       :string           not null
#  origin_country               :string
#  origin_identification_number :string
#  originator_id                :integer(4)
#  parent_id                    :integer(4)
#  person_id                    :integer(4)
#  picture_content_type         :string
#  picture_file_name            :string
#  picture_file_size            :integer(4)
#  picture_updated_at           :datetime
#  provider                     :jsonb            default("{}")
#  reading_cache                :jsonb            default("{}")
#  specie_variety               :jsonb            default("{}")
#  team_id                      :integer(4)
#  tracking_id                  :integer(4)
#  type                         :string
#  type_of_occupancy            :string
#  updated_at                   :datetime         not null
#  updater_id                   :integer(4)
#  uuid                         :uuid
#  variant_id                   :integer(4)       not null
#  variety                      :string           not null
#  work_number                  :string
#  worker_group_item_id         :integer(4)
#

class ProductGroup < Product
  refers_to :variety, scope: :product_group
  belongs_to :parent, class_name: 'ProductGroup'
  has_many :memberships, class_name: 'ProductMembership', foreign_key: :group_id, dependent: :destroy, inverse_of: :group
  has_many :members, through: :memberships

  scope :available, -> {}
  scope :availables, ->(**args) {
    at = args[:at]
    return available if at.blank?

    if at.is_a?(String)
      if at =~ /\A\d\d\d\d\-\d\d\-\d\d \d\d\:\d\d/
        available.at(Time.strptime(at, '%Y-%m-%d %H:%M'))
      else
        logger.warn('Cannot parse: ' + at)
        available
      end
    else
      available.at(at)
    end
  }

  # TODO: see STI scope in unroll
  scope :of_expression, lambda { |expression|
    joins(:nature).where(WorkingSet.to_sql(expression, default: :products, abilities: :product_natures, indicators: :product_natures))
  }

  scope :groups_of, lambda { |member, viewed_at|
    where("id IN (SELECT group_id FROM #{ProductMembership.table_name} WHERE member_id = ? AND nature = ? AND ? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?))", member.id, 'interior', viewed_at, viewed_at, viewed_at)
  }

  # FIXME
  # accepts_nested_attributes_for :memberships, :reject_if => :all_blank, :allow_destroy => true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  # ]VALIDATORS]

  # Add a member to the group
  def add(member, options = {})
    unless member.is_a?(Product)
      raise ArgumentError.new("Product expected, got #{member.class}:#{member.inspect}")
    end

    Intervention.write(:group_inclusion, options) do |i|
      i.cast :group, self, as: 'group_inclusion-target'
      i.cast :member, member, as: 'group_inclusion-includer'
      i.group_inclusion :group, :member
    end
    # self.memberships.create!(member: member, started_at: (options[:at] || Time.zone.now), nature: :interior)
  end

  # Remove a member from the group
  def remove(member, _options = {})
    unless member.is_a?(Product)
      raise ArgumentError.new("Product expected, got #{member.class}:#{member.inspect}")
    end

    Intervention.write(:group_exclusion, at: started_at, production: production) do |i|
      i.cast :group, self, as: 'group_exclusion-target'
      i.cast :member, member, as: 'group_exclusion-includer'
      i.group_exclusion :group, :member
    end
    # self.memberships.create!(member: member, started_at: (options[:at] || Time.zone.now), nature: :exterior)
  end

  # Returns members of the group at a given time (or now by default)
  def members_at(viewed_at = nil)
    Product.members_of(self, viewed_at || Time.zone.now)
  end
end
