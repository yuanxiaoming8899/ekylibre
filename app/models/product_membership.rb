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
# == Table: product_memberships
#
#  created_at      :datetime         not null
#  creator_id      :integer(4)
#  group_id        :integer(4)       not null
#  id              :integer(4)       not null, primary key
#  intervention_id :integer(4)
#  lock_version    :integer(4)       default(0), not null
#  member_id       :integer(4)       not null
#  nature          :string           not null
#  originator_id   :integer(4)
#  originator_type :string
#  started_at      :datetime         not null
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer(4)
#

class ProductMembership < ApplicationRecord
  include TimeLineable
  include Taskable
  enumerize :nature, in: %i[interior exterior], default: :interior, predicates: true
  belongs_to :group, class_name: 'ProductGroup', inverse_of: :memberships
  belongs_to :member, class_name: 'Product', inverse_of: :memberships
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :group, :member, :nature, presence: true
  validates :originator_type, length: { maximum: 500 }, allow_blank: true
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :stopped_at, timeliness: { on_or_after: ->(product_membership) { product_membership.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]

  before_validation do
    self.nature ||= (group ? :interior : :exterior)
  end

  private

    def siblings
      # self.member.memberships
      self.class.where(member: member) # group: self.group,
    end
end
